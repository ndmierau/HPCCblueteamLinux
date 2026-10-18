# HPCC4 Linux checklist (guidance = Ubuntu 22.04 @ .10, ignition = Fedora 38 @ .20)

Rules reminders: don't replace scored services (Apache stays Apache), don't copy company data off the
environment, AI tools are NOT allowed for inject answers, stay in scope (never hit the Red Team back).

## Minute 0-5: credentials (Red Team has the packet!)
1. `passwd plinktern`  (default H00ves0nTheM00n, admin on every box)
2. `sudo passwd jmoney` -> then scoreboard.plinko.horse > Users > update that box > **Save**.
   NEVER disable jmoney. Password changes aren't accepted while scoring is paused (lunch).
3. App accounts: Open WebUI (plinktern@plinko.horse + jmoney@plinko.horse), PlinkCom (plinktern + jmoney).
   Change jmoney's app passwords too and update NEIGH. PlinkCom's DB lives on manifest (.40): coordinate with
   whoever has the Windows boxes before touching DB passwords, or guidance's site breaks.
4. Reverts reset ALL passwords to defaults. 5 free reverts, then -20 min uptime each. Console + Restart in NEIGH
   are your lockout rescue.

## Minute 5-15: look before you touch
5. `git clone` this repo (verify internet first: `curl -I https://github.com`)
6. `sudo ./install.sh`  then  `sudo ./sweep.sh`  (HLF may have planted persistence before the start)
7. Role script: guidance `sudo ./roles/web.sh`; ignition `sudo ./roles/openwebui.sh`
8. Don't touch the log collectors feeding OpenObserve (blackbox .5). Use its dashboards for Linux Auth.

## Minute 15+: harden
9. `sudo ALLOW_PORTS="80" ./harden.sh`   (both services are plain http on 80; script warns about anything else it would block)
10. Second session: confirm jmoney SSH login, then `./healthcheck.sh <team#>` and the scoreboard Details page.
11. Later: `lynis audit system`, `rkhunter --check`, `clamscan -ri /tmp /var/www /home`, aide check.

## Per-OS gotchas
- Ubuntu: logs `/var/log/auth.log`; firewall `ufw`.
- Fedora: logs `journalctl -u sshd` / `/var/log/secure`; firewall `firewall-cmd`; SELinux enforcing (leave on;
  `ausearch -m avc -ts recent` if something mysteriously breaks); `rpm -Va` instead of debsums.
- IP blocking: the scorer connects from MANY IPs that Red Team may share. Never ban by subnet; keep fail2ban lenient.
- blackbox (.5, Mint 22) is out of Red scope: leave OpenObserve alone.

## Backups -> blackbox
- After harden.sh / role scripts: `sudo ./ship-backups.sh` (pushes /root/backup to blackbox ~/backups/<host>/).
- Change blackbox's plinktern password too (same default). Backups contain /etc/shadow, so keep ~/backups at chmod 700.
- If a box is compromised, remove /root/.ssh/bb_backup from its authorized_keys on blackbox (Red can't reach blackbox, but a stolen key could).
- Re-ship after any config change worth keeping. A revert wipes the box, but blackbox keeps the copies.
