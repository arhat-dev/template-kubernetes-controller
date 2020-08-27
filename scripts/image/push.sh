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

set -ex

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

_push_image() {
  comp="$1"
  os="$2"
  arch="$3"

  tag_prefix="$(_get_tag_prefix_by_os "$os")"

  for r in ${IMAGE_REPOS}; do
    docker push "${r}/${comp}:${tag_prefix}${arch}"
  done

  _ensure_manifest "${comp}" "${os}" "${arch}" || true

  for r in ${IMAGE_REPOS}; do
    for t in ${MANIFEST_TAGS}; do
      docker manifest push "${r}/${comp}:${t}" || true
    done
  done
}

comp=$(printf "%s" "$@" | cut -d\. -f3)
os=$(printf "%s" "$@" | cut -d\. -f4)
arch=$(printf "%s" "$@" | cut -d\. -f5)

_push_image "${comp}" "${os}" "${arch}"
