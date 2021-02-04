# MUST use debian image for race test and GNU tar for `kubectl cp`
FROM ghcr.io/arhat-dev/builder-go:debian as builder
FROM ghcr.io/arhat-dev/go:debian

COPY e2e/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /profile

ENTRYPOINT [ \
    "/entrypoint.sh", "/template-kubernetes-controller", \
    "-test.blockprofile=/profile/blockprofile.out", \
    "-test.cpuprofile=/profile/cpuprofile.out", \
    "-test.memprofile=/profile/memprofile.out", \
    "-test.mutexprofile=/profile/mutexprofile.out", \
    "-test.coverprofile=/profile/coverage.txt", \
    "-test.outputdir=/profile", \
    "--" \
]
