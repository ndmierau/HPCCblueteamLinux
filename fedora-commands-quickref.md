FEDORA SERVER 38 (IGNITION) - COMMAND QUICK REFERENCE
Replace t with your team number. Words in CAPITALS are placeholders. Each command has one line saying what it does.

CONNECTING AND SSH TROUBLESHOOTING
- ssh plinktern@172.16.26.20
    Logs into the ignition box.
- ssh jmoney@172.16.26.20
    Tests the scored user's login from a second session.
- ssh-keygen -R 172.16.26.20
    Clears a stale host key warning after a revert.
- scp -r .\blue-team-kit plinktern@172.16.26.20:~/
    Copies the repo from your Windows laptop to the box.
- ip -br a
    Shows the box's interface names and IP addresses.
- systemctl status sshd
    Shows whether the SSH server is running.
- sudo systemctl restart sshd
    Restarts the SSH server.
- sudo sshd -t
    Tests the SSH config for syntax errors before restarting.
- sudo ss -tlnp | grep :22
    Confirms SSH is listening on port 22.
- Test-NetConnection 172.16.26.20 -Port 22
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
- sudo useradd -m jmoney && sudo passwd jmoney
    Creates the stand-in scoring user.

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
- getent group wheel
    Lists who has admin rights through that group.
- sudo grep -rn NOPASSWD /etc/sudoers /etc/sudoers.d
    Finds sudo rules that need no password.
- sudo usermod -L USERNAME
    Locks an unauthorized account (never use on jmoney).
- sudo usermod -U USERNAME
    Unlocks an account you locked by mistake.
- sudo userdel -r USERNAME
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
- sudo dnf makecache
    Refreshes package metadata and tests the repos.
- sudo sed -i -e 's|^metalink=|#metalink=|' -e 's|^#baseurl=http://download.example/pub/fedora/linux|baseurl=https://archives.fedoraproject.org/pub/archive/fedora/linux|' /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo
    Points the repos at the archive server because Fedora 38 is end of life.
- sudo dnf clean all
    Clears cached repo data after changing repo files.
- sudo dnf install -y PACKAGE
    Installs a package.
- sudo dnf install -y --setopt=strict=0 PKG1 PKG2
    Installs several packages and skips any that do not exist.
- sudo dnf remove -y PACKAGE
    Removes a package.
- dnf search NAME
    Searches for a package by name.
- dnf info PACKAGE
    Shows details and the version of a package.
- rpm -q PACKAGE
    Shows whether a package is installed.
- rpm -qf /PATH/TO/FILE
    Shows which package owns a file.
- rpm -qa --last | head -20
    Shows the most recently installed packages.
- sudo dnf history
    Lists past package transactions.
- command -v TOOL
    Shows whether a command is on the PATH.

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
- systemctl is-active firewalld fail2ban auditd
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
- sudo systemctl disable --now cockpit.socket
    Turns off the web admin console you do not need.
- journalctl -u SERVICE -n 50 --no-pager
    Shows a service's last 50 log lines.
- sudo systemctl mask SERVICE
    Blocks a malicious or unwanted service from being started at all.
- sudo service auditd restart
    Restarts auditd, since systemctl refuses to on Fedora.

FIREWALL (FIREWALLD)
- sudo firewall-cmd --state
    Shows whether the firewall is running.
- sudo firewall-cmd --get-active-zones
    Shows which zone is active and on which interface.
- sudo firewall-cmd --list-all
    Shows every allowed service, port, and rule in the zone.
- sudo firewall-cmd --permanent --add-service=ssh
    Allows SSH (saved across reloads).
- sudo firewall-cmd --permanent --add-port=80/tcp
    Allows the website port.
- sudo firewall-cmd --permanent --remove-port=PORT/tcp
    Closes a port you opened.
- sudo firewall-cmd --permanent --remove-service=cockpit
    Closes the Cockpit admin port.
- sudo firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="IP" drop'
    Blocks one IP.
- sudo firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="IP" drop'
    Removes the block on an IP.
- sudo firewall-cmd --reload
    Applies permanent changes.
- sudo firewall-cmd --panic-off
    Turns off panic mode if it was enabled.
- sudo systemctl stop firewalld
    Turns the firewall off (panic button).
- sudo systemctl start firewalld
    Turns the firewall back on.

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
- sudo journalctl -u fail2ban -n 50 --no-pager
    Shows recent bans and errors.
- sudo nano /etc/fail2ban/jail.local
    Edits the jail settings and the ignoreip whitelist.

SELINUX (LEAVE IT ENFORCING)
- getenforce
    Shows whether SELinux is enforcing.
- sestatus
    Shows SELinux status and policy details.
- sudo ausearch -m avc -ts recent
    Shows recent actions SELinux denied.
- ls -Z /PATH
    Shows the SELinux label on files.
- ps -eZ | grep PROCESS
    Shows the SELinux label on a running process.
- sudo restorecon -Rv /PATH
    Resets a path's labels to what policy expects.
- getsebool -a | grep httpd
    Lists web-related SELinux switches.
