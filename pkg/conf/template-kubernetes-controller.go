package conf

import (
	"arhat.dev/pkg/confhelper"
	"arhat.dev/pkg/log"
	"github.com/spf13/pflag"
)

// nolint:lll
type TemplateKubernetesControllerConfig struct {
	TemplateKubernetesController TemplateKubernetesControllerAppConfig `json:"templateKubernetesController" yaml:"templateKubernetesController"`
}

type TemplateKubernetesControllerAppConfig struct {
	confhelper.ControllerConfig `json:",inline" yaml:",inline"`

	Foo string `json:"foo" yaml:"foo"`
}

func FlagsForTemplateKubernetesController(prefix string, config *TemplateKubernetesControllerAppConfig) *pflag.FlagSet {
	fs := pflag.NewFlagSet("app", pflag.ExitOnError)

	fs.StringVar(&config.Foo, prefix+"foo", "bar", "set value of foo")

	return fs
}

func (c *TemplateKubernetesControllerConfig) GetLogConfig() log.ConfigSet {
	return c.TemplateKubernetesController.Log
}

func (c *TemplateKubernetesControllerConfig) SetLogConfig(config log.ConfigSet) {
	c.TemplateKubernetesController.Log = config
}
