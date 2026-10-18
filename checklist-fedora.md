WARNING THIS DOCUMENT IS AI GENERATED, VERIFY ALL COMMANDS AND INFORMATION BEFORE USE AND UPDATE THE DOCUMENT AS YOU GO

FEDORA SERVER 38 (IGNITION, 172.16.t.20) - COMMANDS AND SERVICES REFERENCE
Replace t with team number.
Scored on this box: SSH for jmoney, and Open WebUI at http://172.16.t.20 (login, model list, previous chats).

CONNECTING
- Connect NetBird on your laptop (Management URL https://vpn.plinko.horse)
- SSH into the box:
    ssh plinktern@172.16.t.20
- If you get a changed host key warning (this happens after a revert):
    ssh-keygen -R 172.16.t.20
- Copy the repo from your Windows laptop (PowerShell, in the folder that contains the repo):
    scp -r .\blue-team-kit plinktern@172.16.t.20:~/
- Fallback if SSH is down: use the Console button for this box in scoreboard.plinko.horse (Boxes page)

CREDENTIALS AND ACCOUNTS
- Change the plinktern password (default is in the packet and Red Team has it):
    passwd
- Change the jmoney password, then update it in NEIGH:
    sudo passwd jmoney
- In scoreboard.plinko.horse go to Users, find ignition, enter the new jmoney password, click Save
- Do NOT disable or delete jmoney, and do not change his shell
- Change the Open WebUI passwords inside the app for plinktern@plinko.horse and jmoney@plinko.horse
- Update the Open WebUI password for jmoney in NEIGH to match
- A revert resets every password to the packet default

CHECK THE BOX CAN REACH THE INTERNET
- Test web access:
    curl -I https://github.com
- Test package mirrors:
    sudo dnf makecache

FEDORA 38 REPOSITORY FIX (FEDORA 38 IS END OF LIFE)
- install.sh does this automatically when makecache fails, but here is the manual version
- Point the repos at the archive server:
    sudo sed -i -e 's|^metalink=|#metalink=|' -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://archives.fedoraproject.org/pub/archive/fedora/linux|' /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo
    sudo dnf clean all
    sudo dnf makecache
- If the cisco openh264 repo errors, ignore it or run commands with:
    --setopt=skip_if_unavailable=True
- Look up a package name that is not found:
    dnf search PACKAGE_NAME
    dnf info PACKAGE_NAME

GET THE REPO ONTO THE BOX
- Option A, clone from GitHub (only works without a login if the repo is public; never put a personal token on a competition box):
    sudo dnf install -y git
    git clone https://github.com/ndmierau/HPCCblueteamLinux.git
    cd HPCCblueteamLinux
- Option B, push from your laptop with scp (see CONNECTING), then:
    cd ~/blue-team-kit
- Check the layout (roles folder, dotfiles, executable bits):
    ls -la . roles
- If the files are not in a roles folder or the dotfiles lost their dots:
    mkdir -p roles
    mv openwebui.sh web.sh roles/
    mv gitignore .gitignore
    mv gitattributes .gitattributes
- Make every script executable:
    chmod +x *.sh roles/*.sh
- Syntax check every script:
    for f in *.sh roles/*.sh; do bash -n "$f" && echo "ok $f"; done

SERVICES AND SOFTWARE INSTALLED BY install.sh
- Run the installer:
    sudo ./install.sh
- Firewall: firewalld (replaces ufw on Fedora, do not install ufw)
- IP blocking: fail2ban and fail2ban-firewalld
- Detailed logging: audit (provides auditd)
- /etc change tracking: etckeeper
- Malware scanner: clamav and clamav-update
- Rootkit scanners: rkhunter, chkrootkit
- Security auditing: lynis
- File integrity: aide (Fedora has no debsums, use rpm -Va instead)
- Packet capture: tcpdump, wireshark-cli (provides tshark)
- Network scanning: nmap
- Intrusion detection: suricata
- Bandwidth views: iftop, nethogs
- Web log analysis: goaccess
- Triage utilities: net-tools, lsof, htop, psmisc, tmux, jq, git, inotify-tools
- The installer prints a NOT INSTALLED list for any package it could not find

VERIFY THE INSTALL
- Check every package:
    for p in firewalld fail2ban fail2ban-firewalld audit etckeeper rkhunter chkrootkit lynis \
             clamav clamav-update aide tcpdump wireshark-cli nmap suricata iftop nethogs \
             goaccess net-tools lsof htop psmisc tmux jq git inotify-tools; do
      rpm -q "$p" >/dev/null 2>&1 && echo "OK       $p" || echo "MISSING  $p"
    done
- Install anything missing:
    sudo dnf install -y PACKAGE_NAME
- Check every command is on the PATH:
    for c in firewall-cmd fail2ban-client auditctl etckeeper rkhunter chkrootkit lynis \
             clamscan aide tcpdump tshark nmap suricata iftop nethogs goaccess ss lsof htop; do
      command -v "$c" >/dev/null && echo "OK       $c" || echo "MISSING  $c"
    done
- Check service state:
    systemctl is-active firewalld fail2ban auditd suricata
    sudo firewall-cmd --state
    sudo ss -tlnp
- Before hardening, fail2ban may be inactive until harden.sh runs
- Quick tool checks:
    lynis --version
    nmap --version | head -1
    tshark --version | head -1
    sudo auditctl -s | head -3

SURICATA (OPTIONAL, HEAVY ON CPU AND RAM)
- See why it failed:
    sudo journalctl -u suricata -n 25 --no-pager
    ip -br a
- Point it at your real interface name (example ens18), update rules, test config, restart:
    sudo sed -i 's/interface: eth0/interface: ens18/' /etc/suricata/suricata.yaml
    sudo suricata-update
    sudo suricata -T -c /etc/suricata/suricata.yaml
    sudo systemctl restart suricata
    systemctl is-active suricata
- Or leave it off so it does not slow scored services:
    sudo systemctl disable --now suricata

SELINUX (LEAVE IT ENFORCING)
- Check the mode:
    getenforce
- Never disable SELinux as a fix, find the denial instead:
    sudo ausearch -m avc -ts recent
- Fix a wrong file label on a path:
    sudo restorecon -Rv /path/to/folder
- If a reverse proxy cannot reach Open WebUI because of SELinux:
    sudo setsebool -P httpd_can_network_connect 1

LOOK AROUND BEFORE CHANGING ANYTHING
- Run the read-only sweep (output is also saved to /root/sweep-TIME.txt):
    sudo ./sweep.sh
- Run the Open WebUI checks (what listens on 80 and 8080, reverse proxy, Open WebUI process and service, Ollama, webui.db backup, local health check):
    sudo ./roles/openwebui.sh
- See listening ports and owning processes:
    sudo ss -tulpn
- Find the Open WebUI service name, then view its logs:
    systemctl list-units --type=service --all | grep -iE 'webui|ollama|nginx|httpd|caddy'
    sudo journalctl -u SERVICE_NAME -n 50 --no-pager
- Review what the sweep reports: UID 0 accounts, login shells, sudoers NOPASSWD entries, SSH settings, authorized_keys, cron jobs, timers, enabled services, startup-file persistence, SUID files, recent and failed logins, modified packaged files
- Leave the log collector services alone, they feed OpenObserve on blackbox

PROTECT OPEN WEBUI DATA (CHAT HISTORY IS SCORED)
- roles/openwebui.sh backs up the folder containing webui.db to /root/backup
- Find the database yourself:
    sudo find / -xdev -name webui.db 2>/dev/null
- Back it up by hand:
    sudo tar czf /root/backup/openwebui-data-manual.tgz $(dirname PATH_TO_webui.db)
- Lock down the file to the service user (check the owner first):
    ls -l PATH_TO_webui.db
    sudo chmod 600 PATH_TO_webui.db
- Watch it for tampering:
    sudo ausearch -f webui.db -i
- Keep Ollama on localhost only (port 11434 should not show 0.0.0.0):
    sudo ss -tulpn | grep 11434
- Confirm the app answers locally:
    curl -I http://localhost/

HARDEN THE BOX
- Keep your current SSH session open while you do this
- Run the hardening script (SSH is always allowed, ALLOW_PORTS adds more):
    sudo ALLOW_PORTS="80" ./harden.sh
- Optional settings:
    WHITELIST="IP1 IP2"   addresses fail2ban must never ban
    YES=1                 skip the "port will be blocked" prompt
- What harden.sh does on Fedora:
  - Backs up /etc into /root/backup
  - Starts etckeeper tracking of /etc
  - Warns about listening ports that the firewall would block
  - Enables firewalld, allows ssh and your ports, removes the cockpit service from the firewall
  - Writes a lenient fail2ban jail for sshd using the systemd journal and starts fail2ban
  - Adds auditd watch rules for accounts, sudoers, SSH, PAM, cron, systemd, web config
  - Builds the AIDE integrity baseline in the background
- It refuses to run on blackbox or Mint unless FORCE=1 is set

VERIFY HARDENING DID NOT BREAK SCORING
- From a second session, log in as jmoney:
    ssh jmoney@172.16.t.20
- Load http://172.16.t.20 in a browser and log in as jmoney@plinko.horse
- Confirm he can see the models and his previous chats
- Confirm services and rules on the box:
    sudo firewall-cmd --list-all
    sudo fail2ban-client status
    sudo fail2ban-client status sshd
    systemctl is-active firewalld fail2ban auditd
    sudo ausearch -k identity -i | tail
    ls /root/backup
- Check the AIDE baseline finished:
    ls -la /var/lib/aide/
    tail /root/aide-init.log
- From any machine, check scored services:
    ./healthcheck.sh TEAM_NUMBER
- Also check the Details page at scoreboard.plinko.horse

RECOVERY AND PANIC COMMANDS
- Remove every fail2ban ban:
    sudo fail2ban-client unban --all
- Turn off firewall panic mode, or stop the firewall entirely:
    sudo firewall-cmd --panic-off
    sudo systemctl stop firewalld
- Start it again:
    sudo systemctl start firewalld
- Auditd cannot be restarted with systemctl on Fedora, use:
    sudo service auditd restart
    sudo augenrules --load
- See what changed in /etc:
    sudo etckeeper vcs log
    sudo etckeeper vcs diff
- Restore /etc from the backup tarball (check the file name first), then fix SELinux labels:
    ls /root/backup
    sudo tar xzf /root/backup/etc-TIME.tgz -C /
    sudo restorecon -R /etc
- See recent package changes:
    sudo dnf history
- Locked out of SSH: use the Console button in NEIGH, or Restart the box
- Revert in NEIGH only as a last resort (resets passwords, costs uptime after the free reverts)

BACKUPS TO BLACKBOX
- Change the default plinktern password on blackbox
- Push backups to blackbox (first run asks for the blackbox plinktern password once):
    sudo ./ship-backups.sh
- Re-run after any change worth keeping, especially the Open WebUI data
- If the box is compromised, delete that box's public key line from ~/.ssh/authorized_keys on blackbox

SCANNING AND AUDITING TOOLS
- Full security audit with a prioritized to-do list:
    sudo lynis audit system
- Rootkit scans:
    sudo rkhunter --propupd
    sudo rkhunter --check --sk
    sudo chkrootkit
- Malware scan of common drop locations:
    sudo clamscan -ri /tmp /home /var/www
- If clamscan says no database, update signatures:
    sudo freshclam
- File integrity check against the AIDE baseline:
    sudo aide --check
- Find tampered system files (Fedora replacement for debsums):
    sudo rpm -Va --nomtime | grep -E '^..5'
- See recently installed packages:
    sudo rpm -qa --last | head -20
- Scan your own box the way an attacker would (run from another box):
    nmap -sT -p- 172.16.t.20

LOG AND ACTIVITY WATCHING
- Fedora has no /var/log/auth.log, use these:
    sudo tail -f /var/log/secure
    sudo journalctl -u sshd -f
    sudo journalctl -f
- Reverse proxy logs if one is in front of Open WebUI:
    sudo tail -f /var/log/nginx/access.log
    sudo tail -f /var/log/httpd/access_log
- Web traffic summary (adjust the path and format to the proxy in use):
    sudo goaccess /var/log/nginx/access.log --log-format=COMBINED
- Audit searches (keys: identity sudoers ssh ssh_keys pam cron systemd web webroot):
    sudo ausearch -k identity -i
    sudo ausearch -k ssh_keys -i
- Who is logged in and who tried:
    who
    w
    last
    sudo lastb
- Watch a folder for changes live:
    inotifywait -m -r -e modify,create,delete /etc/ssh
- Keep sessions alive if SSH drops:
    tmux
    tmux attach

PROCESS AND NETWORK TRIAGE
- Processes:
    ps aux
    pstree -p
    htop
- Connections and listeners:
    sudo ss -tulpn
    sudo ss -tnp state established
    sudo lsof -i
- Bandwidth hogs during a flood:
    sudo iftop
    sudo nethogs
- Packet capture on demand:
    sudo tcpdump -i any -w /tmp/cap.pcap port 22
    sudo tcpdump -i any -nn port 80
    sudo tshark -i any -f "port 80"

PERSISTENCE HUNTING (RED TEAM MAY HAVE LEFT ITEMS BEFORE THE START)
- Accounts with UID 0:
    awk -F: '$3==0{print $1}' /etc/passwd
- Accounts with login shells:
    grep -vE '(nologin|false)$' /etc/passwd
- Admin group members (Fedora uses wheel):
    getent group wheel
- Sudo rules:
    sudo grep -rn NOPASSWD /etc/sudoers /etc/sudoers.d
- SSH keys:
    sudo cat /root/.ssh/authorized_keys
    sudo cat /home/*/.ssh/authorized_keys
- Effective SSH settings:
    sudo sshd -T | grep -Ei 'permitrootlogin|passwordauthentication|authorizedkeysfile|allowusers'
- Scheduled tasks:
    sudo crontab -l
    ls -la /etc/cron.d /etc/cron.daily /etc/cron.hourly
    systemctl list-timers --all
- Enabled services:
    systemctl list-unit-files --state=enabled
- Shell startup tampering:
    cat /etc/ld.so.preload
    ls -la /etc/profile.d
    grep -nE "curl|wget|nc |/dev/tcp|bash -i" /etc/profile /etc/bashrc /root/.bashrc /home/*/.bashrc
- Odd SUID files:
    sudo find / -xdev -perm -4000 -type f
- Recently changed system files:
    sudo find /etc -mtime -1 -type f

KEEPING THE REPO UP TO DATE
- On your laptop after editing scripts:
    git add -A
    git commit -m "describe the change"
    git push
- On the box, pull updates:
    cd ~/HPCCblueteamLinux
    git pull
- Re-apply executable bits if needed:
    chmod +x *.sh roles/*.sh

RULES TO REMEMBER
- Do not replace scored services (Open WebUI and its proxy stay as they are)
- Do not copy company data to your personal device or external sites (blackbox is fine)
- Do not use AI tools to write inject answers
- Never ban IP ranges: the scoring engine uses many addresses that Red Team may share
- Never hit the Red Team back, only remove what they leave on your boxes
- Do not disable SELinux
