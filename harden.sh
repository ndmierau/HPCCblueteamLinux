#!/usr/bin/env bash
# Baseline hardening: Ubuntu 22.04 (ufw) and Fedora 38 (firewalld).
# Does NOT change passwords, SSH config, SELinux, or shells (do passwords by hand, see checklist.md).
#
#   sudo ALLOW_PORTS="80" WHITELIST="1.2.3.4" ./harden.sh        (SSH/22 always allowed; YES=1 skips the prompt)
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
ALLOW_PORTS="${ALLOW_PORTS:-80}"; WHITELIST="${WHITELIST:-}"
warn(){ echo "WARN: $*"; }
if command -v apt-get >/dev/null; then OS=deb; elif command -v dnf >/dev/null; then OS=rpm; else echo "unsupported"; exit 1; fi
. /etc/os-release
if [[ "${ID:-}" == "linuxmint" || "$(hostname -s)" == blackbox* ]]; then
  echo "This looks like blackbox (OpenObserve + backups). Refusing: a default-deny firewall could break log ingestion."
  echo "Override only if you know what you're doing: FORCE=1 sudo ./harden.sh"; [[ "${FORCE:-0}" == 1 ]] || exit 1
fi
TS=$(date +%H%M%S); mkdir -p /root/backup

echo "[1/7] Backups"
tar czf /root/backup/etc-$TS.tgz /etc 2>/dev/null
[[ -d /var/www ]] && tar czf /root/backup/www-$TS.tgz /var/www 2>/dev/null

echo "[2/7] etckeeper"
etckeeper init 2>/dev/null; etckeeper commit "baseline before hardening" 2>/dev/null

echo "[3/7] Port check (allowing: 22 $ALLOW_PORTS)"
BLOCKED=0
for p in $(ss -tlnH | awk '{print $4}' | grep -vE '^(127\.|\[::1\]|\[::ffff:127)' | sed 's/.*://' | sort -un); do
  [[ " 22 $ALLOW_PORTS " == *" $p "* ]] || { echo "  !! port $p is listening externally and WILL BE BLOCKED"; BLOCKED=1; }
done
if [[ $BLOCKED -eq 1 && "${YES:-0}" != 1 ]]; then read -rp "Is blocking those OK (not a scored service)? [y/N] " a; [[ $a == y ]] || exit 1; fi

echo "[4/7] Firewall"
if [[ $OS == deb ]]; then
  ufw allow 22/tcp; for p in $ALLOW_PORTS; do ufw allow "$p/tcp"; done
  ufw default deny incoming; ufw default allow outgoing; ufw --force enable; ufw status verbose
  echo "NOTE: Docker-published ports bypass UFW."
else
  systemctl enable --now firewalld
  firewall-cmd --permanent --add-service=ssh
  for p in $ALLOW_PORTS; do firewall-cmd --permanent --add-port="$p/tcp"; done
  firewall-cmd --permanent --remove-service=cockpit 2>/dev/null   # unneeded attack surface
  firewall-cmd --reload; firewall-cmd --list-all
fi

echo "[5/7] fail2ban (lenient on purpose: scorer IPs are unknown; whitelist: ${WHITELIST:-none})"
{
  echo "[DEFAULT]"; echo "ignoreip = 127.0.0.1/8 ::1 $WHITELIST"
  echo "bantime = 5m"; echo "findtime = 10m"; echo "maxretry = 10"
  echo; echo "[sshd]"; echo "enabled = true"
  [[ $OS == rpm ]] && echo "backend = systemd"
  [[ -d /etc/apache2 ]] && { echo; echo "[apache-auth]"; echo "enabled = true"; }
} > /etc/fail2ban/jail.local
systemctl enable --now fail2ban; systemctl restart fail2ban || warn "fail2ban failed to start (journalctl -u fail2ban)"

echo "[6/7] auditd rules (watching only paths that exist; keeps the OpenObserve audit feed intact)"
R=/etc/audit/rules.d/blue.rules; : > $R
add(){ [[ -e $1 ]] && echo "-w $1 -p wa -k $2" >> $R; }
add /etc/passwd identity; add /etc/shadow identity; add /etc/group identity
add /etc/sudoers sudoers; add /etc/sudoers.d/ sudoers
add /etc/ssh/sshd_config ssh; add /root/.ssh/ ssh_keys; add /etc/pam.d/ pam
add /etc/cron.d/ cron; add /var/spool/cron/ cron; add /etc/systemd/system/ systemd
add /etc/apache2/ web; add /etc/httpd/ web; add /etc/nginx/ web; add /var/www/ webroot
systemctl enable auditd 2>/dev/null
augenrules --load >/dev/null 2>&1 || warn "audit rules not loaded (rules may be locked). Not fatal."
echo "Search: ausearch -k identity -i   (keys: identity sudoers ssh ssh_keys pam cron systemd web webroot)"

echo "[7/7] AIDE baseline (background, low priority)"
if [[ $OS == deb ]]; then
  ( nice -n 19 aideinit -y -f >/root/aide-init.log 2>&1 && cp /var/lib/aide/aide.db.new /var/lib/aide/aide.db ) &
else
  ( nice -n 19 aide --init >/root/aide-init.log 2>&1 && mv -f /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz ) &
fi

echo; echo "Done. Verify from a SECOND session + ./healthcheck.sh. Panic buttons:"
echo "  fail2ban-client unban --all"
[[ $OS == deb ]] && echo "  ufw disable" || echo "  firewall-cmd --panic-off ; systemctl stop firewalld"
