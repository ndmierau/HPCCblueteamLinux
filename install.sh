#!/usr/bin/env bash
# Installs blue team tooling. Supports Ubuntu 22.04 (guidance) and Fedora Server 38 (ignition). Safe to re-run.
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root: sudo ./install.sh"; exit 1; }
. /etc/os-release; echo "Detected: $PRETTY_NAME"

if command -v apt-get >/dev/null; then
  export DEBIAN_FRONTEND=noninteractive
  echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections
  PACKAGES=(
    ufw fail2ban auditd etckeeper debsums
    rkhunter chkrootkit lynis clamav aide
    tcpdump tshark nmap suricata
    iftop nethogs goaccess
    net-tools lsof htop psmisc tmux jq git curl inotify-tools
  )
  apt-get update
  # --no-install-recommends avoids pulling in a mail server (postfix) that would open port 25
  apt-get install -y --no-install-recommends "${PACKAGES[@]}"

elif command -v dnf >/dev/null; then
  DNF=(dnf -y --setopt=skip_if_unavailable=True --setopt=strict=0)
  # Fedora 38 is end-of-life: if the normal repos fail, point them at the archive
  if ! dnf -q makecache --setopt=skip_if_unavailable=True >/dev/null 2>&1; then
    echo "dnf makecache failed, switching to archive repos..."
    for f in /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo; do
      [[ -f $f ]] && sed -i \
        -e 's|^metalink=|#metalink=|' \
        -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://archives.fedoraproject.org/pub/archive/fedora/linux|' "$f"
    done
    dnf clean all; "${DNF[@]}" makecache
  fi
  PACKAGES=(
    firewalld fail2ban fail2ban-firewalld audit etckeeper
    rkhunter chkrootkit lynis clamav clamav-update aide
    tcpdump wireshark-cli nmap suricata
    iftop nethogs goaccess
    net-tools lsof htop psmisc tmux jq git inotify-tools
  )
  "${DNF[@]}" install "${PACKAGES[@]}"
  MISSING=(); for p in "${PACKAGES[@]}"; do rpm -q "$p" >/dev/null 2>&1 || MISSING+=("$p"); done
  [[ ${#MISSING[@]} -gt 0 ]] && echo "NOT INSTALLED (check 'dnf search <name>'): ${MISSING[*]}"
else
  echo "Unsupported package manager"; exit 1
fi
echo "Done. Next: sudo ./sweep.sh  (read-only), then sudo ./harden.sh"
