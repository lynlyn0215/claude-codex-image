# claude-codex-image

**Give Claude Code real image generation — using your Codex / ChatGPT subscription, no API key — plus the design taste to know *what* to generate.**

Claude Code can't make pictures on its own. This kit bundles two halves that fit together:

1. **`codex-image`** — the *engine*. A thin wrapper that drives the local [`codex` CLI](https://github.com/openai/codex)'s built‑in `$imagegen` tool, so images are generated through your **ChatGPT/Codex subscription** — **no OpenAI API key, no per‑image billing.** Supports text‑to‑image and image‑to‑image (edit/restyle).
2. **Design‑taste skills** — the *art direction*. Vendored from [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) (MIT): anti‑slop frontend taste + per‑section image direction for web and mobile. They decide *what* images a good design needs; `codex-image` actually produces them.

```
  taste / imagegen-frontend-*  ──▶  decide WHAT to generate (art direction)
            │
            ▼
        codex-image            ──▶  codex exec  ──▶  $imagegen (your ChatGPT sub)
            │                                              │
   Claude  Read  ◀────────  out.png  ◀──── copied from ~/.codex/generated_images/
```

## What's inside

| Skill | Role |
|-------|------|
| `codex-image` | **Engine.** Generate / edit images via the Codex subscription. No API key. (this repo) |
| `taste-skill` (`design-taste-frontend`) | Anti‑slop frontend taste for landing pages, portfolios, redesigns. *(vendored, MIT)* |
| `imagegen-frontend-web` | Per‑section website design‑reference image direction. *(vendored, MIT)* |
| `imagegen-frontend-mobile` | App‑native mobile screen / flow image direction. *(vendored, MIT)* |

> The full taste‑skill collection (brutalist, minimalist, soft, stitch, redesign, brandkit, gpt‑taste, …) lives upstream at [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill). Drop any of those into `skills/` and re‑run `install.sh` to add them too.

## Prerequisites

- [Claude Code](https://docs.claude.com/en/docs/claude-code)
- [`codex` CLI](https://github.com/openai/codex) installed (`brew install codex` on macOS) and logged in:
  ```bash
  codex login            # log in with your ChatGPT subscription (Plus / Pro / Team)
  codex login status     # → "Logged in using ChatGPT"
  ```
- macOS or Linux (the engine wrapper is bash; Windows users can run it under WSL)

## Install

```bash
git clone https://github.com/lynlyn0215/claude-codex-image.git
cd claude-codex-image
./install.sh
```

`install.sh` copies every skill into `~/.claude/skills/`, makes the wrapper executable, and checks that `codex` is installed + logged in. Re‑running is safe. Restart Claude Code (or start a new session) so it picks up the new skills.

## Usage

Once installed, just ask Claude Code naturally:

- *"Generate an OG/social share image for this landing page."* → `codex-image` produces it.
- *"Design me a SaaS landing and generate a reference image for each section."* → `imagegen-frontend-web` directs, `codex-image` generates.
- *"Make 3 mobile onboarding screens."* → `imagegen-frontend-mobile` directs, `codex-image` generates.

### Call the engine directly

```bash
~/.claude/skills/codex-image/codex-image.sh "<prompt>" <output-path> [aspect] [reference-image]
```

- **aspect**: `1:1` (default) · `16:9` · `9:16` · `4:3` · `3:4`  — OG/social images use `16:9`.
- **reference-image** (optional 4th arg): a path = **image‑to‑image / edit** (restyle, change background, expand…).

```bash
# text-to-image (OG image)
~/.claude/skills/codex-image/codex-image.sh \
  "a silver chrome mechanical keycap with a glowing starburst, near-black bg, soft rim light, no text" \
  ./og.png 16:9

# image-to-image (restyle an existing picture)
~/.claude/skills/codex-image/codex-image.sh "restyle into neon cyberpunk night" ./out.png 16:9 ./input.jpg
```

The wrapper prints the saved path on stdout, or a clear error (codex missing / not logged in / quota) on stderr.

## How it works (engine)

`codex` ships a built‑in `$imagegen` image tool. The wrapper runs `codex exec --json` with a `$imagegen …` prompt; codex generates the image into `~/.codex/generated_images/<thread-id>/ig_*.png` using your subscription. The wrapper parses the thread id, finds that file, and copies it to your output path — so it doesn't depend on the model "remembering" to save the file. Env overrides: `CODEX_BIN`, `CODEX_HOME`, `CODEX_IMAGEGEN_MODEL` (default `gpt-5.5`).

## Cost & limits

No OpenAI API spend — calls consume your **ChatGPT subscription** message quota, and are rate‑limited by your plan. Don't burn quota on throwaways; generate deliberately.

## Credits & license

- **codex‑image engine** and packaging: this repo, MIT (see `LICENSE`). The Codex‑subscription image‑gen bridge idea is shared by the community — see also [oakplank/claude-gpt-image-bridge](https://github.com/oakplank/claude-gpt-image-bridge).
- **Design‑taste skills** (`taste-skill`, `imagegen-frontend-web`, `imagegen-frontend-mobile`): vendored from [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill), MIT — full text in `THIRD_PARTY_LICENSES.md`. All credit to the original author.
- Image generation runs on OpenAI's [`codex` CLI](https://github.com/openai/codex) and your ChatGPT subscription.
