# template-kubernetes-controller

`template-kubernetes-controller` is a controller for all kinds of devices

## Introduction

This is the official helm chart for [template-kubernetes-controller](https://github.com/arhat-dev/template-kubernetes-controller), you can deploy `template-kubernetes-controller` to your clusters to manage any devices as kubernetes node via message queue or grpc

## Prerequisites

- `helm` v3
- `Kubernetes` 1.14+

## Installing the Chart

```bash
helm install my-release arhat-dev/template-kubernetes-controller
```

## Uninstalling the Chart

```bash
helm delete my-release
```

## Configuration

Please refer to the [`values.yaml`](https://github.com/arhat-dev/template-kubernetes-controller/blob/master/cicd/deploy/charts/template-kubernetes-controller/values.yaml)
