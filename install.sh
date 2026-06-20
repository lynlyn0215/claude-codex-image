#!/usr/bin/env bash
# Install the skills in this repo into ~/.claude/skills/ for Claude Code.
# Idempotent — safe to re-run. Installs every skills/<name>/ that has a SKILL.md.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src_root="$repo_root/skills"
dst_root="$HOME/.claude/skills"

if [[ ! -d "$src_root" ]]; then
  echo "install.sh: no skills/ dir found next to this script — run it from the cloned repo." >&2
  exit 1
fi

mkdir -p "$dst_root"

installed=()
for dir in "$src_root"/*/; do
  [[ -f "${dir}SKILL.md" ]] || continue          # skip non-skill entries
  name="$(basename "$dir")"
  dst="$dst_root/$name"
  rm -rf "$dst"
  cp -R "$dir" "$dst"
  # make wrapper scripts executable (root-level *.sh and anything under bin/)
  find "$dst" -type f \( -name "*.sh" -o -path "*/bin/*" \) -exec chmod +x {} \; 2>/dev/null || true
  installed+=("$name")
done

echo "✓ Installed ${#installed[@]} skill(s) → $dst_root"
for n in "${installed[@]}"; do echo "   • $n"; done

# --- engine prerequisite: codex CLI (for the codex-image generator) ---
echo
codex_bin=""
if command -v codex >/dev/null 2>&1; then codex_bin="$(command -v codex)"
elif [[ -x "/Applications/Codex.app/Contents/Resources/codex" ]]; then codex_bin="/Applications/Codex.app/Contents/Resources/codex"
elif [[ -x "$HOME/.local/bin/codex" ]]; then codex_bin="$HOME/.local/bin/codex"
fi

if [[ -z "$codex_bin" ]]; then
  cat >&2 <<'EOF'
⚠  codex CLI not found. The codex-image generator needs it.
     macOS:  brew install codex
     Then:   codex login        # log in with your ChatGPT subscription (Plus/Pro/Team)
   (The taste / imagegen art-direction skills work regardless; they just need an
    image generator like codex-image to actually produce pictures.)
EOF
  exit 0
fi

echo "✓ codex CLI detected ($codex_bin)"
if "$codex_bin" login status 2>/dev/null | grep -qi "logged in"; then
  echo "✓ codex is logged in — codex-image is ready."
else
  echo "⚠  codex is installed but not logged in. Run: codex login"
fi

echo
echo "Test the generator:"
echo "  ~/.claude/skills/codex-image/codex-image.sh \"a red balloon on a blue sky\" /tmp/test.png 1:1"
