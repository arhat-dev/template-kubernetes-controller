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

_push_image() {
  comp="$1"
  os="$2"
  arch="$3"

  tag_prefix="$(_get_tag_prefix_by_os "$os")"

  for r in ${IMAGE_REPOS}; do
    docker push "${r}/${comp}:${tag_prefix}${arch}"
  done

  for r in ${IMAGE_REPOS}; do
    for t in ${MANIFEST_TAGS}; do
      docker manifest push "${r}/${comp}:${t}"
    done
  done
}

COMP=$(printf "%s" "$@" | cut -d\. -f3)
OS=$(printf "%s" "$@" | cut -d\. -f4)
ARCH=$(printf "%s" "$@" | cut -d\. -f5)

_push_image "${COMP}" "${OS}" "${ARCH}"
