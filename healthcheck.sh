#!/usr/bin/env bash
# Quick "are my scored Linux services up?" check. Usage: ./healthcheck.sh <team-number>
#old is T="${1:?usage: ./healthcheck.sh <team-number>}"
T="${1:-26}"
for ip in 172.16.$T.10 172.16.$T.20; do
  (echo > /dev/tcp/$ip/22) 2>/dev/null && echo "SSH        $ip: UP" || echo "SSH        $ip: DOWN"
done
curl -s -m 5 -o /dev/null -w "PlinkCom   172.16.$T.10: HTTP %{http_code}\n" "http://172.16.$T.10/"
curl -s -m 5 -o /dev/null -w "Open WebUI 172.16.$T.20: HTTP %{http_code}\n" "http://172.16.$T.20/"
echo "(Authoritative view: scoreboard.plinko.horse -> Details)"
