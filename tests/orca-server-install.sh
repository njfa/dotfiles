#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config=$repo_root/dot_config/mise/config.toml
script=$repo_root/etc/os/ubuntu/opt/orca-server.sh
tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

task_body=$(awk '/^\[tasks\.orca-server\]/{f=1; next} /^\[/{f=0} f' "$config")
default_body=$(awk '/^\[tasks\.default\]/{f=1; next} /^\[/{f=0} f' "$config")
optional_body=$(awk '/^\[tasks\.optional\]/{f=1; next} /^\[/{f=0} f' "$config")

[[ $task_body == *'bash etc/os/ubuntu/opt/orca-server.sh'* ]] || fail 'orca-server task does not run its installer'
[[ $task_body == *'export ORCA_VERSION=v'* ]] || fail 'orca-server task does not pin a version'
[[ $task_body == *'export ORCA_SHA256_AMD64='* ]] || fail 'orca-server task does not pin the amd64 checksum'
[[ $task_body == *'export ORCA_SHA256_ARM64='* ]] || fail 'orca-server task does not pin the arm64 checksum'
[[ $default_body != *'orca-server'* ]] || fail 'orca-server must not run during the default setup'
[[ $optional_body != *'orca-server'* ]] || fail 'orca-server must not run during the optional setup'

missing_tailscale_output=$(
    ORCA_VERSION=test \
        ORCA_SHA256_AMD64=test \
        ORCA_SHA256_ARM64=test \
        bash "$script" 2>&1 || true
)
[[ $missing_tailscale_output == *'Tailscale is required before installing Orca Server.'* ]] || fail 'missing Tailscale should be rejected'

grep -Fq 'User=$service_user' "$script" || fail 'systemd service must run as an unprivileged user'
grep -Fq 'tailscale-online.target' "$script" || fail 'systemd service must wait for Tailscale'
grep -Fq 'ExecStartPre=$tailscale_binary wait --timeout=60s' "$script" || fail 'systemd service must verify that Tailscale is ready'
grep -Fq 'RestartPreventExitStatus=3' "$script" || fail 'systemd service must stop retrying on profile lock'
grep -Fq 'LIBGL_ALWAYS_SOFTWARE=1' "$script" || fail 'headless service must use software rendering'
grep -Fq -- '--pairing-address $pairing_address --mobile-pairing --json' "$script" || fail 'service must emit a mobile-scoped pairing offer'
grep -Fq 'sha256sum "$staged_binary"' "$script" || fail 'downloaded AppImage must be checksum verified'
grep -Fq 'libgtk-3-0t64' "$script" || fail 'Ubuntu 24.04 Electron dependencies are missing'
grep -Fq 'libgtk-3-0 ' "$script" || fail 'Ubuntu 20.04/22.04 Electron dependencies are missing'

tools_dir=$tmp_dir/tools
test_home=$tmp_dir/home
install_dir=$tmp_dir/opt/orca
systemd_dir=$tmp_dir/systemd
log_file=$tmp_dir/commands.log
os_release_file=$tmp_dir/os-release
mkdir -p "$tools_dir" "$test_home" "$systemd_dir"
printf 'ID=ubuntu\nVERSION_ID=24.04\n' >"$os_release_file"

cat >"$tools_dir/id" <<'STUB'
#!/usr/bin/env bash
if [[ ${1:-} == -u ]]; then
    printf '1000\n'
else
    exec /usr/bin/id "$@"
fi
STUB

cat >"$tools_dir/sudo" <<'STUB'
#!/usr/bin/env bash
printf 'sudo' >>"$ORCA_TEST_LOG"
printf ' %q' "$@" >>"$ORCA_TEST_LOG"
printf '\n' >>"$ORCA_TEST_LOG"
exec "$@"
STUB

cat >"$tools_dir/getent" <<'STUB'
#!/usr/bin/env bash
if [[ ${1:-} == passwd && ${2:-} == tester ]]; then
    printf 'tester:x:1000:1000:Test User:%s:/bin/bash\n' "$ORCA_TEST_HOME"
    exit 0
fi
exit 2
STUB

cat >"$tools_dir/uname" <<'STUB'
#!/usr/bin/env bash
if [[ ${1:-} == -m ]]; then
    printf 'aarch64\n'
else
    exec /usr/bin/uname "$@"
fi
STUB

cat >"$tools_dir/apt-get" <<'STUB'
#!/usr/bin/env bash
printf 'apt-get' >>"$ORCA_TEST_LOG"
printf ' %q' "$@" >>"$ORCA_TEST_LOG"
printf '\n' >>"$ORCA_TEST_LOG"
STUB

cat >"$tools_dir/curl" <<'STUB'
#!/usr/bin/env bash
output=
url=
while (($#)); do
    case "$1" in
    -o)
        output=$2
        shift 2
        ;;
    --retry)
        shift 2
        ;;
    -*)
        shift
        ;;
    *)
        url=$1
        shift
        ;;
    esac
done
printf 'curl %s\n' "$url" >>"$ORCA_TEST_LOG"
printf 'fake-orca-arm64' >"$output"
STUB

