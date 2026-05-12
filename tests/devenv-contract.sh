#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
stub_dir="$repo_root/tests/fixtures/devenv-stubs"
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT
main_path="$tmp_dir/main-path"
mkdir -p "$main_path"
for blocked_tool in curl apt-get sudo; do
  cat >"$main_path/$blocked_tool" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
printf 'FAIL: unexpected host tool invocation: %s\n' "$(basename "$0")" >&2
exit 1
STUB
  chmod +x "$main_path/$blocked_tool"
done
export PATH="$stub_dir:$main_path:$PATH"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'Output was:\n%s\n' "$haystack" >&2
    fail "expected output to contain: $needle"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    printf 'Output was:\n%s\n' "$haystack" >&2
    fail "expected output not to contain: $needle"
  fi
}

assert_not_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    fail "expected path not to exist: $path"
  fi
}

assert_line_before() {
  local haystack="$1"
  local first="$2"
  local second="$3"
  local first_line second_line

  first_line=$(printf '%s\n' "$haystack" | grep -nF "$first" | head -n1 | cut -d: -f1 || true)
  second_line=$(printf '%s\n' "$haystack" | grep -nF "$second" | head -n1 | cut -d: -f1 || true)
  if [[ -z $first_line || -z $second_line || $first_line -ge $second_line ]]; then
    printf 'Output was:\n%s\n' "$haystack" >&2
    fail "expected '$first' to appear before '$second'"
  fi
}

bash_path=$(command -v bash)
de_cmd="$repo_root/bin/de"

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfiles bootstrap and passthrough command'
assert_contains "$help_output" 'Usage:'
assert_contains "$help_output" 'Commands:'
assert_contains "$help_output" 'Examples:'
assert_contains "$help_output" 'de help <command>'
assert_contains "$help_output" 'm         Alias for mise'
assert_contains "$help_output" 'c         Alias for chezmoi'
assert_contains "$help_output" 'a         Alias for apm'
assert_contains "$help_output" 'init      Apply dotfiles and run setup'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-long-home" "$de_cmd" --help)
assert_contains "$help_output" 'de - dotfiles bootstrap and passthrough command'
assert_contains "$help_output" 'Usage:'
assert_contains "$help_output" 'Commands:'
assert_contains "$help_output" 'Examples:'
assert_contains "$help_output" 'de help <command>'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-short-home" "$de_cmd" -h)
assert_contains "$help_output" 'de - dotfiles bootstrap and passthrough command'
assert_contains "$help_output" 'Usage:'
assert_contains "$help_output" 'Commands:'
assert_contains "$help_output" 'Examples:'
assert_contains "$help_output" 'de help <command>'

