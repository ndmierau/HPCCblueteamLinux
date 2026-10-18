#!/usr/bin/env bash
# READ-ONLY triage (Ubuntu + Fedora). Changes nothing. Output saved to /root/sweep-<time>.txt
# Red Team may have left "presents" before the competition, so run this FIRST.
[[ $EUID -eq 0 ]] || { echo "Run as root: sudo ./sweep.sh"; exit 1; }
OUT=/root/sweep-$(date +%H%M%S).txt
{
echo "=== OS ==="; . /etc/os-release; echo "$PRETTY_NAME"; command -v getenforce >/dev/null && echo "SELinux: $(getenforce)"
echo; echo "=== Listening ports ===";            ss -tulpn
echo; echo "=== Established connections ===";    ss -tnp state established
echo; echo "=== UID 0 accounts (should be only root) ==="; awk -F: '$3==0{print $1}' /etc/passwd
echo; echo "=== Accounts with login shells ===";  grep -vE '(nologin|false|sync|shutdown|halt)$' /etc/passwd
echo; echo "=== Admin groups ===";                getent group sudo adm wheel
echo; echo "=== sudoers NOPASSWD / extra files ==="; grep -rn "NOPASSWD" /etc/sudoers /etc/sudoers.d 2>/dev/null; ls -la /etc/sudoers.d
echo; echo "=== Effective sshd settings ==="; sshd -T 2>/dev/null | grep -Ei 'permitrootlogin|passwordauthentication|pubkeyauth|authorizedkeysfile|permitemptypasswords|allowusers|authorizedkeyscommand|^port '
echo; echo "=== authorized_keys files ==="
for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do [[ -f $f ]] && { echo "--- $f"; cat "$f"; }; done
echo; echo "=== Cron jobs ==="
for u in $(cut -d: -f1 /etc/passwd); do c=$(crontab -u "$u" -l 2>/dev/null) && echo "--- $u" && echo "$c"; done
ls -la /etc/cron.d /etc/cron.hourly /etc/cron.daily 2>/dev/null; atq 2>/dev/null
echo; echo "=== systemd timers ==="; systemctl list-timers --all --no-pager
echo; echo "=== Enabled systemd services ==="; systemctl list-unit-files --state=enabled --no-pager
echo; echo "=== Log collectors (should be left ALONE: they feed OpenObserve) ==="
systemctl list-units --type=service --no-pager | grep -iE 'otel|openobserve|vector|fluent|promtail|collector'
echo; echo "=== Shell/login persistence ==="
cat /etc/ld.so.preload 2>/dev/null && echo "^^ ld.so.preload exists!"
ls -la /etc/profile.d
grep -nE "curl|wget|nc |ncat|/dev/tcp|bash -i|python.*socket" /etc/profile /etc/profile.d/* /etc/bash.bashrc /etc/bashrc /root/.bashrc /root/.profile /home/*/.bashrc /home/*/.profile 2>/dev/null
echo; echo "=== SUID binaries ==="; find / -xdev -perm -4000 -type f 2>/dev/null
echo; echo "=== Recent logins ==="; last -n 20; echo "--- failed:"; lastb -n 20 2>/dev/null
echo; echo "=== /etc changed in last 24h ==="; find /etc -mtime -1 -type f 2>/dev/null
echo; echo "=== Docker ==="; command -v docker >/dev/null && docker ps --format '{{.Names}}\t{{.Ports}}' || echo "docker not found"
echo; echo "=== Modified packaged files ==="
if command -v debsums >/dev/null; then debsums -c 2>/dev/null | head -50
elif command -v rpm >/dev/null; then rpm -Va --nomtime 2>/dev/null | grep -E '^..5' | grep -v ' c ' | head -50; fi
} 2>&1 | tee "$OUT"
echo; echo "Saved to $OUT (keep it on the box; don't copy competition data off-site)"