cat >"$tools_dir/install" <<'STUB'
#!/usr/bin/env bash
args=()
while (($#)); do
    case "$1" in
    -o | -g)
        shift 2
        ;;
    *)
        args+=("$1")
        shift
        ;;
    esac
done
exec /usr/bin/install "${args[@]}"
STUB

cat >"$tools_dir/chown" <<'STUB'
#!/usr/bin/env bash
exit 0
STUB

cat >"$tools_dir/systemctl" <<'STUB'
#!/usr/bin/env bash
printf 'systemctl' >>"$ORCA_TEST_LOG"
printf ' %q' "$@" >>"$ORCA_TEST_LOG"
printf '\n' >>"$ORCA_TEST_LOG"
exit 0
STUB

cat >"$tools_dir/journalctl" <<'STUB'
#!/usr/bin/env bash
printf '{"type":"orca_server_ready","schemaVersion":1,"pairing":{"available":true,"url":"%s","scope":"mobile"}}\n' "$ORCA_TEST_PAIRING_URL"
STUB

cat >"$tools_dir/qrencode" <<'STUB'
#!/usr/bin/env bash
printf 'qrencode' >>"$ORCA_TEST_LOG"
printf ' %q' "$@" >>"$ORCA_TEST_LOG"
printf '\n' >>"$ORCA_TEST_LOG"
printf '[QR]\n'
STUB

cat >"$tools_dir/tailscale" <<'STUB'
#!/usr/bin/env bash
printf 'tailscale' >>"$ORCA_TEST_LOG"
printf ' %q' "$@" >>"$ORCA_TEST_LOG"
printf '\n' >>"$ORCA_TEST_LOG"
case "${1:-}" in
wait)
    exit 0
    ;;
ip)
    if [[ ${2:-} == -4 ]]; then
        printf '100.64.1.20\n'
        exit 0
    fi
    ;;
esac
exit 1
STUB

chmod +x "$tools_dir"/*
arm64_sha256=$(printf 'fake-orca-arm64' | sha256sum | awk '{print $1}')
pairing_payload='{"v":2,"endpoint":"ws://100.64.1.20:6768","deviceToken":"test-token","publicKeyB64":"test-key","scope":"mobile"}'
pairing_code=$(printf '%s' "$pairing_payload" | base64 -w 0 | tr '+/' '-_' | tr -d '=')
pairing_url="orca://pair?code=$pairing_code"

installer_output=$(
    PATH="$tools_dir:$PATH" \
        USER=tester \
        ORCA_TEST_LOG="$log_file" \
        ORCA_TEST_HOME="$test_home" \
        ORCA_TEST_PAIRING_URL="$pairing_url" \
        ORCA_VERSION=v-test \
        ORCA_SHA256_AMD64=unused \
        ORCA_SHA256_ARM64="$arm64_sha256" \
        ORCA_SERVICE_USER=tester \
        ORCA_INSTALL_DIR="$install_dir" \
        ORCA_SYSTEMD_DIR="$systemd_dir" \
        ORCA_OS_RELEASE_FILE="$os_release_file" \
        bash "$script"
)

[[ -x $install_dir/orca-linux.AppImage ]] || fail 'verified AppImage was not installed'
[[ $(<"$install_dir/VERSION") == v-test ]] || fail 'installed version was not recorded'
grep -Fq 'releases/download/v-test/orca-linux-arm64.AppImage' "$log_file" || fail 'arm64 AppImage was not selected'
grep -Fq 'libgtk-3-0t64' "$log_file" || fail 'Ubuntu 24.04 packages were not selected'
grep -Fq 'systemctl is-active --quiet tailscaled.service' "$log_file" || fail 'tailscaled service state was not checked'
grep -Fq 'tailscale wait --timeout=30s' "$log_file" || fail 'Tailscale readiness was not checked'
grep -Fq 'tailscale ip -4' "$log_file" || fail 'Tailscale IPv4 address was not resolved'
grep -Fq 'systemctl restart orca-serve.service' "$log_file" || fail 'Orca service was not restarted'
grep -Fq 'User=tester' "$systemd_dir/orca-serve.service" || fail 'service user was not configured'
grep -Fq 'WorkingDirectory='"$test_home" "$systemd_dir/orca-serve.service" || fail 'service home was not configured'
grep -Fq 'After=network-online.target tailscaled.service tailscale-online.target' "$systemd_dir/orca-serve.service" || fail 'service does not start after Tailscale'
grep -Fq 'ExecStartPre='"$tools_dir"'/tailscale wait --timeout=60s' "$systemd_dir/orca-serve.service" || fail 'service does not wait for Tailscale readiness'
grep -Fq 'ExecStart='"$install_dir"'/orca-linux.AppImage serve --port 6768 --pairing-address 100.64.1.20 --mobile-pairing --json' "$systemd_dir/orca-serve.service" || fail 'headless mobile service command is incorrect'
grep -Fq 'qrencode -t ANSIUTF8 orca://pair\?code=' "$log_file" || fail 'mobile pairing QR code was not generated'
[[ $installer_output == *'Mobile pairing URL:'* ]] || fail 'mobile pairing URL was not shown'
[[ $installer_output == *'Treat the pairing URL as a secret'* ]] || fail 'pairing secret warning was not shown'

printf 'PASS: Orca server is an explicit, pinned, headless-only task\n'
