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

. scripts/version.sh

IMAGE_REPOS="$(printf "%s" "${IMAGE_REPOS}" | tr ',' ' ')"
if [ -z "${IMAGE_REPOS}" ]; then
    echo "no image repo provided"
    exit 1
fi

MANIFEST_TAGS="${DEFAULT_IMAGE_MANIFEST_TAG:-latest}"
if [ -n "${GIT_TAG}" ]; then
  MANIFEST_TAGS="${MANIFEST_TAGS} ${GIT_TAG}"
fi

_get_tag_prefix_by_os() {
  os="$1"

  case "${os}" in
    windows)
      printf "windows-"
      ;;
    linux)
      printf ""
      ;;
    *)
      echo "unsupported os"
      exit 1
      ;;
  esac
}
