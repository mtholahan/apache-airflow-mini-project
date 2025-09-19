#!/usr/bin/env bash

# install_symlinks.sh
# One-time setup: symlinks bash config files and adds dotfiles/scripts to PATH.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "🔗 Linking dotfiles into home directory..."

# Symlink bashrc and airflow helpers
ln -sf "$ROOT/bash/.bashrc"       "$HOME/.bashrc"
ln -sf "$ROOT/bash/.bash_airflow" "$HOME/.bash_airflow"

# Optional: copy private template if none exists
if [ ! -f "$HOME/.bash_private" ]; then
  cp "$ROOT/bash/.bash_private" "$HOME/.bash_private"
  echo "✅ .bash_private created from template."
fi

# Add scripts/ to PATH if not already present
if ! grep -q "dotfiles/scripts" "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/code/dotfiles/scripts:$PATH"' >> "$HOME/.bashrc"
  echo "✅ PATH updated in .bashrc"
fi

echo -e "\n📎 Installed symlinks:"
ls -l "$HOME/.bashrc" "$HOME/.bash_airflow" 2>/dev/null || true

echo -e "\n🔁 Reload shell with:"
echo "source ~/.bashrc"

echo "🔧 Enforcing LF endings for all shell scripts..."

# 1. Add .gitattributes rule (if missing)
GITATTR="$HOME/code/dotfiles/.gitattributes"
if ! grep -q '\*.sh text eol=lf' "$GITATTR" 2>/dev/null; then
  echo '*.sh text eol=lf' >> "$GITATTR"
  echo "[+] Added '*.sh text eol=lf' to .gitattributes"
fi

# 2. Set global Git config to convert only on input
git config --global core.autocrlf input
echo "[+] Set git core.autocrlf=input globally"

# 3. Normalize existing shell scripts
find "$HOME/code/dotfiles" -name '*.sh' -exec dos2unix {} \;
echo "[+] Converted all *.sh in dotfiles to LF endings"