help_output=$(DEVENV_LANG=ja HOME="$tmp_dir/help-ja-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfilesの初期化とツール委譲コマンド'
assert_contains "$help_output" '使い方:'
assert_contains "$help_output" 'コマンド:'
assert_contains "$help_output" '例:'
assert_contains "$help_output" 'de help <command>'
assert_contains "$help_output" 'm         miseの別名'
assert_contains "$help_output" 'c         chezmoiの別名'
assert_contains "$help_output" 'a         apmの別名'
assert_contains "$help_output" 'init      dotfilesを反映し、セットアップを実行'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=ja_JP.UTF-8 HOME="$tmp_dir/help-lang-ja-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfilesの初期化とツール委譲コマンド'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=ja HOME="$tmp_dir/help-lang-ja-short-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfilesの初期化とツール委譲コマンド'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=ja.UTF-8 HOME="$tmp_dir/help-lang-ja-dot-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfilesの初期化とツール委譲コマンド'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=ja-JP HOME="$tmp_dir/help-lang-ja-hyphen-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfilesの初期化とツール委譲コマンド'

help_output=$(env -u DEVENV_LANG LC_ALL=ja_JP.UTF-8 LANGUAGE=en LANG=C HOME="$tmp_dir/help-lc-all-ja-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfilesの初期化とツール委譲コマンド'

help_output=$(env -u DEVENV_LANG LC_ALL=C LANGUAGE=ja:en LANG=ja_JP.UTF-8 HOME="$tmp_dir/help-lc-all-c-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfiles bootstrap and passthrough command'
assert_not_contains "$help_output" 'dotfilesの初期化'

help_output=$(env -u DEVENV_LANG -u LC_ALL LANGUAGE=ja:en LANG=C HOME="$tmp_dir/help-language-ja-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfilesの初期化とツール委譲コマンド'

help_output=$(env -u DEVENV_LANG -u LC_ALL LANGUAGE=en:ja LANG=ja_JP.UTF-8 HOME="$tmp_dir/help-language-en-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfiles bootstrap and passthrough command'
assert_not_contains "$help_output" 'dotfilesの初期化'

help_output=$(env -u LC_ALL -u LANGUAGE DEVENV_LANG=en LANG=ja_JP.UTF-8 HOME="$tmp_dir/help-env-en-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfiles bootstrap and passthrough command'
assert_not_contains "$help_output" 'dotfilesの初期化'

help_output=$(env -u LC_ALL -u LANGUAGE DEVENV_LANG=fr LANG=ja_JP.UTF-8 HOME="$tmp_dir/help-env-unsupported-home" "$de_cmd" help)
assert_contains "$help_output" 'de - dotfiles bootstrap and passthrough command'
assert_not_contains "$help_output" 'dotfilesの初期化'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-install-home" "$de_cmd" help install)
assert_contains "$help_output" 'de install'
assert_contains "$help_output" '--repo URL'
assert_contains "$help_output" '--branch NAME'
assert_contains "$help_output" '--path PATH'
assert_contains "$help_output" 'raw.githubusercontent.com/njfa/dotfiles/main/bin/de'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-install-option-home" "$de_cmd" install --help)
assert_contains "$help_output" 'de install'
assert_contains "$help_output" '--repo URL'
assert_contains "$help_output" '--branch NAME'
assert_contains "$help_output" '--path PATH'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-init-home" "$de_cmd" help init)
assert_contains "$help_output" 'de init - apply dotfiles and run setup'
assert_contains "$help_output" 'chezmoi apply'
assert_contains "$help_output" 'mise install'
assert_contains "$help_output" 'mise run setup'

help_output=$(DEVENV_LANG=ja HOME="$tmp_dir/help-install-option-ja-home" "$de_cmd" install --help)
assert_contains "$help_output" 'de install - dotfilesをclone後、applyとセットアップを実行'
assert_contains "$help_output" '使い方:'

help_output=$(DEVENV_LANG=ja HOME="$tmp_dir/help-init-ja-home" "$de_cmd" help init)
assert_contains "$help_output" 'de init - dotfilesを反映し、セットアップを実行'
assert_contains "$help_output" 'chezmoi apply'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-mise-home" "$de_cmd" help mise)
assert_contains "$help_output" 'de mise'
assert_contains "$help_output" 'Passes arguments through to mise.'
assert_contains "$help_output" 'de m run deploy'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-chezmoi-home" "$de_cmd" help chezmoi)
assert_contains "$help_output" 'de chezmoi'
assert_contains "$help_output" 'Installs chezmoi through mise when missing.'
assert_contains "$help_output" 'de c apply --source .'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-apm-home" "$de_cmd" help apm)
assert_contains "$help_output" 'de apm'
assert_contains "$help_output" 'Installs apm through mise as pipx:apm-cli when missing.'
assert_contains "$help_output" 'de a --version'

help_output=$(DEVENV_LANG=ja HOME="$tmp_dir/help-install-ja-home" "$de_cmd" help install)
assert_contains "$help_output" 'de install - dotfilesをclone後、applyとセットアップを実行'
assert_contains "$help_output" '--repo URL'
assert_contains "$help_output" '--branch NAME'
assert_contains "$help_output" '--path PATH'

help_output=$(DEVENV_LANG=ja HOME="$tmp_dir/help-mise-ja-home" "$de_cmd" help mise)
assert_contains "$help_output" 'de mise - miseへ引数を委譲'
assert_contains "$help_output" 'miseが未導入の場合はインストールします。'

help_output=$(DEVENV_LANG=ja HOME="$tmp_dir/help-chezmoi-ja-home" "$de_cmd" help chezmoi)
assert_contains "$help_output" 'de chezmoi - chezmoiへ引数を委譲'
assert_contains "$help_output" 'chezmoiが未導入の場合はmise経由でインストールします。'

help_output=$(DEVENV_LANG=ja HOME="$tmp_dir/help-apm-ja-home" "$de_cmd" help apm)
assert_contains "$help_output" 'de apm - apmへ引数を委譲'
assert_contains "$help_output" 'apmが未導入の場合はmiseでpipx:apm-cliとしてインストールします。'

help_output=$(env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-raw-home" "$bash_path" -s -- help install <"$de_cmd")
assert_contains "$help_output" 'de install'
assert_contains "$help_output" 'raw.githubusercontent.com/njfa/dotfiles/main/bin/de'

if env -u DEVENV_LANG -u LC_ALL -u LANGUAGE LANG=C HOME="$tmp_dir/help-unknown-home" "$de_cmd" help unknown >"$tmp_dir/help-unknown.out" 2>"$tmp_dir/help-unknown.err"; then
  fail 'unknown help topic should fail'
fi
assert_contains "$(cat "$tmp_dir/help-unknown.err")" 'Unknown help topic: unknown'

output=$(HOME="$tmp_dir/mise-home" "$de_cmd" mise --version)
assert_contains "$output" '[STUB mise] --version'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'

output=$(HOME="$tmp_dir/mise-alias-home" "$de_cmd" m --version)
assert_contains "$output" '[STUB mise] --version'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'

no_args_bin="$tmp_dir/no-args-bin"
mkdir -p "$no_args_bin"
for tool in mise apm chezmoi; do
  cat >"$no_args_bin/$tool" <<STUB
#!$bash_path
set -euo pipefail
printf '[STUB $tool] argc=%s args=%s\n' "\$#" "\$*"
STUB
  chmod +x "$no_args_bin/$tool"
done
output=$(HOME="$tmp_dir/mise-no-args-home" PATH="$no_args_bin:$main_path:$PATH" "$de_cmd" m)
assert_contains "$output" '[STUB mise] argc=0 args='
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'

output=$(HOME="$tmp_dir/chezmoi-no-args-home" PATH="$no_args_bin:$main_path:$PATH" "$de_cmd" c)
assert_contains "$output" '[STUB chezmoi] argc=0 args='
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'

output=$(HOME="$tmp_dir/apm-no-args-home" PATH="$no_args_bin:$main_path:$PATH" "$de_cmd" a)
assert_contains "$output" '[STUB apm] argc=0 args='
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'

output=$(HOME="$tmp_dir/mise-help-home" "$de_cmd" mise --help)
assert_contains "$output" '[STUB mise] --help'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'
assert_not_contains "$output" 'de mise - pass arguments through to mise'

ordered_bin="$tmp_dir/ordered-bin"
mkdir -p "$ordered_bin"
cat >"$ordered_bin/mise" <<STUB
#!$bash_path
set -euo pipefail
case "\$*" in
  'activate bash')
    ;;
  ordered-output)
    printf 'stdout-before\n'
    printf 'stderr-middle\n' >&2
    printf 'stdout-after\n'
    ;;
  *)
    printf '[STUB mise] %s\n' "\$*"
    ;;
esac
STUB
chmod +x "$ordered_bin/mise"
ordered_output=$(HOME="$tmp_dir/ordered-home" PATH="$ordered_bin:$main_path:$PATH" "$de_cmd" mise ordered-output 2>&1)
assert_line_before "$ordered_output" 'stdout-before' 'stderr-middle'
assert_line_before "$ordered_output" 'stderr-middle' 'stdout-after'

home_without_config="$tmp_dir/home-without-config"
output=$(HOME="$home_without_config" "$de_cmd" mise --version)
assert_contains "$output" '[STUB mise] --version'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'
assert_not_exists "$home_without_config/.config/mise/config.toml"

output=$(HOME="$tmp_dir/chezmoi-home" "$de_cmd" chezmoi apply --source "$repo_root")
assert_contains "$output" '[STUB chezmoi] apply --source'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'

output=$(HOME="$tmp_dir/chezmoi-alias-home" "$de_cmd" c apply --source "$repo_root")
assert_contains "$output" '[STUB chezmoi] apply --source'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'

output=$(HOME="$tmp_dir/chezmoi-help-home" "$de_cmd" chezmoi --help)
assert_contains "$output" '[STUB chezmoi] --help'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'
assert_not_contains "$output" 'de chezmoi - pass arguments through to chezmoi'

output=$(HOME="$tmp_dir/apm-home" "$de_cmd" apm --version)
assert_contains "$output" '[STUB apm] --version'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'

output=$(HOME="$tmp_dir/apm-alias-home" "$de_cmd" a --version)
assert_contains "$output" '[STUB apm] --version'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'

output=$(HOME="$tmp_dir/apm-help-home" "$de_cmd" apm --help)
assert_contains "$output" '[STUB apm] --help'
assert_not_contains "$output" '[RUN]'
assert_not_contains "$output" '[OK]'
assert_not_contains "$output" 'de apm - pass arguments through to apm'

missing_apm_dir="$tmp_dir/missing-apm-bin"
missing_apm_tools="$tmp_dir/missing-apm-tools"
missing_apm_shim_dir="$tmp_dir/missing-apm-shims"
missing_apm_log="$tmp_dir/missing-apm-mise.log"
mkdir -p "$missing_apm_dir" "$missing_apm_tools" "$missing_apm_shim_dir"
ln -s /usr/bin/dirname "$missing_apm_tools/dirname"
ln -s /usr/bin/mkdir "$missing_apm_tools/mkdir"
ln -s /usr/bin/cp "$missing_apm_tools/cp"
ln -s /usr/bin/cmp "$missing_apm_tools/cmp"
ln -s /usr/bin/mktemp "$missing_apm_tools/mktemp"
ln -s /usr/bin/rm "$missing_apm_tools/rm"
cat >"$missing_apm_dir/mise" <<'STUB'
#!/usr/bin/bash
set -euo pipefail
printf '%s\n' "$*" >>"$MISE_STUB_LOG"
printf 'MISE_CONFIG_FILE=%s\n' "${MISE_CONFIG_FILE:-}" >>"$MISE_STUB_LOG"
printf 'PWD=%s\n' "$PWD" >>"$MISE_STUB_LOG"
case "$*" in
  'activate bash')
    printf 'export PATH="%s:$PATH"\n' "$APM_SHIM_DIR"
    ;;
  'install pipx:apm-cli'|'trust')
    ;;
  *)
    printf '[STUB mise] %s\n' "$*"
    ;;
esac
STUB
chmod +x "$missing_apm_dir/mise"
cat >"$missing_apm_shim_dir/apm" <<'STUB'
#!/usr/bin/bash
set -euo pipefail
printf '[STUB apm] %s\n' "$*"
STUB
chmod +x "$missing_apm_shim_dir/apm"
output=$(HOME="$tmp_dir/missing-apm-home" PATH="$missing_apm_dir:$missing_apm_tools" MISE_STUB_LOG="$missing_apm_log" APM_SHIM_DIR="$missing_apm_shim_dir" /usr/bin/bash "$de_cmd" apm --version)
assert_contains "$(cat "$missing_apm_log")" 'install pipx:apm-cli'
assert_contains "$(cat "$missing_apm_log")" "MISE_CONFIG_FILE=$repo_root/dot_config/mise/config.toml"
assert_contains "$(cat "$missing_apm_log")" "PWD=$repo_root"
assert_contains "$output" '[STUB apm] --version'
assert_not_contains "$output" '[RUN] apm --version'
assert_not_contains "$output" '[OK] apm --version'

output=$(HOME="$tmp_dir/default-home" "$de_cmd")
assert_not_contains "$output" '[RUN] mise run os-dependencies'
assert_contains "$output" '[RUN] mise install'
assert_contains "$output" '[RUN] mise run setup'
assert_contains "$output" '[STUB mise] run setup'

if "$de_cmd" unknown >"$tmp_dir/devenv-unknown.out" 2>"$tmp_dir/devenv-unknown.err"; then
  fail 'unknown subcommand should fail'
fi
assert_contains "$(cat "$tmp_dir/devenv-unknown.err")" 'Usage: de'

install_bin="$tmp_dir/install-bin"
install_tools="$tmp_dir/install-tools"
install_target="$tmp_dir/dotfiles-target"
install_log="$tmp_dir/install-git.log"
mkdir -p "$install_bin" "$install_tools"

for tool in bash dirname mktemp rm mkdir cat chmod; do
  tool_path=$(command -v "$tool") || fail "required test tool not found: $tool"
  ln -s "$tool_path" "$install_tools/$tool"
done

for tool in curl apt-get sudo; do
  cat >"$install_bin/$tool" <<STUB
#!$bash_path
set -euo pipefail
printf 'unexpected %s invocation during install contract test\n' '$tool' >&2
exit 127
STUB
  chmod +x "$install_bin/$tool"
done

cat >"$install_bin/git" <<STUB
#!$bash_path
set -euo pipefail
printf '%s\n' "\$*" >>"\$INSTALL_GIT_LOG"
if [[ \$1 == clone ]]; then
  target="\${@: -1}"
  mkdir -p "\$target/bin"
  cat >"\$target/bin/de" <<'INNER'
#!$bash_path
set -euo pipefail
printf '[CLONED de] %s\n' "\$*"
INNER
  chmod +x "\$target/bin/de"
fi
STUB
chmod +x "$install_bin/git"

set +e
HOME="$tmp_dir/install-success-home" PATH="$install_bin:$install_tools" INSTALL_GIT_LOG="$install_log" "$de_cmd" install --repo https://example.com/dotfiles.git --branch feature/test --path "$install_target" >"$tmp_dir/install-success.out" 2>"$tmp_dir/install-success.err"
install_status=$?
set -e
install_output=$(cat "$tmp_dir/install-success.out")
if [[ $install_status -ne 0 ]]; then
  printf 'stdout was:\n%s\nstderr was:\n%s\n' "$install_output" "$(cat "$tmp_dir/install-success.err")" >&2
  fail 'install success contract should pass'
fi
assert_contains "$(cat "$install_log")" 'clone --branch feature/test -- https://example.com/dotfiles.git'
assert_contains "$(cat "$install_log")" "$install_target"
assert_contains "$install_output" '[RUN] git clone'
assert_not_contains "$install_output" '[RUN] de'
assert_contains "$install_output" '[CLONED de] init'

dash_repo_target="$tmp_dir/dash-repo-target"
dash_repo_log="$tmp_dir/dash-repo-git.log"
output=$(HOME="$tmp_dir/dash-repo-home" PATH="$install_bin:$install_tools" INSTALL_GIT_LOG="$dash_repo_log" "$de_cmd" install --repo ./-repo --branch dash/test --path "$dash_repo_target")
assert_contains "$(cat "$dash_repo_log")" "clone --branch dash/test -- ./-repo $dash_repo_target"
assert_contains "$output" '[RUN] git clone'
assert_not_contains "$output" '[RUN] de'
assert_contains "$output" '[CLONED de] init'

raw_install_target="$tmp_dir/raw-dotfiles-target"
raw_install_log="$tmp_dir/raw-install-git.log"
output=$(HOME="$tmp_dir/raw-install-home" PATH="$install_bin:$install_tools" INSTALL_GIT_LOG="$raw_install_log" "$bash_path" -s -- install --repo https://example.com/raw.git --branch raw/test --path "$raw_install_target" <"$de_cmd")
assert_contains "$(cat "$raw_install_log")" 'clone --branch raw/test -- https://example.com/raw.git'
assert_contains "$(cat "$raw_install_log")" "$raw_install_target"
assert_contains "$output" '[RUN] git clone'
assert_not_contains "$output" '[RUN] de'
assert_contains "$output" '[CLONED de] init'

install_bootstrap_bin="$tmp_dir/install-bootstrap-bin"
install_bootstrap_tools="$tmp_dir/install-bootstrap-tools"
install_bootstrap_shims="$tmp_dir/install-bootstrap-shims"
install_bootstrap_log="$tmp_dir/install-bootstrap.log"
mkdir -p "$install_bootstrap_bin" "$install_bootstrap_tools" "$install_bootstrap_shims"

for tool in dirname mkdir cp cmp chmod cat; do
  tool_path=$(command -v "$tool") || fail "required test tool not found: $tool"
  ln -s "$tool_path" "$install_bootstrap_tools/$tool"
done

cat >"$install_bootstrap_bin/mise" <<'STUB'
#!/usr/bin/bash
set -euo pipefail
case "$*" in
  'activate bash')
    printf 'MISE:activate bash\n' >>"$INSTALL_BOOTSTRAP_LOG"
    printf 'export PATH="%s:$PATH"\n' "$INSTALL_BOOTSTRAP_SHIMS"
    ;;
  'trust')
    printf 'MISE:trust\n' >>"$INSTALL_BOOTSTRAP_LOG"
    ;;
  'install chezmoi')
    printf 'MISE:install chezmoi\n' >>"$INSTALL_BOOTSTRAP_LOG"
    cat >"$INSTALL_BOOTSTRAP_SHIMS/chezmoi" <<'INNER'
