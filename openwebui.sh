#!/usr/bin/env bash
# Open WebUI checks for "Ignition" (172.16.t.20). Read-only except for the backup.
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
mkdir -p /root/backup

echo "=== What is listening on 80 / 8080 / 3000? ==="
ss -tulpn | grep -E ':(80|8080|3000|443)\b'

echo; echo "=== Reverse proxy present? ==="
for s in nginx apache2 caddy haproxy; do systemctl is-active --quiet "$s" && echo "$s: ACTIVE"; done
echo "--- nginx sites:";  ls -la /etc/nginx/sites-enabled /etc/nginx/conf.d 2>/dev/null
echo "--- apache sites:"; ls -la /etc/apache2/sites-enabled 2>/dev/null
grep -rE "proxy_pass|ProxyPass" /etc/nginx /etc/apache2 2>/dev/null

echo; echo "=== Open WebUI process / service ==="
ps aux | grep -iE "open-webui|open_webui|uvicorn" | grep -v grep
systemctl list-units --type=service --all --no-pager | grep -iE "webui|ollama|open"
echo "--- unit files:"; grep -rliE "open-webui|open_webui" /etc/systemd/system /lib/systemd/system 2>/dev/null

echo; echo "=== Ollama (model backend) ==="
systemctl is-active ollama 2>/dev/null; ss -tulpn | grep 11434

echo; echo "=== Data (chat history = scored!) ==="
DBS=$(find / -xdev -name webui.db 2>/dev/null)
echo "${DBS:-no webui.db found}"
for db in $DBS; do
  d=$(dirname "$db")
  tar czf "/root/backup/openwebui-data-$(date +%H%M%S).tgz" "$d" 2>/dev/null && echo "Backed up $d to /root/backup/"
done

echo; echo "=== Local health check ==="
curl -s -o /dev/null -w "http://localhost/  -> HTTP %{http_code}\n" http://localhost/
curl -s -o /dev/null -w "http://localhost:8080/ -> HTTP %{http_code}\n" http://localhost:8080/

echo; echo "Tip: protect webui.db (chmod 600, owned by the service user) and watch it: ausearch -f webui.db -i"
