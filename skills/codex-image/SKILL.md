---
name: codex-image
description: Generate (or edit) images using a Codex subscription's built-in image tool via the local `codex` CLI — no OpenAI API key, no Open Design, no extra service. Use when the user wants to generate/create/make an image, illustration, icon, logo, hero art, OG/social-share image, texture, or edit/restyle an existing image, AND has the Codex CLI installed and logged in (a Codex/ChatGPT subscription). Ideal for people who use Claude Code but also pay for Codex and want to spend that image quota instead of a separate paid API.
---

# codex-image — 用 Codex 订阅生图(不走 API key)

让同时有 **Claude Code** 和 **Codex 订阅** 的人，在 Claude Code 里直接用 Codex 的内置
`$imagegen` 能力生成图片——**不需要 OpenAI API key、不需要 Open Design**，只用本地 `codex` CLI
的登录态（消耗的是 Codex 订阅额度）。

## 原理(一句话)

`codex` CLI 自带 `$imagegen` 工具。给 `codex exec` 喂一条以 `$imagegen ` 开头的 prompt，
它就用你的订阅生成图，存到 `~/.codex/generated_images/<thread_id>/ig_*.png`。本技能的脚本
把这条链路封好：跑 codex → 解析 thread_id → 找到 `ig_` 图 → 拷到你指定路径。

## 前置条件

- 已安装 **Codex CLI** 并登录(`codex login`)。脚本按此顺序探测可执行文件：
  `$CODEX_BIN` → PATH 里的 `codex` → `/Applications/Codex.app/Contents/Resources/codex` → `~/.local/bin/codex`。
- macOS / Linux(Windows 需要 `danger-full-access` 沙箱，脚本暂未处理)。
- 找不到 codex 或未登录时脚本会报清楚的错。

## 怎么用

调用本技能目录下的脚本即可：

```bash
bash ~/.claude/skills/codex-image/codex-image.sh "<prompt>" <输出路径> [aspect] [参考图]
```

- **prompt**(必填)：英文描述通常质量更稳；可写「no text」避免乱码文字。
- **输出路径**(必填)：例如 `landing/assets/og.jpg` 或 `./hero.png`。脚本把生成的 `ig_` 图拷到这里（自动建目录）。
- **aspect**(可选，默认 `1:1`)：常用 `1:1` / `16:9` / `9:16` / `4:3` / `3:4`。OG/社交图用 `16:9`。
- **参考图**(可选)：传一张图的路径 = **图生图/编辑**(restyle、改背景、扩展等)。

脚本成功后**只在 stdout 打印输出文件路径**，失败则非零退出并打印原因。

### 示例

```bash
# 1) 文生图:深色产品英雄图
bash ~/.claude/skills/codex-image/codex-image.sh \
  "a silver chrome mechanical keycap with a glowing four-point starburst, near-black background, soft rim light, no text" \
  ./hero.png 16:9

# 2) 图生图:把一张图改成赛博朋克夜景
bash ~/.claude/skills/codex-image/codex-image.sh \
  "restyle into neon cyberpunk night, rain reflections" \
  ./out.png 16:9 ./input.jpg
```

## 给 agent 的执行建议

1. 先确认用户想要的尺寸/用途，挑合适 aspect（OG 图 → 16:9，App 图标 → 1:1）。
2. prompt 用具体、英文、含风格/光线/背景/「no text」等约束。
3. 直接 `bash` 调脚本，拿回 stdout 的路径。
4. 生成的是 PNG；要更小可后续 `sips -s format jpeg ... ` 压成 JPG。
5. 生成会消耗用户 Codex 订阅额度，**一次到位、别盲目连刷**；要多版让用户先确认。

## 环境变量(可选)

- `CODEX_BIN`：指定 codex 可执行文件路径。
- `CODEX_HOME`：codex 数据目录(默认 `~/.codex`)。
- `CODEX_IMAGEGEN_MODEL`：编排模型(默认 `gpt-5.5`)。

## 排错

- `找不到 codex CLI` → 装 Codex / `codex login` / 设 `CODEX_BIN`。
- `没有返回 thread_id` 或 `未找到 ig_ 图` → 多半是未登录、额度用尽或被沙箱拦；看脚本打印的 stderr 尾部。