#!/usr/bin/bash
set -euo pipefail
printf 'CHEZMOI:%s\n' "$*" >>"$INSTALL_BOOTSTRAP_LOG"
printf '[STUB chezmoi] %s\n' "$*"
INNER
    chmod +x "$INSTALL_BOOTSTRAP_SHIMS/chezmoi"
    printf '[STUB mise] install chezmoi\n'
    ;;
  'install')
    printf 'MISE:install-default\n' >>"$INSTALL_BOOTSTRAP_LOG"
    printf '[STUB mise] install\n'
    ;;
  'run setup')
    printf 'MISE:run-setup\n' >>"$INSTALL_BOOTSTRAP_LOG"
    printf '[STUB mise] run setup\n'
    ;;
  *)
    printf 'MISE:%s\n' "$*" >>"$INSTALL_BOOTSTRAP_LOG"
    printf '[STUB mise] %s\n' "$*"
    ;;
esac
STUB
chmod +x "$install_bootstrap_bin/mise"

output=$(HOME="$tmp_dir/init-home" PATH="$install_bootstrap_bin:$install_bootstrap_tools" INSTALL_BOOTSTRAP_LOG="$install_bootstrap_log" INSTALL_BOOTSTRAP_SHIMS="$install_bootstrap_shims" /usr/bin/bash "$de_cmd" init)
bootstrap_log_output=$(cat "$install_bootstrap_log")
assert_contains "$output" '[RUN] mise install chezmoi'
assert_contains "$output" '[RUN] chezmoi apply'
assert_contains "$output" '[RUN] mise install'
assert_contains "$output" '[RUN] mise run setup'
assert_line_before "$bootstrap_log_output" 'MISE:install chezmoi' "CHEZMOI:apply --source $repo_root"
assert_line_before "$bootstrap_log_output" "CHEZMOI:apply --source $repo_root" 'MISE:install-default'
assert_line_before "$bootstrap_log_output" 'MISE:install-default' 'MISE:run-setup'

