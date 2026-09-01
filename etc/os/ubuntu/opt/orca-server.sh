#!/usr/bin/env bash
set -euo pipefail

: "${ORCA_VERSION:?ORCA_VERSION is required}"
: "${ORCA_SHA256_AMD64:?ORCA_SHA256_AMD64 is required}"
: "${ORCA_SHA256_ARM64:?ORCA_SHA256_ARM64 is required}"

port=${ORCA_PORT:-6768}
install_dir=${ORCA_INSTALL_DIR:-/opt/orca}
systemd_dir=${ORCA_SYSTEMD_DIR:-/etc/systemd/system}
os_release_file=${ORCA_OS_RELEASE_FILE:-/etc/os-release}
service_name=orca-serve.service

if ! command -v tailscale >/dev/null 2>&1; then
    echo "Tailscale is required before installing Orca Server." >&2
    echo "Install and connect Tailscale, then run: ./bin/de m run orca-server" >&2
    exit 1
fi
tailscale_binary=$(command -v tailscale)
if ! [[ $tailscale_binary =~ ^/[A-Za-z0-9._/-]+$ ]]; then
    echo "The Tailscale executable path is not supported: $tailscale_binary" >&2
    exit 1
fi

if ! systemctl is-active --quiet tailscaled.service; then
    echo "Tailscale is installed, but tailscaled.service is not running." >&2
    echo "Start and connect it before installing Orca Server." >&2
    exit 1
fi

if ! tailscale wait --timeout=30s; then
    echo "Tailscale did not become ready within 30 seconds." >&2
    echo "A recent Tailscale version with the 'tailscale wait' command is required." >&2
    exit 1
fi

if ! pairing_address=$(tailscale ip -4); then
    echo "Unable to obtain this server's Tailscale IPv4 address." >&2
    exit 1
fi
pairing_address_pattern='^100\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'
if ! [[ $pairing_address =~ $pairing_address_pattern ]]; then
    echo "Unable to determine a valid Tailscale IPv4 address: $pairing_address" >&2
    exit 1
fi

case "$port" in
'' | *[!0-9]*)
    echo "ORCA_PORT must be a number between 1 and 65535." >&2
    exit 1
    ;;
