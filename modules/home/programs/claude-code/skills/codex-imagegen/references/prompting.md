# Prompting reference for codex-imagegen

These rules are distilled from three sources:

- OpenAI's [GPT Image prompting guide](https://developers.openai.com/cookbook/examples/multimodal/image-gen-models-prompting-guide) (gpt-image-2);
- the Codex system skill `~/.codex/skills/.system/imagegen/` (Apache-2.0);
- community Codex wrappers (links at the end).

The built-in tool takes only a prompt, reference images and a transparency flag. Everything else, including size and quality, has to live in the prompt.

## Principles

1. **Order and labels.** Write scene/backdrop → subject → key details → constraints, then the intended use. For anything complex, use short labeled lines instead of one paragraph. Choose a skimmable template over clever syntax.
2. **Intended use sets the mode.** Say what the image is for: "landing-page hero", "app-store screenshot", "classroom handout", "billboard". This sets the polish level and the layout conventions.
3. **Be concrete about the physical world.** Name materials, shapes, textures and the medium (photo, watercolor, gouache, flat vector, 3D render, risograph). Add quality levers only when they serve the look: *film grain*, *macro detail*, *textured brushstrokes*.
4. **Photorealism:** say "photorealistic" or "real photograph". Ask for real texture, such as pores, fabric wear and imperfections. Avoid words that imply staging ("perfect", "glamour") unless you want that look. Lens and camera terms steer framing and feel, not exact optics.
5. **The aspect ratio always goes in the prompt.** State it in words and numbers: "tall 9:16 portrait", "wide 16:9 landscape", "square 1:1". When the asset needs room for UI or copy, say where the negative space goes.
6. **Text in the image:**
   - put the exact copy in quotes or ALL CAPS;
   - say "render exactly once, verbatim, no extra characters";
   - give the font style, weight, color, size and placement;
   - spell unusual words letter by letter;
   - keep copy short, because long paragraphs degrade;
   - check every glyph during QA.
7. **Edits: change versus keep.** Write "Change ONLY <X>. Keep <Y> unchanged." List what must survive: identity, pose, camera angle, lighting, shadows, layout, text, logos. Repeat the invariants on every iteration; drift accumulates.
8. **Multiple images by index.** Write "Image 1: product photo (edit target). Image 2: style reference." Then say how they interact: "Apply Image 2's palette and brushwork to Image 1." For composites, say what moves where and what must match: lighting, perspective, scale, contact shadows.
9. **Iterate with one change at a time.** Start from a clean base prompt. Then make single targeted follow-ups ("warmer light", "remove the extra chair") by editing the best output. Do not rewrite the whole prompt.
10. **Specificity policy:**
    - When the user is already specific, normalize their words into the template without adding creative content.
    - When the user is vague, add only composition, intended use and polish hints.
    - Never invent brands, slogans, extra characters, palettes or story beats.
11. **Transparent assets:** set `--transparent` and ask for an isolated subject with clean alpha edges, generous padding, no backdrop, no shadow and no fake checkerboard.
12. **Always say "no watermark".** Add "no logos" and "no extra text" unless they are wanted.

## Recipes by use case

Copy a recipe, fill it, and delete the lines that don't apply.

### Photorealistic, natural

```text
Use case: photorealistic
Asset: <editorial header / team page portrait>
Frame: <4:5 portrait>, <medium close-up at eye level>
Scene: <real location, time of day>
Subject: <who/what, doing what; real texture: skin pores, fabric wear>
Style: photorealistic candid photograph, 35mm film look, 50mm lens, shallow depth of field, subtle grain
Lighting: <soft window light from the left / overcast daylight>
Avoid: no glamorization, no heavy retouching, no text, no watermark
```

### Product mockup

```text
Use case: product-mockup
Asset: <e-commerce hero / catalog tile>
Frame: <1:1 square>, product centered, generous negative space
Scene: <seamless paper backdrop / styled surface: pale oak table>
Subject: <product, exact materials, finish, color>
Style: photorealistic studio product photography, crisp edges, accurate materials
Lighting: <softbox key light from upper left, gentle contact shadow>
Avoid: no logos, no text, no watermark, no props unless listed
```

### Website hero or background

```text
Use case: stylized-concept
Asset: landing-page hero background
Frame: wide 16:9 landscape; calm negative space on the left third for headline copy
Subject: <abstract shapes / scene that signals the product's domain>
Style: <matte 3D / soft gradient illustration / editorial photo>
Palette: <brand colors as names or hex>
Avoid: no text, no logos, no UI, no watermark
```

### UI mockup

Describe it as if it already shipped. Use real interface vocabulary, not concept-art language.

```text
Use case: ui-mockup
Asset: <app-store screenshot / pitch-deck slide>
Frame: <9:16 portrait> inside an iPhone frame
Subject: <screen name>: <header, list of X with small photos, section "Today's specials", bottom tab bar>
Style: real, polished, shipped product UI; clear hierarchy; <light theme, subtle accent color>
Text (verbatim): "<screen title>" — bold sans-serif header
Avoid: no lorem ipsum, no watermark
```

