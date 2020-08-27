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
}

comp=$(printf "%s" "$@" | cut -d\. -f3)
os=$(printf "%s" "$@" | cut -d\. -f4)
arch=$(printf "%s" "$@" | cut -d\. -f5)

_build_image "${comp}" "${os}" "${arch}"
