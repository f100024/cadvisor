#!/bin/bash

# Copyright 2015 Google Inc. All rights reserved.
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

GIT_ROOT=$(dirname "${BASH_SOURCE}")/..

ASSETS_INPUT_DIRS="$GIT_ROOT/cmd/internal/pages/assets/js/... $GIT_ROOT/cmd/internal/pages/assets/styles/..."
ASSETS_OUTPUT_PATH="$GIT_ROOT/cmd/internal/pages/static/assets.go"
ASSETS_PACKAGE="static"

TEMPLATES_INPUT_DIRS="$GIT_ROOT/cmd/internal/pages/assets/html/..."
TEMPLATES_OUTPUT_PATH="$GIT_ROOT/cmd/internal/pages/templates.go"
TEMPLATES_PACKAGE="pages"

FORCE="${FORCE:-}" # Force assets to be rebuilt if FORCE=true

# Install while in a temp dir to avoid polluting go.mod/go.sum
pushd "${TMPDIR:-/tmp}" > /dev/null
go install github.com/kevinburke/go-bindata@latest
popd > /dev/null

build_asset () {
  local package=$1
  local output_path=$2
  local input_dirs=${@:3}
  local tmp_output=$(mktemp)
  local year="$(git log -1 --date=format:'%Y' --format=%cd -- ${output_path})"

  go-bindata -nometadata -o $output_path -pkg $package $input_dirs
  cat build/boilerplate/boilerplate.go.txt | sed "s/YEAR/$year/" > "${tmp_output}"
  echo -e "// generated by build/assets.sh; DO NOT EDIT\n" >> "${tmp_output}"
  cat "${output_path}" >> "${tmp_output}"
  gofmt -w -s "${tmp_output}"
  mv "${tmp_output}" "${output_path}"
}

for f in $GIT_ROOT/cmd/internal/pages/assets/js/* $GIT_ROOT/cmd/internal/pages/assets/styles/*; do
  if [ "$FORCE" == "true" ] || [ "$f" -nt $ASSETS_OUTPUT_PATH -o ! -e $ASSETS_OUTPUT_PATH ]; then
    build_asset "$ASSETS_PACKAGE" "$ASSETS_OUTPUT_PATH" "$ASSETS_INPUT_DIRS"
    break;
  fi
done

for f in $GIT_ROOT/cmd/internal/pages/assets/html/*; do
  if [ "$FORCE" == "true" ] || [ "$f" -nt $TEMPLATES_OUTPUT_PATH -o ! -e $TEMPLATES_OUTPUT_PATH ]; then
    build_asset "$TEMPLATES_PACKAGE" "$TEMPLATES_OUTPUT_PATH" "$TEMPLATES_INPUT_DIRS"
    break;
  fi
done

exit 0
