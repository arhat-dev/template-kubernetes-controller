package main

import (
	"fmt"
	"math/rand"
	"os"
	"time"

	"arhat.dev/template-kubernetes-controller/cmd/template-kubernetes-controller/pkg"
	"arhat.dev/template-kubernetes-controller/pkg/version"
)

func main() {
	rand.Seed(time.Now().UnixNano())

	cmd := pkg.NewTemplateKubernetesControllerCmd()
	cmd.AddCommand(version.NewVersionCmd())

	err := cmd.Execute()
	if err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "failed to run template-kubernetes-controller %v: %v\n", os.Args, err)
		os.Exit(1)
	}
}
