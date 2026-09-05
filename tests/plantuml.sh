#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# The functions use portable shell syntax; load only these, not the user's shell.
eval "$(sed -n '/^start-plantuml() {/,/^}/p; /^stop-plantuml() {/,/^}/p' dot_zshrc)"
calls=()
docker() {
  calls+=("$*")
  if [[ $1 == container ]]; then return "$inspect_status"; fi
}
inspect_status=0
start-plantuml
stop-plantuml
[[ ${calls[*]} == 'container inspect plantuml start plantuml stop plantuml rm plantuml' ]]
calls=()
inspect_status=1
start-plantuml
[[ ${calls[1]} == 'run -d -p 18123:8080 --name plantuml plantuml/plantuml-server:jetty' ]]