- sudo setsebool -P httpd_can_network_connect 1
    Lets a web proxy connect to a backend app (only if a denial shows it is needed).

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
- sudo ausearch -k web -i
    Shows changes to the web server config.
- sudo ausearch -f webui.db -i
    Shows who touched the Open WebUI database.
- sudo ausearch -m USER_LOGIN -i
    Shows login events.
- sudo ausearch -ts recent -i
    Shows the most recent audit events.
- sudo aureport -au
    Summarizes authentication events.
- sudo aureport --summary
    Gives an overview of audit activity.

FILE INTEGRITY (AIDE AND RPM)
- ls -la /var/lib/aide/
    Checks whether the AIDE baseline database exists.
- tail /root/aide-init.log
    Shows whether the baseline build finished.
- sudo aide --check
    Compares the disk to the baseline and lists changes.
- sudo aide --update
    Builds a new database that includes current changes.
- sudo rpm -Va --nomtime | grep -E '^..5'
    Lists packaged files whose contents were modified.
- sudo rpm -V PACKAGE
    Verifies the files of one package.

SCANNERS
- sudo lynis audit system
    Runs a full hardening audit with suggestions.
- sudo rkhunter --propupd
    Records the current file state as the rkhunter baseline.
- sudo rkhunter --check --sk
    Runs a rootkit scan without pausing for keypresses.
- sudo chkrootkit
    Runs a second rootkit scan.
- sudo clamscan -ri /tmp /home /var/www
    Scans common drop locations for malware.
- sudo freshclam
    Updates ClamAV signatures if clamscan reports no database.

LOGS (FEDORA USES THE JOURNAL; /var/log/secure ONLY EXISTS IF RSYSLOG IS INSTALLED)
- sudo journalctl -u sshd -f
    Watches the SSH service log live, including logins.
- sudo journalctl -u sshd --no-pager | grep "Failed password" | tail
    Shows recent failed SSH logins.
- sudo journalctl -u sshd --no-pager | grep "Accepted" | tail
    Shows recent successful SSH logins.
- sudo journalctl -u sshd --no-pager | grep "Failed password" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head
    Ranks IPs by failed SSH attempts.
- sudo journalctl _COMM=sudo -n 30 --no-pager
    Shows recent sudo activity.
- sudo journalctl -f
    Watches every system log line live.
- sudo journalctl -n 100 --no-pager
    Shows the latest 100 system log lines.
- sudo journalctl -p err -n 50 --no-pager
    Shows the latest error-level messages.
- sudo tail -f /var/log/nginx/access.log
    Watches proxy requests live if nginx fronts Open WebUI.
- sudo tail -f /var/log/httpd/access_log
    Watches web requests live if httpd is the proxy.
- sudo goaccess /var/log/nginx/access.log --log-format=COMBINED
    Shows a terminal dashboard of web traffic.
- inotifywait -m -r -e modify,create,delete /etc/ssh
    Prints a line whenever an SSH config file changes.

OPEN WEBUI (SCORED SERVICE)
- sudo ./roles/openwebui.sh
    Runs your Open WebUI checks and backs up its data folder.
- sudo ss -tulpn | grep -E ':(80|8080|3000|11434)\b'
    Shows what is listening on the likely Open WebUI and Ollama ports.
- systemctl list-units --type=service --all | grep -iE 'webui|ollama|nginx|httpd|caddy'
    Finds the Open WebUI, Ollama, and proxy service names.
- sudo journalctl -u SERVICE_NAME -n 50 --no-pager
    Shows the app's recent log lines.
- curl -I http://localhost/
    Checks that the site answers locally on port 80.
- curl -I http://localhost:8080/
    Checks whether the app answers directly on its own port.
- sudo nginx -t
    Tests the nginx config if nginx is the proxy.
- sudo grep -rn proxy_pass /etc/nginx
    Shows where nginx forwards traffic.
- sudo systemctl reload nginx
    Applies nginx changes without dropping connections.
- ollama list
    Lists the models Ollama has, which the scorer must be able to see.
- curl -s http://localhost:11434/api/tags
    Lists models through Ollama's API.
- sudo ss -tulpn | grep 11434
    Confirms Ollama is only on localhost.
- sudo find / -xdev -name webui.db 2>/dev/null
    Finds the chat history database.
- ls -l PATH_TO_webui.db
    Shows the database's owner and permissions.
- sudo chmod 600 PATH_TO_webui.db
    Restricts the database to its owner.
- sudo tar czf /root/backup/openwebui-manual.tgz $(dirname PATH_TO_webui.db)
    Backs up the Open WebUI data folder by hand.
- sudo systemctl restart SERVICE_NAME
    Restarts Open WebUI after restoring data.

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
- sudo systemctl stop firewalld
    Removes firewall blocking if you locked yourself or the scorer out.
- sudo firewall-cmd --panic-off
    Cancels panic mode if it was turned on.
- sudo restorecon -R /etc
    Fixes SELinux labels after restoring files from a backup.
- sudo systemctl restart sshd
    Brings SSH back if it stopped.
- Use the Console button in scoreboard.plinko.horse
    Gets you a login when SSH is unreachable.
- Revert in scoreboard.plinko.horse
    Rebuilds the box as a last resort and resets every password.
