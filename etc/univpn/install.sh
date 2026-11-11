#!/usr/bin/env bash
#
# One-time system setup for the passwordless `univpn` zsh function (macOS).
# Not stowed: the root script and sudoers rule must be root-owned copies, never
# symlinks into this user-writable repo (else editing them = passwordless root).
#
#   ~/dotfiles/etc/univpn/install.sh
#
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT=/usr/local/sbin/univpn-connect
RULE=/etc/sudoers.d/univpn

echo "==> Installing $SCRIPT"
sudo install -d -o root -g wheel -m 755 /usr/local/sbin
sudo install -o root -g wheel -m 755 "$HERE/univpn-connect" "$SCRIPT"

echo "==> Installing $RULE"
tmp="$(mktemp)"
echo "$USER ALL=(root) NOPASSWD: $SCRIPT \"\"" > "$tmp"
sudo visudo -cf "$tmp" >/dev/null
sudo install -o root -g wheel -m 440 "$tmp" "$RULE"
rm -f "$tmp"

if security find-generic-password -a s8jjmeye -s univpn >/dev/null 2>&1; then
  echo "==> Keychain item 'univpn' already present"
else
  echo "==> Storing UdS VPN password in the login keychain"
  security add-generic-password -a s8jjmeye -s univpn -w
fi

echo "==> Done. Open a new shell and run: univpn"
