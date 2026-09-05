#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# bash accepts only one script operand; check each file separately.
git ls-files -z '*.sh' 'bin/de' | xargs -0 -r -n 1 bash -n
for test in tests/*.sh; do
  [[ $test == tests/run.sh ]] && continue
  printf 'Running %s\n' "$test"
  bash "$test"
done
