---
name: codex-imagegen
description: Generate or edit raster images via the Codex CLI's built-in image_gen tool. Use when the user wants an image created, edited, or varied. Not for SVG/vector assets or diagrams better made in code.
---

# codex-imagegen

Produce real raster images from Claude Code by handing a tight prompt spec to Codex's built-in `image_gen` tool. This skill replaced the old nanobanana MCP server.

## How it works

`scripts/codex_image.py` runs one isolated `codex exec` per image:

- empty temp directory, read-only sandbox, `--ephemeral`, prompt on stdin;
- the Codex relay model is told to call `image_gen` once with the prompt, copied verbatim;
- Codex saves the PNG to `~/.codex/generated_images/<thread_id>/`, and the script copies it to `--out`;
- `OPENAI_API_KEY` is removed from the child environment, so usage hits the ChatGPT plan, never the metered API.

What the built-in tool gives you, and what it does not:

| Control | Built-in `image_gen` | How this skill handles it |
| --- | --- | --- |
| Prompt | yes | Your spec, verbatim |
| Reference or edit images | yes (`referenced_image_paths`) | `--ref` (repeatable, order = Image 1, 2, …) |
| Transparent background | yes (`transparent_background`) | `--transparent`; the script verifies the alpha corners |
| Size, aspect ratio | **no parameter** | Say the ratio in the prompt; use `--size WxH` for exact pixels (local crop or pad) |
| Quality, model, seed, `n` | **no** | Codex-managed. Use `--n` for parallel variants |
| Mask inpainting | **no** | Describe the region in words and list the invariants |

Native output is about 1.6 MP at the requested ratio (a 16:9 prompt gave 1672x941). One image takes **25–90 s**. Up to 4 variants run in parallel in about the same time.

## Requirements

- `codex` on PATH and logged in with ChatGPT (`codex login status` prints `Logged in using ChatGPT`). Only Whopper ships it. On BigTasty the script stops with a clear error.
- `python3` and ImageMagick `magick`. Both hosts have them.

## Workflow

1. **Is a bitmap right?** If the asset should be SVG, code or an edit to an existing vector file, say so and stop. Otherwise continue.
2. **Classify the request.**
   - Generate or edit?
   - One image or variants?
   - Where does it go?
     - The project, under a path the user named or one that fits the repo, like `public/images/`.
     - Or preview only, under `/tmp/codex-imagegen/<slug>.png`.
3. **Write the prompt spec** with the template below. Read `references/prompting.md` once per session before the first non-trivial prompt. It has the rules and the per-use-case recipes.
4. **Run the script** with the Bash tool and `timeout: 600000`:

   ```bash
   python3 ~/.claude/skills/codex-imagegen/scripts/codex_image.py \
     --out public/images/hero.png --size 1920x1080 --prompt-file /tmp/codex-imagegen/hero.txt
   ```

   For long specs, write them to a file and use `--prompt-file`; this avoids shell-quoting damage. Generate distinct assets as separate calls; run independent ones as parallel Bash calls.
5. **Do visual QA.** Read every output image, or the `sheet` for variants. Check it against the spec:
   - subject and composition;
   - in-image text, letter by letter;
   - the edit invariants, i.e. what had to stay unchanged;
   - the aspect ratio;
   - for transparent output, `alpha_ok` and the edges, with no halo and no fake checkerboard.
6. **Iterate deliberately.** Make one targeted change per round. Edit the best result (`--ref <it>`) rather than re-rolling from scratch. Restate every invariant each round. Stop after 2 correction rounds and report what is still off instead of burning quota.
7. **Report:**
   - final path(s), with dimensions;
   - the final prompt;
   - for variants, the one you picked and why;
   - any defect left that QA found.

   If the asset is used in code, wire it in: imports, `<img>` tags, `alt` text.

## Prompt spec template

Use labeled lines and drop the ones that don't help. Order matters: scene → subject → details → constraints.

```text
Use case: <photorealistic | product-mockup | ui-mockup | infographic | logo-brand | illustration | stylized-concept | ads-marketing | edit:<kind>>
Asset: <where it will be used, e.g. landing-page hero, blog header, app-store screenshot>
Frame: <aspect ratio in words AND numbers, e.g. "wide 16:9 landscape">; <composition: centered / rule of thirds / negative space on the left for copy>
Scene: <environment or backdrop>
Subject: <main subject, concrete materials, shapes, textures>
Style: <medium: photorealistic photo / watercolor / flat vector / 3D render>; <quality levers only if needed: film grain, macro detail>
Lighting: <light source + mood>
Palette: <colors or "neutral">
Text (verbatim): "<EXACT COPY>" — <font style, weight, size, color, placement>; render once, no extra characters
Images: Image 1 = <edit target | style reference | subject to insert>; Image 2 = …
Keep unchanged: <edit invariants>
Avoid: no watermark; no logos; no extra text; <other negatives>
```

