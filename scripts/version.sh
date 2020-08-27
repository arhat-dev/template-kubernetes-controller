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

GIT_BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
GIT_COMMIT="$(git rev-parse HEAD 2>/dev/null || true)"
GIT_REV="$(git describe --contains --always --match='v*' 2>/dev/null || true)"

GIT_TAG=${VERSION}

if [ -z "${GIT_TAG}" ]; then
  GIT_TAG="$(git describe --tags 2>/dev/null || true)"
  case "${GIT_TAG}" in
    *"${GIT_REV}")
      GIT_TAG=""
      ;;
  esac
fi

# fallback to gitlab ci env
if [ -z "${GIT_BRANCH}" ]; then
  GIT_BRANCH="${CI_COMMIT_BRANCH}"
fi

if [ -z "${GIT_COMMIT}" ]; then
  GIT_COMMIT="${CI_COMMIT_SHA}"
fi

if [ -z "${GIT_TAG}" ]; then
  GIT_TAG="${CI_COMMIT_TAG}"
fi

# fallback to github actions env
if [ -z "${GIT_COMMIT}" ]; then
  GIT_COMMIT="${GITHUB_SHA}"
fi
