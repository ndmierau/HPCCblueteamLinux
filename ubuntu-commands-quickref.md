UBUNTU 22.04 (GUIDANCE) - COMMAND QUICK REFERENCE
Replace t with your team number. Words in CAPITALS are placeholders. Each command has one line saying what it does.

CONNECTING AND SSH TROUBLESHOOTING
- ssh plinktern@172.16.26.10
    Logs into the guidance box.
- ssh jmoney@172.16.26.10
    Tests the scored user's login from a second session.
- ssh-keygen -R 172.16.26.10
    Clears a stale host key warning after a revert.
- scp -r .\blue-team-kit plinktern@172.16.26.10:~/
    Copies the repo from your Windows laptop to the box.
- ip -br a
    Shows the box's interface names and IP addresses.
- systemctl status ssh
    Shows whether the SSH server is running.
- sudo systemctl restart ssh
    Restarts the SSH server.
- sudo sshd -t
    Tests the SSH config for syntax errors before restarting.
- sudo ss -tlnp | grep :22
    Confirms SSH is listening on port 22.
- Test-NetConnection 172.16.26.10 -Port 22
    Run on your Windows laptop to test whether the port is reachable.
- tmux
    Starts a session that survives SSH disconnects.
- tmux attach
    Reattaches to your tmux session after reconnecting.

PRACTICE VM ONLY (VIRTUALBOX)
- ssh -p 2222 plinktern@DESKTOP_IP
    Connects to the practice VM through the VirtualBox port forward.
- scp -P 2222 -r .\blue-team-kit plinktern@DESKTOP_IP:~/
    Copies the repo to the practice VM (capital P for the port).
- ssh-keygen -R "[DESKTOP_IP]:2222"
    Clears a stale host key after restoring the VM snapshot.
- Test-NetConnection DESKTOP_IP -Port 2222
    Run on your Windows laptop to test the forwarded port.
- sudo adduser jmoney
    Creates the stand-in scoring user.
- sudo apt install -y apache2
    Installs Apache as a stand-in for PlinkCom.

ACCOUNTS AND PASSWORDS
- passwd
    Changes the password of the account you are logged in as.
- sudo passwd jmoney
    Changes the scored user's password (then update it in NEIGH and click Save).
- id jmoney
    Shows jmoney's user ID and groups.
- sudo chage -l jmoney
    Shows password aging settings for jmoney.
- awk -F: '$3==0{print $1}' /etc/passwd
    Lists accounts with UID 0, which should only be root.
- grep -vE '(nologin|false)$' /etc/passwd
    Lists accounts that have a login shell.
- getent group sudo
    Lists who has admin rights through that group.
- sudo grep -rn NOPASSWD /etc/sudoers /etc/sudoers.d
    Finds sudo rules that need no password.
- sudo usermod -L USERNAME
    Locks an unauthorized account (never use on jmoney).
- sudo usermod -U USERNAME
    Unlocks an account you locked by mistake.
- sudo deluser USERNAME
    Removes an unauthorized account.
- sudo pkill -KILL -u USERNAME
    Kills every session and process owned by that user.
- sudo chsh -s /usr/sbin/nologin USERNAME
    Stops an unauthorized account from getting a shell (never use on jmoney).

INTERNET AND PACKAGES
- ping -c 2 8.8.8.8
    Tests raw internet connectivity.
- curl -I https://github.com
    Tests DNS and HTTPS access to GitHub.
- sudo apt-get update
    Refreshes package lists and tests the mirrors.
- sudo apt-get install -y PACKAGE
    Installs a package.
- sudo apt-get remove -y PACKAGE
    Removes a package.
- sudo add-apt-repository universe
    Enables the universe repository if packages are not found.
- apt search NAME
    Searches for a package by name.
- dpkg -s PACKAGE
    Shows whether a package is installed.
- dpkg -l | grep NAME
    Finds installed packages matching NAME.
- command -v TOOL
    Shows whether a command is on the PATH.
- ls -lt /var/log/apt/ | head
    Shows the most recent package install activity.
- grep ' install ' /var/log/dpkg.log | tail -20
    Shows the last packages that were installed.

GIT AND THE REPO
- git clone https://github.com/ndmierau/HPCCblueteamLinux.git
    Downloads your repo onto the box.
- cd HPCCblueteamLinux
    Moves into the repo folder.
- git pull
    Downloads your latest script changes.
- git status
    Shows files changed locally.
- ls -la . roles
    Checks that the roles folder, dotfiles, and permissions are right.