Rules that matter most:

- **Always state the aspect ratio in the prompt.** The tool has no size parameter.
- **Photorealism:** say "photorealistic" explicitly. Use camera language (35mm, 50mm lens, eye level, shallow depth of field) for look and framing, not as exact physics.
- **Text:** put it in quotes or ALL CAPS. Give the font, size, color and placement. Say "exactly once, verbatim". Spell rare words letter by letter.
- **Edits:** write "change ONLY X; keep Y, Z unchanged" and repeat it on every iteration to stop drift.
- **Multiple images:** label each one by index and role, and say how they interact. Example: "apply Image 2's style to Image 1".
- **Specific requests:** if the user's prompt is already specific, normalize it and do not embellish. If it is vague, add only composition, intended-use and polish hints. Never invent brands, slogans, extra characters or palettes.

## Script reference

```text
codex_image.py --out PATH [--prompt TEXT | --prompt-file FILE | stdin]
               [--ref IMG]... [--transparent] [--n 1-4]
               [--size WxH] [--fit cover|contain] [--force]
               [--model M] [--effort low] [--timeout 300]
```

- `--out` sets the extension: `.png`, `.webp` or `.jpg`. Other formats are converted with `magick`. JPEG is refused with `--transparent`.
- The script never overwrites by default. An existing file gets a sibling `-v2`, `-v3` and so on. `--force` replaces it.
- `--n N` runs N parallel variants named `<stem>-1 … <stem>-N`, plus `<stem>-sheet.png`, a left-to-right contact sheet to Read for comparison.
- `--size` makes exact pixels locally after generation. `cover` (the default) crops to fill; `contain` pads with transparency.
  - Ask for the same ratio in the prompt, or the crop will cut the subject.
- `--model` / `--effort` only steer the relay model. The image model is Codex-managed and cannot be chosen.
- Stdout is a single JSON object, for example:

  ```json
  {"ok": true, "images": [{"path": "...", "width": 1672, "height": 941, "alpha_ok": true,
    "source": "~/.codex/generated_images/<thread>/exec-....png", "thread_id": "...", "elapsed_s": 34.2}],
   "sheet": "...-sheet.png"}
  ```

  Failed images carry `error`, `thread_id` and `agent_message`. Exit code: 0 means everything was saved, 2 means partial success, 1 means nothing was saved or there was a usage error.
- Every saved image is appended to `~/.local/state/codex-imagegen/history.jsonl` with its prompt, refs, Codex version, dimensions and source path. Use it to answer "what prompt made this?".

## Failure handling

- **Exit 0 from codex does not mean an image exists.** Tool errors, usage limits and refusals reach the relay model as text. The script treats a missing PNG as failure and surfaces the relay's message.
- **Never auto-retry a failure.** A timeout may still have produced an image, and retries burn quota.
  - Read the `error`. On a usage or rate limit, tell the user and stop.
  - On a content-policy block, rephrase only if the request is legitimate. Do not route around it.
  - On a transient 5xx or network error, one manual retry is fine.
- If `alpha_ok` is `false`, look at the image. Then do one retry that asks harder for transparency, e.g. "isolated subject, fully transparent background, no shadow, no checkerboard, no backdrop". The fallback is to regenerate on a flat `#FF00FF` background and chroma-key it out:

  ```bash
  magick in.png -fuzz 12% -transparent '#FF00FF' out.png
  ```

  Then check the edges for a magenta fringe.
- The script prints `codex CLI not found` or `not logged in with ChatGPT`. Tell the user. Do not set up an API key on your own initiative.

## Costs and etiquette

- Every image draws on the user's shared ChatGPT/Codex allowance, and images burn it several times faster than text.
  - Default to 1 image. Offer variants (`--n 2-4`) when the direction is open.
  - Don't spray rerolls.
- Prompts go to OpenAI. Keep secrets, private data and client-confidential material out of them.
- Don't depict real private people. Don't copy trademarked characters or logos unless the user owns them.
- Images used by the project belong in the project tree. Never leave a referenced asset only under `~/.codex/generated_images/`.
