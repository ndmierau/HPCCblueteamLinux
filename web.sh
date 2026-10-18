#!/usr/bin/env bash
# Apache2 checks for PlinkCom (172.16.t.10). Read-only except for the backup.
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
mkdir -p /root/backup
tar czf /root/backup/apache-$(date +%H%M%S).tgz /etc/apache2 /var/www 2>/dev/null

echo "=== Config syntax ==="; apache2ctl configtest
echo; echo "=== Vhosts ===";     apache2ctl -S 2>&1
echo; echo "=== Enabled modules ==="; apache2ctl -M 2>&1
echo; echo "=== Files in /var/www changed in last 24h ==="; find /var/www -type f -mtime -1 2>/dev/null
echo; echo "=== Suspicious PHP patterns ==="
grep -rEl "eval\(base64_decode|system\(\$_|shell_exec\(\$_|passthru\(|assert\(\$_" /var/www 2>/dev/null
echo; echo "=== .htaccess files ==="; find /var/www -name .htaccess 2>/dev/null
echo; echo "=== Files owned by root/unusual perms in webroot (world-writable) ==="; find /var/www -perm -o+w 2>/dev/null
echo; echo "=== Top client IPs in access log ==="
awk '{print $1}' /var/log/apache2/access.log 2>/dev/null | sort | uniq -c | sort -rn | head
echo; echo "Live view: goaccess /var/log/apache2/access.log --log-format=COMBINED"