esac
if [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
    echo "ORCA_PORT must be a number between 1 and 65535." >&2
    exit 1
fi

case "$install_dir" in
/*) ;;
*)
    echo "ORCA_INSTALL_DIR must be an absolute path." >&2
    exit 1
    ;;
esac
if ! [[ $install_dir =~ ^/[A-Za-z0-9._/-]+$ ]]; then
    echo "ORCA_INSTALL_DIR contains unsupported characters: $install_dir" >&2
    exit 1
fi

if [ ! -r "$os_release_file" ]; then
    echo "Ubuntu could not be detected: $os_release_file is unavailable." >&2
    exit 1
fi
# shellcheck disable=SC1091
. "$os_release_file"
if [ "${ID:-}" != ubuntu ]; then
    echo "Orca server installation supports Ubuntu only (detected: ${ID:-unknown})." >&2
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    service_user=${ORCA_SERVICE_USER:-${SUDO_USER:-}}
    if [ -z "$service_user" ] || [ "$service_user" = root ]; then
        echo "Do not run Orca as root. Set ORCA_SERVICE_USER to an unprivileged user." >&2
        exit 1
    fi
    run_as_root() {
        "$@"
    }
else
    service_user=${ORCA_SERVICE_USER:-${USER:-}}
    if [ -z "$service_user" ]; then
        echo "Unable to determine the Orca service user." >&2
        exit 1
    fi
    if ! command -v sudo >/dev/null 2>&1; then
        echo "sudo is required to install Orca and its systemd service." >&2
        exit 1
    fi
    run_as_root() {
        sudo "$@"
    }
fi

case "$service_user" in
'' | *[!a-zA-Z0-9_.-]*)
    echo "Invalid ORCA_SERVICE_USER: $service_user" >&2
    exit 1
    ;;
esac

passwd_entry=$(getent passwd "$service_user" || true)
if [ -z "$passwd_entry" ]; then
    echo "ORCA_SERVICE_USER does not exist: $service_user" >&2
    exit 1
fi
service_home=$(printf '%s\n' "$passwd_entry" | cut -d: -f6)
if ! [[ $service_home =~ ^/[A-Za-z0-9._/-]+$ ]]; then
    echo "The service user's home directory is not supported: $service_home" >&2
    exit 1
fi

case "$(uname -m)" in
x86_64)
    asset=orca-linux.AppImage
    expected_sha256=$ORCA_SHA256_AMD64
    ;;
aarch64 | arm64)
    asset=orca-linux-arm64.AppImage
    expected_sha256=$ORCA_SHA256_ARM64
    ;;
*)
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

common_packages=(
    curl file jq qrencode xvfb zlib1g-dev ca-certificates git
    libnss3 libgbm1 libxtst6 libdrm2 libxkbcommon0 libpango-1.0-0 libcairo2
    libxcomposite1 libxdamage1 libxfixes3 libxrandr2 libxrender1 libx11-xcb1
    libxcb-dri3-0 libxss1
)
if dpkg --compare-versions "${VERSION_ID:-0}" ge 24.04; then
    electron_packages=(
        libgtk-3-0t64 libatk1.0-0t64 libatk-bridge2.0-0t64 libasound2t64
        libcups2t64 libatspi2.0-0t64 libfuse2t64
    )
else
    electron_packages=(
        libgtk-3-0 libatk1.0-0 libatk-bridge2.0-0 libasound2
        libcups2 libatspi2.0-0 libfuse2
    )
fi

run_as_root apt-get update -y
run_as_root apt-get install -y "${common_packages[@]}" "${electron_packages[@]}"
run_as_root install -d -o root -g root -m 0755 "$install_dir"

binary_path=$install_dir/orca-linux.AppImage
download_url="https://github.com/stablyai/orca/releases/download/${ORCA_VERSION}/${asset}"
installed_sha256=
if run_as_root test -f "$binary_path"; then
    installed_sha256=$(run_as_root sha256sum "$binary_path" | awk '{print $1}')
fi

if [ "$installed_sha256" != "$expected_sha256" ]; then
    staged_binary=$install_dir/orca-linux.AppImage.new
    run_as_root rm -f "$staged_binary"
    run_as_root curl -fL --retry 3 "$download_url" -o "$staged_binary"
    actual_sha256=$(run_as_root sha256sum "$staged_binary" | awk '{print $1}')
    if [ "$actual_sha256" != "$expected_sha256" ]; then
        run_as_root rm -f "$staged_binary"
        echo "Orca checksum verification failed." >&2
        echo "Expected: $expected_sha256" >&2
        echo "Actual:   $actual_sha256" >&2
        exit 1
    fi
    run_as_root chown root:root "$staged_binary"
    run_as_root chmod 0755 "$staged_binary"
    run_as_root mv -f "$staged_binary" "$binary_path"
fi

version_file=$(mktemp)
unit_file=$(mktemp)
cleanup() {
    rm -f "$version_file" "$unit_file"
}
trap cleanup EXIT

printf '%s\n' "$ORCA_VERSION" >"$version_file"
run_as_root install -o root -g root -m 0644 "$version_file" "$install_dir/VERSION"

cat >"$unit_file" <<EOF
[Unit]
Description=Orca headless runtime server
After=network-online.target tailscaled.service tailscale-online.target
Wants=network-online.target tailscaled.service tailscale-online.target
StartLimitIntervalSec=300
StartLimitBurst=5

[Service]
Type=simple
User=$service_user
WorkingDirectory=$service_home
Environment=HOME=$service_home
Environment=PATH=$service_home/.local/bin:$service_home/.local/share/mise/shims:/usr/local/bin:/usr/bin:/bin
Environment=LIBGL_ALWAYS_SOFTWARE=1
ExecStartPre=$tailscale_binary wait --timeout=60s
ExecStart=$binary_path serve --port $port --pairing-address $pairing_address --mobile-pairing --json
StandardOutput=journal
StandardError=journal
KillMode=mixed
Restart=on-failure
RestartPreventExitStatus=3
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

run_as_root install -o root -g root -m 0644 "$unit_file" "$systemd_dir/$service_name"
run_as_root systemctl daemon-reload
run_as_root systemctl enable "$service_name"
run_as_root systemctl reset-failed "$service_name" >/dev/null 2>&1 || true
service_started_at=$(date --iso-8601=seconds)
run_as_root systemctl restart "$service_name"

if ! run_as_root systemctl is-active --quiet "$service_name"; then
    echo "Orca failed to start. Inspect it with:" >&2
    echo "  sudo journalctl -u $service_name -n 100 --no-pager" >&2
    exit 1
fi

echo "Orca $ORCA_VERSION is running as $service_user on port $port."
echo "Advertised address: $pairing_address"

ready_json=
for _ in $(seq 1 30); do
    ready_json=$(run_as_root journalctl -u "$service_name" --since "$service_started_at" -o cat --no-pager \
        | jq -Rrc 'fromjson? | select(.type == "orca_server_ready" and .schemaVersion == 1 and .pairing.scope == "mobile")' \
        | tail -n 1)
    if [ -n "$ready_json" ]; then
        break
    fi
    sleep 1
done

if [ -n "$ready_json" ]; then
    pairing_url=$(printf '%s\n' "$ready_json" | jq -r '.pairing.url // empty')
else
    pairing_url=
fi
if [ -n "$pairing_url" ]; then
    case "$pairing_url" in
    'orca://pair?code='*)
        pairing_code=${pairing_url#orca://pair?code=}
        ;;
    *)
        echo "Orca emitted an unsupported mobile pairing URL." >&2
        exit 1
        ;;
    esac

    normalized_code=${pairing_code//-/+}
    normalized_code=${normalized_code//_/\/}
    case $((${#normalized_code} % 4)) in
    2) normalized_code="${normalized_code}==" ;;
    3) normalized_code="${normalized_code}=" ;;
    0) ;;
    *)
        echo "Orca emitted a malformed mobile pairing code." >&2
        exit 1
        ;;
    esac
    if ! pairing_payload=$(printf '%s' "$normalized_code" | base64 --decode 2>/dev/null); then
        echo "Orca emitted a mobile pairing code that could not be decoded." >&2
        exit 1
    fi
    if ! printf '%s\n' "$pairing_payload" \
        | jq -e '.v == 2 and .scope == "mobile" and (.endpoint | type == "string") and (.deviceToken | type == "string") and (.publicKeyB64 | type == "string")' \
            >/dev/null; then
        echo "Orca emitted a pairing code that is not valid for Orca Mobile." >&2
        exit 1
    fi

    echo
    echo "Mobile pairing URL:"
    echo "$pairing_url"
    echo
    echo "Scan this QR code from Orca Mobile:"
    qrencode -t ANSIUTF8 "$pairing_url"
    echo "Treat the pairing URL as a secret and share it only with the intended phone."
else
    if [ -n "$ready_json" ]; then
        pairing_reason=$(printf '%s\n' "$ready_json" | jq -r '.pairing.reason // "unknown"')
        pairing_guidance=$(printf '%s\n' "$ready_json" | jq -r '.pairing.guidance // "Inspect the Orca service logs."')
    else
        pairing_reason=startup_timeout
        pairing_guidance="Orca did not emit readiness JSON within 30 seconds."
    fi
    echo "Orca started, but a mobile pairing URL was not available: $pairing_reason" >&2
    echo "$pairing_guidance" >&2
    echo "Inspect logs with: sudo journalctl -u $service_name -n 100 --no-pager" >&2
    exit 1
fi
