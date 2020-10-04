ARG ARCH=mips64le

# usually a kubernetes controller do not use cgo so
# we can build on alpine and copy it to debian
FROM arhatdev/builder-go:alpine as builder
FROM arhatdev/go:debian-${ARCH}
ARG APP=template-kubernetes-controller

ENTRYPOINT [ "/template-kubernetes-controller" ]
