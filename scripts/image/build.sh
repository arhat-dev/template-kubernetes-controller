#!/bin/sh

# Copyright 2020 The arhat.dev Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

. scripts/image/common.sh

_ensure_manifest() {
  comp="$1"
  os="$2"
  arch="$3"

  args=""
  case "${arch}" in
    amd64)
      args="--arch amd64 --os ${os}"
      ;;
    armv6)
      args="--arch arm --variant v6 --os ${os}"
      ;;
    armv7)
      args="--arch arm --variant v7 --os ${os}"
      ;;
    arm64)
      args="--arch arm64 --os ${os}"
      ;;
    *)
      echo "unsupported arch"
      exit 1
      ;;
  esac

  tag_prefix="$(_get_tag_prefix_by_os "$os")"

  for r in ${IMAGE_REPOS}; do
    for t in ${MANIFEST_TAGS}; do
      image_name="${r}/${comp}:${tag_prefix}${arch}"
      manifest_name="${r}/${comp}:${t}"

      docker manifest create "${manifest_name}" \
        "${image_name}" || true

      docker manifest create "${manifest_name}" \
        --amend "${image_name}"

      # shellcheck disable=SC2086
      docker manifest annotate "${manifest_name}" \
        "${image_name}" ${args}
    done
  done
}

_build_image() {
  comp="$1"
  os="$2"
  arch="$3"
  dockerfile="cicd/docker/${comp}.dockerfile"
  tag_prefix="$(_get_tag_prefix_by_os "$os")"

  image_names=""
  for r in ${IMAGE_REPOS}; do
    image_names="-t ${r}/${comp}:${tag_prefix}${arch} ${image_names}"
  done

  if [ -z "${image_names}" ]; then
    echo "no image name generated"
    exit 1
  fi

  # shellcheck disable=SC2086
  docker build --pull -f "${dockerfile}" \
    ${image_names} \
    --build-arg TARGET="${comp}.${os}.${arch}" \
    --build-arg ARCH="${arch}" \
    --build-arg APP="${comp}" .
  
  _ensure_manifest "${comp}" "${os}" "${arch}"
}

COMP=$(printf "%s" "$@" | cut -d\. -f3)
OS=$(printf "%s" "$@" | cut -d\. -f4)
ARCH=$(printf "%s" "$@" | cut -d\. -f5)

_build_image "${COMP}" "${OS}" "${ARCH}"