- chmod +x *.sh roles/*.sh
    Makes every script executable.
- for f in *.sh roles/*.sh; do bash -n "$f" && echo "ok $f"; done
    Syntax-checks every script without running it.
- mkdir -p roles && mv openwebui.sh web.sh roles/
    Fixes the layout if the role scripts landed in the top folder.
- mv gitignore .gitignore && mv gitattributes .gitattributes
    Restores the leading dots on the dotfiles.

YOUR SCRIPTS
- sudo ./install.sh
    Installs the whole tool set.
- sudo ./sweep.sh
    Runs the read-only triage and saves a report to /root.
- sudo ALLOW_PORTS="80" ./harden.sh
    Applies firewall, fail2ban, auditd rules, etckeeper, and the AIDE baseline.
- sudo WHITELIST="IP1 IP2" ALLOW_PORTS="80" ./harden.sh
    Does the same while keeping listed IPs from ever being banned.
- sudo YES=1 ALLOW_PORTS="80" ./harden.sh
    Does the same and skips the blocked-port confirmation.
- sudo ./ship-backups.sh
    Copies /root/backup to blackbox.
- ./healthcheck.sh TEAM_NUMBER
    Tests SSH and both scored websites.
- ls /root/backup
    Lists the backups the scripts have made.
- ls /root/sweep-*.txt
    Lists saved sweep reports.

SERVICE CONTROL
- systemctl is-active fail2ban auditd apache2
    Prints whether each service is running.
- systemctl status SERVICE
    Shows a service's state and its recent log lines.
- sudo systemctl start SERVICE
    Starts a service.
- sudo systemctl stop SERVICE
    Stops a service.
- sudo systemctl restart SERVICE
    Restarts a service.
- sudo systemctl reload SERVICE
    Reloads a service's config without dropping connections.
- sudo systemctl enable --now SERVICE
    Starts a service now and at every boot.
- sudo systemctl disable --now SERVICE
    Stops a service and keeps it from starting at boot.
- sudo systemctl disable --now suricata
    Turns off the heavy IDS so it does not slow scored services.
- journalctl -u SERVICE -n 50 --no-pager
    Shows a service's last 50 log lines.
- sudo systemctl mask SERVICE
    Blocks a malicious or unwanted service from being started at all.

FIREWALL (UFW)
- sudo ufw status verbose
    Shows whether the firewall is on and every rule.
- sudo ufw status numbered
    Shows rules with numbers so you can delete one.
- sudo ufw allow 22/tcp
    Allows SSH.
- sudo ufw allow 80/tcp
    Allows the website.
- sudo ufw insert 1 deny from IP
    Blocks one IP, placed first so it beats the allow rules.
- sudo ufw delete deny from IP
    Removes a block on an IP.
- sudo ufw delete N
    Deletes the rule with that number.
- sudo ufw default deny incoming
    Blocks everything inbound that is not explicitly allowed.
- sudo ufw --force enable
    Turns the firewall on without a prompt.
- sudo ufw disable
    Turns the firewall off (panic button).
- sudo ufw reload
    Reloads the rules.
- sudo iptables -L DOCKER-USER -n
    Shows Docker firewall rules, which ufw does not control.

FAIL2BAN (IP BLOCKING)
- sudo fail2ban-client status
    Lists the active jails.
- sudo fail2ban-client status sshd
    Shows currently banned SSH IPs and failure counts.
- sudo fail2ban-client set sshd banip IP
    Bans an IP in the SSH jail.
- sudo fail2ban-client set sshd unbanip IP
    Unbans an IP.
- sudo fail2ban-client unban --all
    Clears every ban (use if the scorer gets blocked).
- sudo fail2ban-client reload
    Reloads the config after editing jail.local.
- sudo tail -f /var/log/fail2ban.log
    Watches bans and unbans live.
- sudo nano /etc/fail2ban/jail.local
    Edits the jail settings and the ignoreip whitelist.

AUDITD (DETAILED LOGS)
- sudo auditctl -l
    Lists the audit rules currently loaded.
- sudo auditctl -s
    Shows audit status.
- sudo augenrules --load
    Reloads the rules from /etc/audit/rules.d.
- sudo ausearch -k identity -i
    Shows changes to passwd, shadow, and group.
- sudo ausearch -k sudoers -i
    Shows changes to sudo rules.
- sudo ausearch -k ssh_keys -i
    Shows changes to root's SSH keys.
- sudo ausearch -k cron -i
    Shows changes to scheduled jobs.
- sudo ausearch -k webroot -i
    Shows changes to the website files.
- sudo ausearch -k web -i
    Shows changes to the Apache config.
- sudo ausearch -m USER_LOGIN -i
    Shows login events.
- sudo ausearch -ts recent -i
    Shows the most recent audit events.
- sudo aureport -au
    Summarizes authentication events.
- sudo aureport --summary
    Gives an overview of audit activity.

FILE INTEGRITY (AIDE AND DEBSUMS)
- ls -la /var/lib/aide/
    Checks whether the AIDE baseline database exists.
- tail /root/aide-init.log
    Shows whether the baseline build finished.
- sudo aide --config /etc/aide/aide.conf --check
    Compares the disk to the baseline and lists changes.
- sudo aide --config /etc/aide/aide.conf --update
    Builds a new database that includes current changes.
- sudo debsums -c
    Lists installed package files that were modified.
- sudo debsums -s
    Does the same but prints only problems.

SCANNERS
- sudo lynis audit system
    Runs a full hardening audit with suggestions.
- sudo rkhunter --propupd
    Records the current file state as the rkhunter baseline.
- sudo rkhunter --check --sk
    Runs a rootkit scan without pausing for keypresses.
- sudo chkrootkit
    Runs a second rootkit scan.
- sudo clamscan -ri /tmp /var/www /home
    Scans common drop locations for malware.
- sudo systemctl stop clamav-freshclam && sudo freshclam && sudo systemctl start clamav-freshclam
    Updates ClamAV signatures if clamscan reports no database.

LOGS
- sudo tail -f /var/log/auth.log
    Watches logins and sudo use live.
- sudo journalctl -u ssh -f
    Watches the SSH service log live.
- sudo journalctl -n 100 --no-pager
    Shows the latest 100 system log lines.
- sudo grep "Failed password" /var/log/auth.log | tail
    Shows recent failed SSH logins.
- sudo grep "Accepted" /var/log/auth.log | tail
    Shows recent successful SSH logins.
- sudo grep "Failed password" /var/log/auth.log | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head
    Ranks IPs by failed SSH attempts.
- sudo grep sudo /var/log/auth.log | tail
    Shows recent sudo activity.
- sudo tail -f /var/log/apache2/access.log
    Watches website requests live.
- sudo tail -f /var/log/apache2/error.log
    Watches Apache errors live.
- sudo goaccess /var/log/apache2/access.log --log-format=COMBINED
    Shows a terminal dashboard of website traffic.
- awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head
    Ranks IPs by number of web requests.
- inotifywait -m -r -e modify,create,delete /var/www
    Prints a line whenever a website file changes.

APACHE (PLINKCOM)
- sudo ./roles/web.sh
    Runs your Apache checks and backs up the config and webroot.
- sudo apache2ctl configtest
    Tests the Apache config for errors.
- sudo apache2ctl -S
    Shows virtual hosts and which files define them.
- sudo apache2ctl -M
    Lists loaded Apache modules.
- sudo a2dismod MODULE
    Disables an unneeded or suspicious module.
- sudo a2enmod MODULE
    Enables a module.
- ls -la /etc/apache2/sites-enabled
    Lists enabled site configs.
- sudo systemctl reload apache2
    Applies config changes without dropping connections.
- sudo systemctl restart apache2
    Restarts Apache.
- curl -I http://localhost/
    Checks that the website answers locally.
- sudo find /var/www -type f -mtime -1
    Lists website files changed within the last day.
- sudo find /var/www -perm -o+w
    Lists world-writable website files.
- sudo find /var/www -name .htaccess
    Lists .htaccess files that can change site behavior.
- sudo grep -rEl "eval\(base64_decode|shell_exec\(\$_|passthru\(" /var/www
    Searches for common webshell patterns.
- sudo tar xzf /root/backup/www-TIME.tgz -C /
    Restores the website files from your backup.
- sudo tar xzf /root/backup/etc-TIME.tgz -C / etc/apache2
    Restores only the Apache config from your backup.

WHO IS ON THE BOX
- who
    Shows who is logged in right now.
- w
    Shows who is logged in and what they are running.
- last -n 20
    Shows recent successful logins.
- sudo lastb -n 20
    Shows recent failed logins.
- sudo pkill -KILL -t pts/N
    Kicks the login session on that terminal (find N with the w command).

PROCESSES AND RESOURCES
- ps aux
    Lists every running process.
- ps aux --sort=-%cpu | head
    Shows the processes using the most CPU.
- ps aux --sort=-%mem | head
    Shows the processes using the most memory.
- pstree -p
    Shows which process started which.
- htop
    Gives a live, sortable view of processes and load.
- sudo ls -l /proc/PID/exe
    Shows the real program file behind a suspicious process.
- sudo kill -9 PID
    Force-stops a process by its ID.
- sudo pkill -f NAME
    Force-stops processes whose command line matches NAME.
- uptime
    Shows load averages and how long the box has been up.
- free -h
    Shows memory and swap use.
- df -h
    Shows disk space use.
- sudo dmesg | tail -30
    Shows recent kernel messages such as crashes or out-of-memory kills.

NETWORK TRIAGE
- sudo ss -tulpn
    Lists listening ports and the process that owns each.
- sudo ss -tnp state established
    Lists active connections and who owns them.
- sudo lsof -i
    Lists processes with open network connections.
- ip -br a
    Shows interface names and IP addresses.
- ip route
    Shows the default gateway and routes.
- sudo iftop
    Shows live bandwidth by remote address.
- sudo nethogs
    Shows live bandwidth by process.
- nmap -sT -p- 172.16.t.X
    Scans a box for open ports the way an attacker would (run from another box).
- nmap -sV localhost
    Identifies services and versions listening on this box.

PACKET CAPTURE
- sudo tcpdump -i any -nn port 80
    Prints live web traffic as it arrives.
- sudo tcpdump -i any -nn port 22
    Prints live SSH traffic.
- sudo tcpdump -i any -w /tmp/cap.pcap port 22
    Saves SSH traffic to a capture file.
- sudo tcpdump -nn -r /tmp/cap.pcap | head
    Reads back the first lines of a saved capture.
- sudo tshark -i any -f "port 80"
    Shows decoded live web traffic.
- tshark -r /tmp/cap.pcap -q -z conv,ip
    Summarizes which IP pairs talked the most in a capture.

PERSISTENCE HUNTING
- sudo cat /root/.ssh/authorized_keys
    Shows keys that can log in as root.
- sudo cat /home/*/.ssh/authorized_keys
    Shows keys that can log in as normal users.
