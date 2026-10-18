UBUNTU 22.04 (GUIDANCE, 172.16.t.10) - COMMANDS AND SERVICES REFERENCE
Replace t with your team number.

CONNECTING
- Connect NetBird on your laptop (Management URL https://vpn.plinko.horse)
- SSH into the competition box:
    ssh plinktern@172.16.t.10
- If you get a changed host key warning (this happens after a revert):
    ssh-keygen -R 172.16.t.10
#Next step should be able to be skipped if you are just ripping the repo from github on the box itself.
Copy the repo from your Windows laptop (PowerShell, in the folder that contains the repo):
    scp -r .\blue-team-kit plinktern@172.16.t.10:~/

CREDENTIALS AND ACCOUNTS
- Change the plinktern password (default is in the packet and Red Team has it || default: H00ves0nTheM00n):
    passwd plinktern
- Change the jmoney password, then update it in NEIGH:
    sudo passwd jmoney
- In scoreboard.plinko.horse go to Users, find the box, enter the new jmoney password, click Save
- Do NOT disable or delete jmoney, and do not change his shell (for scoring purposes)
- Change application passwords inside PlinkCom (plinktern and jmoney) and update NEIGH to match
*Coordinate with the Windows teammate before changing database passwords (PlinkCom uses MariaDB on manifest)
*A revert resets every password to the packet default

CHECK THE BOX CAN REACH THE INTERNET
- Test web access:
    curl -I https://github.com
- Test package mirrors:
    sudo apt-get update

GET THE REPO ONTO THE BOX
- Plan A, clone from GitHub:
    sudo apt install -y git
  
    git clone https://github.com/ndmierau/HPCCblueteamLinux.git
  
    cd HPCCblueteamLinux
- Plan B, push from laptop with scp (see CONNECTING), then:

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
- Firewall: ufw
- IP blocking: fail2ban
- Detailed logging: auditd
- /etc change tracking: etckeeper
- Package tamper checks: debsums
- Malware scanner: clamav
- Rootkit scanners: rkhunter, chkrootkit
- Security auditing: lynis
- File integrity: aide
- Packet capture: tcpdump, tshark
- Network scanning: nmap
- Intrusion detection: suricata
- Bandwidth views: iftop, nethogs
- Web log analysis: goaccess
- Triage utilities: net-tools, lsof, htop, psmisc, tmux, jq, git, curl, inotify-tools
- Installer uses --no-install-recommends so no mail server (port 25) gets pulled in

VERIFY THE INSTALL
- Check every package:
    for p in ufw fail2ban auditd etckeeper debsums rkhunter chkrootkit lynis clamav aide \
             tcpdump tshark nmap suricata iftop nethogs goaccess net-tools lsof htop \
             psmisc tmux jq git curl inotify-tools; do
      dpkg -s "$p" >/dev/null 2>&1 && echo "OK       $p" || echo "MISSING  $p"
    done
- Install anything missing:
    sudo apt-get install -y PACKAGE_NAME
- If a package is not found, enable universe:
    sudo add-apt-repository universe
    sudo apt update
- Check every command is on the PATH:
    for c in ufw fail2ban-client auditctl etckeeper debsums rkhunter chkrootkit lynis \
             clamscan aide tcpdump tshark nmap suricata iftop nethogs goaccess ss lsof htop; do
      command -v "$c" >/dev/null && echo "OK       $c" || echo "MISSING  $c"
    done
- Check service state:
    systemctl is-active fail2ban auditd suricata
    sudo ufw status
    sudo ss -tlnp
- Before hardening, ufw inactive is normal and fail2ban may be inactive until harden.sh runs
- Port 25 listening would mean a mail server got installed (unexpected)
- Quick tool checks:
    lynis --version
    nmap --version | head -1
    tshark --version | head -1
    sudo auditctl -s | head -3

SURICATA (OPTIONAL, HEAVY ON CPU AND RAM)
- See why it failed:
    sudo journalctl -u suricata -n 25 --no-pager
    ip -br a
- Point it at your real interface name (example enp0s3), update rules, test config, restart:
    sudo sed -i 's/interface: eth0/interface: enp0s3/' /etc/suricata/suricata.yaml
    sudo suricata-update
    sudo suricata -T -c /etc/suricata/suricata.yaml
    sudo systemctl restart suricata
    systemctl is-active suricata
- Or leave it off so it does not slow scored services:
    sudo systemctl disable --now suricata

LOOK AROUND BEFORE CHANGING ANYTHING
- Run the read-only sweep (output is also saved to /root/sweep-TIME.txt):
    sudo ./sweep.sh
- Run the Apache checks (config test, vhosts, modules, recent web file changes, webshell patterns, .htaccess files, top client IPs):
    sudo ./roles/web.sh
- See listening ports and owning processes:
    sudo ss -tulpn
- Review what the sweep reports: UID 0 accounts, login shells, sudoers NOPASSWD entries, SSH settings, authorized_keys, cron jobs, timers, enabled services, startup-file persistence, SUID files, recent and failed logins, modified packaged files
- Leave the log collector services alone, they feed OpenObserve on blackbox

HARDEN THE BOX
- Keep your current SSH session open while you do this
- Run the hardening script (SSH on 22 is always allowed, ALLOW_PORTS adds more):
    sudo ALLOW_PORTS="80" ./harden.sh
- Optional settings:
    WHITELIST="IP1 IP2"   addresses fail2ban must never ban
    YES=1                 skip the "port will be blocked" prompt
What harden.sh does:
  - Backs up /etc and /var/www into /root/backup
  - Starts etckeeper tracking of /etc
  - Warns about listening ports that the firewall would block
  - Enables ufw with default deny incoming, allows 22 and your ports
  - Writes a lenient fail2ban jail (sshd and apache-auth) and starts fail2ban
  - Adds auditd watch rules for accounts, sudoers, SSH, PAM, cron, systemd, Apache, web root
  - Builds the AIDE integrity baseline in the background
*It refuses to run on blackbox or Mint unless FORCE=1 is set

VERIFY HARDENING DID NOT BREAK SCORING
- From a second session, log in as jmoney:
    ssh jmoney@172.16.t.10
- Load http://172.16.t.10 in a browser
- Confirm services and rules on the box:
    sudo ufw status verbose
    sudo fail2ban-client status
    sudo fail2ban-client status sshd
    systemctl is-active fail2ban auditd
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
- Turn the firewall off, and back on:
    sudo ufw disable
    sudo ufw --force enable
- See what changed in /etc:
    sudo etckeeper vcs log
    sudo etckeeper vcs diff
- Restore /etc from the backup tarball (check the file name first):
    ls /root/backup
    sudo tar xzf /root/backup/etc-TIME.tgz -C /
- Locked out of SSH: use the Console button in NEIGH, or Restart the box
*Revert in NEIGH only as a last resort (resets passwords, costs uptime after the free reverts)

BACKUPS TO BLACKBOX
- Change the default plinktern password on blackbox
- Push backups to blackbox (first run asks for the blackbox plinktern password once):
    sudo ./ship-backups.sh
- Re-run after any change worth keeping
- If the box is compromised, delete that box's public key line from ~/.ssh/authorized_keys on blackbox (though it is out of red teams scope)

SCANNING AND AUDITING TOOLS
- Full security audit with a prioritized to-do list:
    sudo lynis audit system
- Rootkit scans:
    sudo rkhunter --propupd
    sudo rkhunter --check --sk
    sudo chkrootkit
- Malware scan of common drop locations:
    sudo clamscan -ri /tmp /var/www /home
- If clamscan says no database, update signatures:
    sudo systemctl stop clamav-freshclam
    sudo freshclam
    sudo systemctl start clamav-freshclam
- File integrity check against the AIDE baseline:
    sudo aide --config /etc/aide/aide.conf --check
- Find tampered system files:
    sudo debsums -c
*Scan our boxes the way an attacker would (run from another box):
    nmap -sT -p- 172.16.t.10

LOG AND ACTIVITY WATCHING
- Authentication log:
    sudo tail -f /var/log/auth.log
- SSH service log:
    sudo journalctl -u ssh -f
- Apache logs:
    sudo tail -f /var/log/apache2/access.log
    sudo tail -f /var/log/apache2/error.log
- Apache traffic summary:
    sudo goaccess /var/log/apache2/access.log --log-format=COMBINED
- Audit searches (keys: identity sudoers ssh ssh_keys pam cron systemd web webroot):
    sudo ausearch -k identity -i
    sudo ausearch -k ssh_keys -i
    sudo ausearch -k webroot -i
- Who is logged in and who tried:
    who
    w
    last
    sudo lastb
-if noticed an ip then use Fail2ban to block it
Bash

sudo systemctl enable --now fail2ban

- Or block it with ufw (replace port 22 if with SSH port if changed)
sudo ufw deny from <attacker_ip> to any port 22

- Watch a folder for changes live:
    inotifywait -m -r -e modify,create,delete /var/www
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
- Admin group members:
    getent group sudo adm
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
    grep -nE "curl|wget|nc |/dev/tcp|bash -i" /etc/profile /etc/bash.bashrc /root/.bashrc /home/*/.bashrc
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
- Do not replace scored services (Apache stays Apache)
- Do not copy company data to your personal device or external sites (blackbox is fine)
- Do not use AI tools to write inject answers
- Never ban IP ranges: the scoring engine uses many addresses that Red Team may share
- Never hit the Red Team back, only remove what they leave on your boxes
