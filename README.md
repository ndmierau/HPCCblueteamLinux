# blue-team-kit-linux
Scripts for the HPCC4 Linux boxes (Ubuntu 22.04, Fedora Server 38). No secrets, passwords, or IPs belong in this repo.

    git clone https://github.com/YOURNAME/blue-team-kit.git && cd blue-team-kit
    sudo bash install.sh && sudo bash sweep.sh

See checklist.md files for the order of operations.

Replace all variables t in ips to our team number. Idk what our team number is yet, hence the placeholder.

git install:

ubuntu:
sudo apt update
sudo apt install git

fedora:
sudo dnf install git

check with:
git --version

post ubuntu install, check also:
for p in ufw fail2ban auditd etckeeper debsums rkhunter chkrootkit lynis clamav aide \
         tcpdump tshark nmap suricata iftop nethogs goaccess net-tools lsof htop \
         psmisc tmux jq git curl inotify-tools; do
  dpkg -s "$p" >/dev/null 2>&1 && echo "OK       $p" || echo "MISSING  $p"
done

for c in ufw fail2ban-client auditctl etckeeper debsums rkhunter chkrootkit lynis \
         clamscan aide tcpdump tshark nmap suricata iftop nethogs goaccess ss lsof htop; do
  command -v "$c" >/dev/null && echo "OK       $c" || echo "MISSING  $c"
done


