#!/usr/bin/env bash
set -euo pipefail

die() {
    echo "$*" >&2
    exit 1
}

need() {
    command -v "$1" >/dev/null 2>&1 || die "Missing required command: $1"
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    die "Run this script with sudo."
fi

need systemctl
need sysctl

echo "=== Waydroid Network Fix ==="

bridge_name() {
    local bridge
    local config="/var/lib/waydroid/lxc/waydroid/config"

    bridge=""
    if [[ -r "$config" ]]; then
        bridge="$(
            awk -F'[[:space:]]*=[[:space:]]*' '
                $1 == "lxc.net.0.link" || $1 == "lxc.network.link" {
                    print $2
                    exit
                }
            ' "$config"
        )"
    fi

    printf '%s\n' "${bridge:-waydroid0}"
}

ensure_iptables_rule() {
    local ipt_bin="$1"
    local mode="$2"
    local table="$3"
    local chain="$4"
    shift 4

    local table_args=()
    if [[ "$table" != "-" ]]; then
        table_args=(-t "$table")
    fi

    if ! "$ipt_bin" "${table_args[@]}" -C "$chain" "$@"; then
        "$ipt_bin" "${table_args[@]}" "$mode" "$chain" "$@"
    fi
}

echo "Enabling IPv4 forwarding..."
sysctl -w net.ipv4.ip_forward=1 >/dev/null

bridge="$(bridge_name)"

if systemctl is-active --quiet firewalld; then
    need firewall-cmd
    echo "Configuring firewalld..."
    firewall-cmd --zone=trusted --add-interface="$bridge" --permanent >/dev/null || true
    firewall-cmd --zone=trusted --add-interface="$bridge" >/dev/null || true
    firewall-cmd --reload >/dev/null
else
    iptables_bin="$(command -v iptables-legacy || command -v iptables || true)"
    [[ -n "$iptables_bin" ]] || die "Missing required command: iptables or iptables-legacy"

    echo "Configuring iptables..."
    ensure_iptables_rule "$iptables_bin" -I "-" INPUT -i "$bridge" -p udp --dport 67 -j ACCEPT
    ensure_iptables_rule "$iptables_bin" -I "-" INPUT -i "$bridge" -p tcp --dport 67 -j ACCEPT
    ensure_iptables_rule "$iptables_bin" -I "-" INPUT -i "$bridge" -p udp --dport 53 -j ACCEPT
    ensure_iptables_rule "$iptables_bin" -I "-" INPUT -i "$bridge" -p tcp --dport 53 -j ACCEPT
    ensure_iptables_rule "$iptables_bin" -I "-" FORWARD -i "$bridge" -j ACCEPT
    ensure_iptables_rule "$iptables_bin" -I "-" FORWARD -o "$bridge" -j ACCEPT
    ensure_iptables_rule "$iptables_bin" -A nat POSTROUTING -s 192.168.240.0/24 ! -d 192.168.240.0/24 -j MASQUERADE
    ensure_iptables_rule "$iptables_bin" -A mangle POSTROUTING -o "$bridge" -p udp --dport 68 -j CHECKSUM --checksum-fill
fi

echo "Done. If Waydroid was already running, reconnect it or restart the session."
