#!/usr/bin/env bash
# Pushes /root/backup/* to blackbox (172.16.t.5) over SSH. blackbox is in the competition
# environment, in scope for us, and out of scope for Red Team.
# Usage: sudo ./ship-backups.sh         (BB_USER defaults to plinktern; BB_HOST auto-derived)
set -uo pipefail
[[ $EUID -eq 0 ]] || { echo "Run as root"; exit 1; }
BB_USER="${BB_USER:-plinktern}"
T=26
BB_HOST="${BB_HOST:-172.16.$T.5}"
KEY=/root/.ssh/bb_backup
DEST="backups/$(hostname -s)"
SSHO=(-i "$KEY" -o StrictHostKeyChecking=accept-new -o BatchMode=yes)

[[ -d /root/backup ]] || { echo "Nothing in /root/backup yet (run harden.sh / role scripts first)"; exit 1; }
echo "Target: $BB_USER@$BB_HOST:~/$DEST"

if [[ ! -f $KEY ]]; then
  echo "Creating a dedicated backup key (used for nothing else)..."
  mkdir -p /root/.ssh && chmod 700 /root/.ssh
  ssh-keygen -q -t ed25519 -N "" -f "$KEY"
  echo "Installing it on blackbox (you'll be asked for $BB_USER's password once)..."
  ssh-copy-id -i "$KEY.pub" -o StrictHostKeyChecking=accept-new "$BB_USER@$BB_HOST" || { rm -f "$KEY" "$KEY.pub"; exit 1; }
fi

ssh "${SSHO[@]}" "$BB_USER@$BB_HOST" "umask 077; mkdir -p ~/$DEST && chmod 700 ~/backups ~/$DEST" || { echo "SSH to blackbox failed"; exit 1; }
scp "${SSHO[@]}" -p -r /root/backup/. "$BB_USER@$BB_HOST:$DEST/" && echo "Shipped. Restore with: scp $BB_USER@$BB_HOST:$DEST/<file> /root/restore/"
