#!/bin/sh
# shellcheck disable=SC2039

# Copyright 2020 The arhat.dev Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

. scripts/version.sh

_install_deps() {
  echo "${INSTALL}"
  eval "${INSTALL}"
}

_build() {
  echo "$1"
  eval "$1"
}

template_kubernetes_controller() {
  _build "CGO_ENABLED=0 ${GOBUILD} -tags='foo bar' ./cmd/template-kubernetes-controller"
}

COMP=$(printf "%s" "$@" | cut -d\. -f1)
CMD=$(printf "%s" "$@" | tr '-' '_' | tr '.'  ' ')

# CMD format: {func_name} {os} {arch}

GOOS="$(printf "%s" "${CMD}" | cut -d\  -f2)"
ARCH="$(printf "%s" "${CMD}" | cut -d\  -f3)"

GOEXE=""
PREDEFINED_BUILD_TAGS=""
case "${GOOS}" in
  darwin)
    PREDEFINED_BUILD_TAGS=""
  ;;
  openbsd)
    PREDEFINED_BUILD_TAGS=""
  ;;
  netbsd)
    PREDEFINED_BUILD_TAGS=""
  ;;
  freebsd)
    PREDEFINED_BUILD_TAGS=""
  ;;
  plan9)
    PREDEFINED_BUILD_TAGS=""
  ;;
  aix)
    PREDEFINED_BUILD_TAGS=""
  ;;
  solaris)
    PREDEFINED_BUILD_TAGS=""
  ;;
  linux)
    case "${ARCH}" in
      mips64* | mipsle*)
        PREDEFINED_BUILD_TAGS=""
      ;;
      riscv64)
        PREDEFINED_BUILD_TAGS=""
      ;;
    esac
  ;;
  windows)
    GOEXE=".exe"
    case "${ARCH}" in
      arm*)
        PREDEFINED_BUILD_TAGS=""
      ;;
    esac
  ;;
esac

GOARCH=${ARCH}

case "${ARCH}" in
  armv*)
    GOARCH=arm
    GOARM=${ARCH#armv}

    case "${GOARM}" in
      5)
        # armv5 support is rare
        ;;
      6)
        ALPINE_ARCH="armhf" # alpine doesn't have armv5 support though
        DEBIAN_ARCH="armel"

        DEBIAN_TRIPLE="arm-linux-gnueabi"
        ALPINE_TRIPLE="armel-linux-musleabi"
        ;;
      7)
        ALPINE_ARCH="armv7"
        DEBIAN_ARCH="armhf"

        DEBIAN_TRIPLE="arm-linux-gnueabihf"
        ALPINE_TRIPLE="armv7l-linux-musleabihf"
        ;;
    esac
    ;;
  arm64)
    ALPINE_ARCH="aarch64"
    DEBIAN_ARCH="arm64"

    DEBIAN_TRIPLE="aarch64-linux-gnu"
    ALPINE_TRIPLE="aarch64-linux-musl"
    ;;
  x86)
    ALPINE_ARCH="x86"
    DEBIAN_ARCH="i386"

    ALPINE_TRIPLE="i686-linux-musl"
    DEBIAN_TRIPLE="i686-linux-gnu"
    ;;
  amd64)
    ALPINE_ARCH="x86_64"
    DEBIAN_ARCH="amd64"

    # cross compile to amd64 seems rare
    ;;
  ppc64)
    ALPINE_ARCH="ppc64"
    DEBIAN_ARCH="ppc64"

    ALPINE_TRIPLE="powerpc64-linux-musl"
    DEBIAN_TRIPLE="powerpc64-linux-gnu"
    ;;
  ppc64le)
    ALPINE_ARCH="ppc64le"
    DEBIAN_ARCH="ppc64el"

    ALPINE_TRIPLE="powerpc64le-linux-musl"
    DEBIAN_TRIPLE="powerpc64le-linux-gnu"
    ;;
  riscv64,s390x)
    ALPINE_ARCH="${ARCH}"
    ALPINE_ARCH="${ARCH}"

    ALPINE_TRIPLE="${ARCH}-linux-musl"
    DEBIAN_TRIPLE="${ARCH}-linux-gnu"
    ;;
  *)
    # TODO
    GOARCH=${ARCH}
    ;;
esac

# handle mips arch

case "${ARCH}" in
  mips*hf)
    GOARCH=${ARCH%hf}
    GOMIPS=hardfloat
    ;;
  mips*)
    GOMIPS=softfloat
    ;;
esac

case "${GOARCH}" in
  mipsle*)
    ALPINE_ARCH="mipsel"
    DEBIAN_ARCH="mipsel"

    ALPINE_TRIPLE="mipsel-linux-musl"
    DEBIAN_TRIPLE="mipsel-linux-gnu"
    ;;
  mips64le*)
    ALPINE_ARCH="mips64el"
    DEBIAN_ARCH="mips64el"

    ALPINE_TRIPLE="mips64el-linux-musl"
    DEBIAN_TRIPLE="mips64el-linux-gnu"
    ;;
  mips*)
    ALPINE_ARCH="${GOARCH}"
    DEBIAN_ARCH="${GOARCH}"

    ALPINE_TRIPLE="${GOARCH}-linux-musl"
    DEBIAN_TRIPLE="${GOARCH}-linux-gnu"
    ;;