### Infographic or educational diagram

```text
Use case: infographic
Asset: <slide / handout> for <audience>
Frame: <3:2 landscape>, clean grid, generous white space
Subject: <process/system>; required parts: <A, B, C...>; arrows showing <flow>
Text (verbatim): title "<TITLE>"; labels: "<label1>", "<label2>", ...
Style: flat, consistent icon style, high-contrast readable labels, white background
Avoid: tiny text, decorative clutter, any labels not listed
```

The tool cannot set `quality=high`. For dense labels, keep the text short and generate in several passes, or build the diagram in SVG instead.

### Logo or brand mark

```text
Use case: logo-brand
Asset: logo exploration for <name>, a <what the company does>
Frame: 1:1 square, single centered mark, generous padding
Subject: original, non-infringing mark; <personality: warm, timeless / sharp, technical>
Style: clean vector-like shapes, strong silhouette, balanced negative space, flat, minimal strokes, no gradients
Text (verbatim): "<NAME>" (only if a wordmark is wanted)
Avoid: no mockup scenery, no checkerboard, no watermark
```

Pair it with `--transparent --n 4`. Logos usually end up redrawn as vectors, so treat these as concepts.

### Ad or marketing creative

Write a creative brief: brand, audience, positioning, vibe, scene and the exact tagline. Then let the model make taste calls within those limits.

```text
Use case: ads-marketing
Asset: <Instagram 4:5 ad / billboard 3:1>
Brief: <brand> is <positioning> for <audience>; vibe: <...>
Scene: <concept>
Text (verbatim): tagline "<TAGLINE>" — rendered exactly once, clean legible typography, <placement>
Avoid: no extra text, no unrelated logos, no watermark
```

### Illustration or story, with a consistent character

1. Generate a **character anchor**: plain background, full body, neutral pose. Spell out the outfit, proportions and palette in the prompt.
2. For every later scene, use `--ref anchor.png` and write "Image 1 is the character reference. Keep the face, proportions, outfit and palette identical. New scene: …".

### Edits

Pass the edit target as `--ref` (Image 1). Start every edit prompt with "Image 1 is the edit target."

| Kind | Prompt core |
| --- | --- |
| Object swap | "Replace ONLY the <object> with <new>. Preserve camera angle, lighting, shadows and every other object." |
| Remove object | "Remove ONLY the <object>; fill the area naturally, matching the surrounding texture and light. Change nothing else." |
| Lighting/weather | "Change ONLY the time of day to <golden hour>. Keep the composition, subjects and geometry identical." |
| Background cutout | add `--transparent`; "Remove the background so only <subject> remains with clean alpha edges. No shadow, no checkerboard." |
| Background replace | "Replace ONLY the background with <new>. Keep the subject, its edges and lighting direction unchanged; match the light on the subject." |
| Text localization | "Translate ONLY the text to <language>, verbatim and accurate. Keep the typography style, placement, sizes and every non-text element unchanged." |
| Style transfer | "Image 1 is the style reference. Create <new subject/scene> in exactly that style (palette, texture, linework). <background/framing constraints>." |
| Composite | "Image 1 is the scene, Image 2 the <subject>. Place the <subject> from Image 2 <where> in Image 1; match the lighting, perspective, scale and contact shadows. Change nothing else." |
| Sketch to render | "Image 1 is a sketch. Render it as <photorealistic / 3D> while keeping its exact layout, proportions and perspective." |
| Identity-preserving | "Keep the person's face, identity, body shape, pose and expression unchanged. Change ONLY <garment/setting>." |

## QA checklist after each image

- The subject and every requested element are present, and nothing extra has been added.
- The aspect ratio and composition match the spec, and the negative space is where the copy goes.
- Every text glyph is correct, appears once, and is legible at the size it will be used.
- Edits: the invariants really are unchanged. Compare against the source side by side.
- Transparent output: `alpha_ok` is true, with clean edges, no halo and no baked-in checkerboard.
- No watermark artifacts, warped hands or garbled micro-text in the corners.

## Prior art this skill borrows from

- [JPInert/codex-image](https://github.com/JPInert/codex-image): uses the thread id from `thread.started` to find `generated_images/<thread_id>/`, and gates billing on the ChatGPT login.
- [JunSeo99/claude-skill-codex-imagegen](https://github.com/JunSeo99/claude-skill-codex-imagegen): empty temp directory, read-only relay, alpha verification, no automatic retries.
- [aldegad/image-gen](https://github.com/aldegad/image-gen): chroma-key fallback for transparency.
- [stephenlzc/codex-image-gen](https://github.com/stephenlzc/codex-image-gen): local resize to exact sizes, and a prompt archive.
- [mishagavura/claude-code-image-generation](https://github.com/mishagavura/claude-code-image-generation): never overwrite, and report quota errors loudly.
