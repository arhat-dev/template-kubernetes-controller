/*
Copyright 2020 The arhat.dev Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

package cmd

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"os"

	"arhat.dev/pkg/envhelper"
	"arhat.dev/pkg/kubehelper"
	"arhat.dev/pkg/log"
	"github.com/spf13/cobra"
	corev1 "k8s.io/api/core/v1"
	kubeclient "k8s.io/client-go/kubernetes"
	"k8s.io/client-go/kubernetes/scheme"
	typedcorev1 "k8s.io/client-go/kubernetes/typed/core/v1"
	"k8s.io/client-go/tools/record"

	"arhat.dev/template-kubernetes-controller/pkg/apis"
	"arhat.dev/template-kubernetes-controller/pkg/conf"
	"arhat.dev/template-kubernetes-controller/pkg/constant"
	"arhat.dev/template-kubernetes-controller/pkg/controller/samplecrd"
)

func NewTemplateKubernetesControllerCmd() *cobra.Command {
	var (
		appCtx       context.Context
		configFile   string
		config       = new(conf.Config)
		cliLogConfig = new(log.Config)
	)

	appCmd := &cobra.Command{
		Use:           "template-kubernetes-controller",
		SilenceErrors: true,
		SilenceUsage:  true,
		PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
			if cmd.Use == "version" {
				return nil
			}

			var err error
			appCtx, err = conf.ReadConfig(cmd, &configFile, cliLogConfig, config)
			if err != nil {
				return err
			}

			return nil
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			return run(appCtx, config)
		},
	}

	flags := appCmd.PersistentFlags()

	flags.StringVarP(&configFile, "config", "c", constant.DefaultTemplateKubernetesControllerConfigFile,
		"path to the app config file")
	flags.AddFlagSet(kubehelper.FlagsForControllerConfig("app", "", cliLogConfig,
		&config.App.ControllerConfig))
	flags.AddFlagSet(conf.FlagsForTemplateKubernetesController("", &config.App))

	return appCmd
}

func run(appCtx context.Context, config *conf.Config) error {
	logger := log.Log.WithName("app")

	logger.I("creating kube client for initialization")
	kubeClient, _, err := config.App.KubeClient.NewKubeClient(nil, false)
	if err != nil {
		return fmt.Errorf("failed to create kube client from kubeconfig: %w", err)
	}

	_, mtHandler, err := config.App.Metrics.CreateIfEnabled(true)
	if err != nil {
		return fmt.Errorf("failed to create metrics provider: %w", err)
	}

	if mtHandler != nil {
		mux := http.NewServeMux()
		mux.Handle(config.App.Metrics.HTTPPath, mtHandler)

		tlsConfig, err2 := config.App.Metrics.TLS.GetTLSConfig(true)
		if err2 != nil {
			return fmt.Errorf("failed to get tls config for metrics listener: %w", err2)
		}

		srv := &http.Server{
			Handler:   mux,
			Addr:      config.App.Metrics.Endpoint,
			TLSConfig: tlsConfig,
		}

		go func() {
			err2 = srv.ListenAndServe()
			if err2 != nil && !errors.Is(err2, http.ErrServerClosed) {
				panic(err2)
			}
		}()
	}

	_, err = config.App.Tracing.CreateIfEnabled(true, nil)
	if err != nil {
		logger.E("failed to create tracing provider", log.Error(err))
		return err
	}

	evb := record.NewBroadcaster()
	watchEventLogging := evb.StartLogging(func(format string, args ...interface{}) {
		logger.I(fmt.Sprintf(format, args...), log.String("source", "event"))
	})
	watchEventRecording := evb.StartRecordingToSink(
		&typedcorev1.EventSinkImpl{Interface: kubeClient.CoreV1().Events(envhelper.ThisPodNS())})
	defer func() {
		watchEventLogging.Stop()
		watchEventRecording.Stop()
	}()

	logger.V("creating leader elector")
	elector, err := config.App.LeaderElection.CreateElector("app", kubeClient,
		evb.NewRecorder(scheme.Scheme, corev1.EventSource{
			Component: "app",
		}),
		// on elected
		func(ctx context.Context) {
			err2 := onElected(ctx, logger, kubeClient, config)
			if err2 != nil {
				logger.E("failed to run controller", log.Error(err2))
				os.Exit(1)
			}
		},
		// on ejected
		func() {
			logger.E("lost leader-election")
			os.Exit(1)
		},
		// on new leader
		func(identity string) {
			// TODO: react when new leader elected
		},
	)

	if err != nil {
		return fmt.Errorf("failed to create elector: %w", err)
	}

	logger.I("running leader election")
	elector.Run(appCtx)

	return fmt.Errorf("unreachable code")
}

func onElected(
	appCtx context.Context,
	logger log.Interface,
	kubeClient kubeclient.Interface,
	config *conf.Config,
) error {
	logger.I("won leader election")

	// setup scheme for all custom resources
	logger.D("adding api scheme")
	if err := apis.AddToScheme(scheme.Scheme); err != nil {
		return fmt.Errorf("failed to add api scheme: %w", err)
	}

	logger.D("discovering api resources")
	preferredResources, err := kubeClient.Discovery().ServerPreferredResources()
	if err != nil {
		logger.I("failed to finish api discovery", log.Error(err))
	}

	if len(preferredResources) == 0 {
		logger.I("no api resource discovered")
		preferredResources = samplecrd.CheckAPIVersionFallback(kubeClient)
	} else {
		logger.D("found api resources", log.Any("resources", preferredResources))
	}

	// create and start controller
	logger.I("creating controller")
	controller, err := samplecrd.NewController(
		appCtx, config, preferredResources,
	)
	if err != nil {
		return fmt.Errorf("failed to create new controller: %w", err)
	}

	logger.I("starting controller")
	if err = controller.Start(); err != nil {
		return fmt.Errorf("failed to start controller: %w", err)
	}

	return fmt.Errorf("controller exited: %w", appCtx.Err())
}