- sudo sshd -T | grep -Ei 'permitrootlogin|passwordauthentication|authorizedkeysfile|allowusers'
    Shows the SSH settings actually in effect.
- sudo crontab -l
    Shows root's scheduled jobs.
- sudo crontab -u USERNAME -l
    Shows another user's scheduled jobs.
- ls -la /etc/cron.d /etc/cron.daily /etc/cron.hourly
    Lists system-wide scheduled job files.
- systemctl list-timers --all
    Lists systemd timers, which can hide scheduled backdoors.
- systemctl list-unit-files --state=enabled
    Lists services that start at boot.
- systemctl list-units --type=service --state=running
    Lists services running right now.
- cat /etc/ld.so.preload
    Shows libraries forced into every program (should not exist).
- ls -la /etc/profile.d
    Lists scripts that run at every login.
- grep -nE "curl|wget|nc |/dev/tcp|bash -i" /etc/profile /root/.bashrc /home/*/.bashrc
    Finds reverse-shell style lines in shell startup files.
- sudo find / -xdev -perm -4000 -type f
    Lists SUID programs, which can be abused for root access.
- sudo find /tmp /var/tmp /dev/shm -type f
    Lists files dropped in common attacker staging folders.
- sudo find /etc -mtime -1 -type f
    Lists config files changed within the last day.
- sudo find / -xdev -type f -mtime -1 -not -path '/proc/*' 2>/dev/null | head -50
    Lists recently changed files anywhere on the disk.

BACKUPS AND RESTORING
- sudo tar czf /root/backup/manual-$(date +%H%M%S).tgz PATH
    Makes a quick manual backup of any folder.
- scp plinktern@172.16.t.5:backups/HOSTNAME/FILE /root/
    Pulls a backup back from blackbox.
- sudo tar tzf /root/backup/FILE.tgz | head
    Lists what is inside a backup before restoring it.
- sudo etckeeper vcs log
    Shows every saved version of /etc.
- sudo etckeeper vcs diff
    Shows /etc changes since the last save.
- sudo etckeeper vcs checkout -- ssh/sshd_config
    Restores a single /etc file (path is relative to /etc) to its saved version.
- sudo etckeeper commit "message"
    Saves the current /etc as a new version.

EMERGENCY
- sudo fail2ban-client unban --all
    Frees any IP that was banned, including the scorer.
- sudo ufw disable
    Removes firewall blocking if you locked yourself or the scorer out.
- sudo systemctl restart ssh
    Brings SSH back if it stopped.
- sudo systemctl restart apache2
    Brings the website back if it stopped.
- Use the Console button in scoreboard.plinko.horse
    Gets you a login when SSH is unreachable.
- Revert in scoreboard.plinko.horse
    Rebuilds the box as a last resort and resets every password.