esac

CC="gcc"
STRIP="strip"
CXX="g++"
CFLAGS="-I/usr/include/glib-2.0 -I/usr/include"
LDFLAGS=""

PM_DEB=$(command -v apt-get || printf "")
PM_RPM=$(command -v yum || command -v dnf || printf "")
PM_APK=$(command -v apk || printf "")

if [ -n "${PM_DEB}" ]; then
  TRIPLE="${DEBIAN_TRIPLE}"
  if [ -n "${TRIPLE}" ]; then
    PKG_CONFIG_PATH="/usr/lib/${TRIPLE}/pkgconfig"
    CFLAGS="-I/usr/include/${TRIPLE} -I/usr/${TRIPLE}/include -I/usr/lib/${TRIPLE}/glib-2.0/include ${CFLAGS}"
    LDFLAGS="-L/lib/${TRIPLE} -L/usr/lib/${TRIPLE}"
  fi

  # TODO: Add required deb packages
  deb_packages=""

  # TODO: inspect why install packages directly will not setup pkgconfig files
  INSTALL="apt-get install -y ${deb_packages}"
  if [ -n "${DEBIAN_ARCH}" ]; then
    packages_with_arch=""
    for pkg in ${deb_packages}; do
      packages_with_arch="${pkg}:${DEBIAN_ARCH} ${packages_with_arch}"
    done
    # TODO: fix install command here
    # INSTALL="${INSTALL} python3-distutils=3.7.3-1 python3-lib2to3=3.7.3-1 python3=3.7.3-1 && apt-get install -y ${packages_with_arch}"
  fi
fi

# TODO: handle rpm package installation
# if [ -n "${PM_RPM}" ]; then
#   INSTALL="yum install -y ${RPM_PACKAGES}"
# fi

if [ -n "${PM_APK}" ]; then
  TRIPLE="${ALPINE_TRIPLE}"
  if [ -n "${TRIPLE}" ]; then
    PKG_CONFIG_PATH="/${TRIPLE}/usr/lib/pkgconfig"
    CFLAGS="-I/${TRIPLE}/include -I/${TRIPLE}/usr/include -I/${TRIPLE}/usr/lib/glib-2.0/include ${CFLAGS}"
    LDFLAGS="-L/${TRIPLE}/lib -L/${TRIPLE}/usr/lib"
  fi

  # TODO: Add required apk packages
  apk_packages=""

  INSTALL="apk add ${apk_packages}"
  if [ -n "${ALPINE_ARCH}" ]; then
    apk_dirs_for_triple=""

    apk_dirs="/var/lib/apk /var/cache/apk /usr/share/apk /etc/apk"
    for d in ${apk_dirs}; do
      apk_dirs_for_triple="/${TRIPLE}${d} ${apk_dirs_for_triple}"
    done

    INSTALL="mkdir -p ${apk_dirs_for_triple} && apk add --root /${TRIPLE} --arch ${ALPINE_ARCH} ${apk_packages}"
  fi
fi

if [ -n "${TRIPLE}" ]; then
  CC="${TRIPLE}-gcc"
  CXX="${TRIPLE}-g++"
  STRIP="${TRIPLE}-strip"
fi

if [ "${GOARCH}" = "x86" ]; then
  GOARCH="386"
fi

CGO_FLAGS="CC=${CC} CXX=${CXX} CC_FOR_TARGET=${CC} CXX_FOR_TARGET=${CXX} CGO_CFLAGS_ALLOW='-W' CGO_CFLAGS='${CFLAGS}' CGO_LDFLAGS='${LDFLAGS}'"

GO_LDFLAGS="-s -w \
  -X arhat.dev/template-kubernetes-controller/pkg/version.branch=${GIT_BRANCH} \
  -X arhat.dev/template-kubernetes-controller/pkg/version.commit=${GIT_COMMIT} \
  -X arhat.dev/template-kubernetes-controller/pkg/version.tag=${GIT_TAG} \
  -X arhat.dev/template-kubernetes-controller/pkg/version.arch=${ARCH}"

GOBUILD="GO111MODULE=on \
  GOOS=${GOOS} \
  GOARCH=${GOARCH} \
  GOARM=${GOARM} \
  GOMIPS=${GOMIPS} \
  GOWASM=satconv,signext \
  ${CGO_FLAGS} \
  go build \
  -trimpath \
  -buildmode=${BUILD_MODE:-default} \
  -mod=vendor \
  -ldflags='${GO_LDFLAGS}' \
  -o build/${COMP}.${GOOS}.${ARCH}${GOEXE}"

$CMD