if HOME="$tmp_dir/install-bootstrap-home" PATH="$install_bootstrap_bin:$install_bootstrap_tools" INSTALL_BOOTSTRAP_LOG="$install_bootstrap_log" INSTALL_BOOTSTRAP_SHIMS="$install_bootstrap_shims" /usr/bin/bash "$de_cmd" install-bootstrap >"$tmp_dir/install-bootstrap.out" 2>"$tmp_dir/install-bootstrap.err"; then
  fail 'install-bootstrap should no longer be a supported subcommand'
fi
assert_contains "$(cat "$tmp_dir/install-bootstrap.err")" 'Usage: de'

existing_target="$tmp_dir/existing-dotfiles"
mkdir -p "$existing_target"
set +e
HOME="$tmp_dir/install-existing-home" PATH="$install_bin:$install_tools" "$de_cmd" install --path "$existing_target" >"$tmp_dir/install-existing.out" 2>"$tmp_dir/install-existing.err"
install_existing_status=$?
set -e
if [[ $install_existing_status -eq 0 ]]; then
  fail 'install should fail when target path already exists'
fi
assert_contains "$(cat "$tmp_dir/install-existing.err")" 'already exists'

for option in --repo --branch --path; do
  set +e
  HOME="$tmp_dir/install-missing-value-home" PATH="$install_bin:$install_tools" "$de_cmd" install "$option" >"$tmp_dir/install-missing-value.out" 2>"$tmp_dir/install-missing-value.err"
  install_missing_value_status=$?
  set -e
  if [[ $install_missing_value_status -ne 2 ]]; then
    printf 'stdout was:\n%s\nstderr was:\n%s\n' "$(cat "$tmp_dir/install-missing-value.out")" "$(cat "$tmp_dir/install-missing-value.err")" >&2
    fail "install $option without a value should exit 2"
  fi
  assert_contains "$(cat "$tmp_dir/install-missing-value.err")" 'Usage: de'
done

missing_git_bin="$tmp_dir/missing-git-bin"
mkdir -p "$missing_git_bin"
dirname_path=$(command -v dirname) || fail 'required test tool not found: dirname'
ln -s "$dirname_path" "$missing_git_bin/dirname"
cat >"$missing_git_bin/id" <<STUB
#!$bash_path
set -euo pipefail
if [[ \${1:-} == '-u' ]]; then
  printf '1000\n'
fi
STUB
chmod +x "$missing_git_bin/id"

set +e
HOME="$tmp_dir/install-home" PATH="$missing_git_bin" "$bash_path" "$de_cmd" install --path "$tmp_dir/no-git-target" >"$tmp_dir/install-missing-git.out" 2>"$tmp_dir/install-missing-git.err"
install_missing_git_status=$?
set -e
if [[ $install_missing_git_status -eq 0 ]]; then
  fail 'install should fail when git is unavailable and cannot be installed'
fi
assert_contains "$(cat "$tmp_dir/install-missing-git.err")" 'git is required to install dotfiles.'

missing_tools_dir="$tmp_dir/missing-tools"
mkdir -p "$missing_tools_dir"
ln -s /usr/bin/dirname "$missing_tools_dir/dirname"
cat >"$missing_tools_dir/id" <<'STUB'
#!/usr/bin/env bash
set -euo pipefail
if [[ ${1:-} == '-u' ]]; then
  printf '1000\n'
fi
STUB
chmod +x "$missing_tools_dir/id"

if HOME="$tmp_dir/bootstrap-home" PATH="$missing_tools_dir" /usr/bin/bash "$de_cmd" mise --version >"$tmp_dir/missing-curl.out" 2>"$tmp_dir/missing-curl.err"; then
  fail 'missing curl bootstrap should fail'
fi
assert_contains "$(cat "$tmp_dir/missing-curl.err")" 'curl is required to install mise.'
