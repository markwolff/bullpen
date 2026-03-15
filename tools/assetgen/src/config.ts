/**
 * Art bible and asset manifest for Bullpen pixel art generation.
 */

/** Art bible prompt — prepended to every generation request. */
export const ART_BIBLE = `\
Style: 2D pixel art, 3/4 top-down perspective (RPG-style, like Stardew Valley or Game Dev Tycoon).
Color palette: Warm, muted background tones (off-white walls #EAE6DF, tan wood floor #C4B6A0, brown desks #8B6544). Saturated accent colors for status indicators.
Resolution: Character sprites 32x48 pixels, furniture/tiles 16x16 or 32x32 pixels, scaled with nearest-neighbor filtering.
Outline: 1px dark outlines (#2D2D3D, warm dark — never pure black) on all sprites.
Perspective: 3/4 top-down view for all elements.
Lighting: Soft ambient lighting, warm office tones, no harsh directional shadows.
Background: Transparent where applicable.
Consistency: All assets must feel like they belong in the same cozy office environment.`;

/** Supported asset types with generation hints. */
export const TYPE_HINTS: Record<string, string> = {
  character:
    "A character sprite sheet frame. 32x48 pixels. The character should be clearly readable at small sizes with distinct silhouette.",
  furniture:
    "An office furniture piece. 32x32 pixels. Should look solid and grounded in the 3/4 perspective.",
  tile: "A seamless tileable texture. 16x16 pixels. Must tile cleanly in all directions.",
  decoration:
    "A small decorative object. Various sizes. Adds personality and warmth to the office scene.",
  icon: "A UI icon. 16x16 or 32x32 pixels. Clear, readable at small sizes with strong silhouette.",
};

/** A single asset definition in the manifest. */
export interface AssetEntry {
  name: string;
  type: string;
  description: string;
  aspectRatio: string;
  subdir: string;
}

/** Full asset manifest for Bullpen. */
export const BULLPEN_ASSETS: AssetEntry[] = [
  // ── Claude character sprites (32x48, 2:3) ──────────────────────────
  {
    name: "char_claude_idle",
    type: "character",
    description:
      "32x48 pixel art character sitting at office desk, relaxed posture, gentle bob pose, orange-tinted hoodie, warm skin tones, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background, cozy indie office aesthetic, friendly humanoid AI agent, arms at sides",
    aspectRatio: "2:3",
    subdir: "characters/claude",
  },
  {
    name: "char_claude_thinking",
    type: "character",
    description:
      "32x48 pixel art character in thinking pose, hand on chin, small sparkle effect above head, orange-tinted hoodie with amber accents, warm skin tones, slight head tilt, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background, cozy indie office aesthetic",
    aspectRatio: "2:3",
    subdir: "characters/claude",
  },
  {
    name: "char_claude_writing",
    type: "character",
    description:
      "32x48 pixel art character actively typing at keyboard, leaning slightly forward with focus, orange-tinted hoodie with amber accents, warm skin tones, small motion lines near hands suggesting rapid typing, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/claude",
  },
  {
    name: "char_claude_reading",
    type: "character",
    description:
      "32x48 pixel art character reading a document, holding paper or looking at monitor intently, orange-tinted hoodie with amber accents, warm skin tones, slightly squinted eyes, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background, careful attention expression",
    aspectRatio: "2:3",
    subdir: "characters/claude",
  },
  {
    name: "char_claude_command",
    type: "character",
    description:
      "32x48 pixel art character executing a command, confident stance with one hand raised directing, orange-tinted hoodie with amber accents, warm skin tones, small command prompt icon floating nearby, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/claude",
  },
  {
    name: "char_claude_searching",
    type: "character",
    description:
      "32x48 pixel art character searching through files, looking left and right with hand shading eyes, orange-tinted hoodie with amber accents, warm skin tones, scattered paper icons nearby, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/claude",
  },
  {
    name: "char_claude_waiting",
    type: "character",
    description:
      "32x48 pixel art character waiting patiently, arms crossed, small hourglass icon nearby, orange-tinted hoodie with amber accents, warm skin tones, relaxed but attentive posture, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/claude",
  },
  {
    name: "char_claude_error",
    type: "character",
    description:
      "32x48 pixel art character reacting to error, surprised expression with hands up startled, orange-tinted hoodie with amber accents, warm skin tones, small red exclamation mark floating nearby, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/claude",
  },
  {
    name: "char_claude_finished",
    type: "character",
    description:
      "32x48 pixel art character celebrating task completion, happy pose with one arm raised in triumph, orange-tinted hoodie with amber accents, warm skin tones, small green checkmark and star sparkle effect, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/claude",
  },

  // ── Codex character sprites (32x48, 2:3) ───────────────────────────
  {
    name: "char_codex_idle",
    type: "character",
    description:
      "32x48 pixel art character standing idle at desk, professional posture, cool blue-tinted hoodie with teal accents, warm skin tones, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background, distinct humanoid AI agent, arms at sides",
    aspectRatio: "2:3",
    subdir: "characters/codex",
  },
  {
    name: "char_codex_thinking",
    type: "character",
    description:
      "32x48 pixel art character in thinking pose, hand on chin, small thought-bubble sparkle above head, cool blue-tinted hoodie with teal accents, warm skin tones, analytical expression, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/codex",
  },
  {
    name: "char_codex_writing",
    type: "character",
    description:
      "32x48 pixel art character actively typing at keyboard, leaning forward coding, cool blue-tinted hoodie with teal accents, warm skin tones, small motion lines near hands, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/codex",
  },
  {
    name: "char_codex_reading",
    type: "character",
    description:
      "32x48 pixel art character reading code on screen, studying intently, cool blue-tinted hoodie with teal accents, warm skin tones, slightly narrowed eyes for deep code review, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/codex",
  },
  {
    name: "char_codex_command",
    type: "character",
    description:
      "32x48 pixel art character executing a command, confident stance with one hand raised, cool blue-tinted hoodie with teal accents, warm skin tones, terminal prompt icon floating nearby, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/codex",
  },
  {
    name: "char_codex_searching",
    type: "character",
    description:
      "32x48 pixel art character searching through codebase, scanning left and right with magnifying glass, cool blue-tinted hoodie with teal accents, warm skin tones, code snippet fragments floating nearby, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/codex",
  },
  {
    name: "char_codex_waiting",
    type: "character",
    description:
      "32x48 pixel art character waiting for process, arms crossed, small loading spinner icon nearby, cool blue-tinted hoodie with teal accents, warm skin tones, patient but alert posture, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/codex",
  },
  {
    name: "char_codex_error",
    type: "character",
    description:
      "32x48 pixel art character reacting to build error, surprised expression with hands up, cool blue-tinted hoodie with teal accents, warm skin tones, red exclamation mark floating nearby, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/codex",
  },
  {
    name: "char_codex_finished",
    type: "character",
    description:
      "32x48 pixel art character celebrating completion, satisfied pose with thumbs up, cool blue-tinted hoodie with teal accents, warm skin tones, green checkmark and merge icon effect, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "2:3",
    subdir: "characters/codex",
  },

  // ── Furniture (32x32, 1:1) ─────────────────────────────────────────
  {
    name: "furniture_desk",
    type: "furniture",
    description:
      "32x32 pixel art warm brown wooden office desk, 3/4 top-down RPG perspective, visible wood grain texture #8B6544 base tone, slightly darker edges, clean simple design, 1px dark outlines #2D2D3D, transparent background, cozy indie office aesthetic",
    aspectRatio: "1:1",
    subdir: "furniture",
  },
  {
    name: "furniture_chair",
    type: "furniture",
    description:
      "32x32 pixel art office swivel chair in dark gray charcoal, 3/4 top-down view showing seat and backrest, slightly rounded comfortable shape, 1px dark outlines #2D2D3D, transparent background, cozy indie office aesthetic",
    aspectRatio: "1:1",
    subdir: "furniture",
  },
  {
    name: "furniture_monitor_on",
    type: "furniture",
    description:
      "32x32 pixel art small CRT-style monitor on stand, screen glowing soft white-blue light, generic code lines on screen, 3/4 top-down RPG perspective, retro-tech cozy feel, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "1:1",
    subdir: "furniture",
  },
  {
    name: "furniture_monitor_off",
    type: "furniture",
    description:
      "32x32 pixel art small CRT-style monitor on stand, screen dark and powered off, dark gray rectangle screen, 3/4 top-down RPG perspective, same shape as monitor_on but clearly off, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "1:1",
    subdir: "furniture",
  },
  {
    name: "furniture_monitor_green",
    type: "furniture",
    description:
      "32x32 pixel art small CRT-style monitor on stand, green-tinted screen glow indicating success status, small green checkmark on screen, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background, healthy system indicator",
    aspectRatio: "1:1",
    subdir: "furniture",
  },
  {
    name: "furniture_monitor_red",
    type: "furniture",
    description:
      "32x32 pixel art small CRT-style monitor on stand, red-tinted screen glow indicating error status, small red X on screen, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background, warning error indicator",
    aspectRatio: "1:1",
    subdir: "furniture",
  },
  {
    name: "furniture_monitor_amber",
    type: "furniture",
    description:
      "32x32 pixel art small CRT-style monitor on stand, amber yellow-tinted screen glow indicating in-progress status, warm amber tint on screen, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "1:1",
    subdir: "furniture",
  },

  // ── Decorations (various sizes) ────────────────────────────────────
  {
    name: "decor_plant_1",
    type: "decoration",
    description:
      "16x24 pixel art small potted desk plant with round green leaves in terracotta pot, 3/4 top-down RPG perspective, adds life and warmth, 1px dark outlines #2D2D3D, transparent background, cozy indie office aesthetic",
    aspectRatio: "2:3",
    subdir: "decorations",
  },
  {
    name: "decor_plant_2",
    type: "decoration",
    description:
      "16x32 pixel art tall potted floor plant with long pointed leaves in white ceramic pot, 3/4 top-down RPG perspective, taller than desk plant placed on floor, 1px dark outlines #2D2D3D, transparent background, cozy indie office aesthetic",
    aspectRatio: "1:2",
    subdir: "decorations",
  },
  {
    name: "decor_coffee_mug",
    type: "decoration",
    description:
      "16x16 pixel art small coffee mug with steam wisps rising, white cream colored mug, 3/4 top-down RPG perspective, tiny but recognizable, 1px dark outlines #2D2D3D, transparent background, cozy office detail",
    aspectRatio: "1:1",
    subdir: "decorations",
  },
  {
    name: "decor_clock",
    type: "decoration",
    description:
      "16x16 pixel art round wall clock with simple face showing hour and minute hands, wall-mounted perspective, light frame dark numbers, 1px dark outlines #2D2D3D, transparent background, cozy office detail",
    aspectRatio: "1:1",
    subdir: "decorations",
  },
  {
    name: "decor_window",
    type: "decoration",
    description:
      "32x32 pixel art office window showing soft blue sky outside, simple rectangular frame with crossbars, warm light streaming in, wall-mounted perspective, 1px dark outlines #2D2D3D, transparent background, cozy indie office aesthetic",
    aspectRatio: "1:1",
    subdir: "decorations",
  },
  {
    name: "decor_whiteboard",
    type: "decoration",
    description:
      "32x24 pixel art wall-mounted whiteboard with faint scribbles and diagrams, silver gray frame white surface, 3/4 top-down wall perspective, 1px dark outlines #2D2D3D, transparent background, cozy indie office aesthetic",
    aspectRatio: "4:3",
    subdir: "decorations",
  },
  {
    name: "decor_lamp",
    type: "decoration",
    description:
      "16x24 pixel art small warm desk lamp with cone-shaped shade casting soft yellow glow, 3/4 top-down RPG perspective, cozy and inviting, 1px dark outlines #2D2D3D, transparent background, warm ambient lighting",
    aspectRatio: "2:3",
    subdir: "decorations",
  },

  // ── Tiles (16x16, 1:1) ────────────────────────────────────────────
  {
    name: "tile_floor_wood",
    type: "tile",
    description:
      "16x16 pixel art seamless wooden floor tile, warm tan honey wood planks #C4B6A0 base tone, subtle wood grain lines running horizontally, must tile seamlessly in all directions, 1px dark outlines #2D2D3D, no transparency, cozy indie office aesthetic",
    aspectRatio: "1:1",
    subdir: "tiles",
  },
  {
    name: "tile_wall",
    type: "tile",
    description:
      "16x16 pixel art seamless office wall tile, off-white cream color #EAE6DF base tone, very subtle texture with slight vertical stripe pattern, must tile seamlessly in all directions, 1px dark outlines #2D2D3D, no transparency, cozy indie office aesthetic",
    aspectRatio: "1:1",
    subdir: "tiles",
  },

  // ── Office cat (32x32, 1:1) ───────────────────────────────────────
  {
    name: "cat_idle",
    type: "character",
    description:
      "32x32 pixel art small orange tabby office cat sitting upright, tail wrapped around paws, content expression with ears perked, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background, cozy office mascot",
    aspectRatio: "1:1",
    subdir: "cat",
  },
  {
    name: "cat_walk_1",
    type: "character",
    description:
      "32x32 pixel art small orange tabby office cat mid-stride walk frame 1, left front paw and right back paw forward, tail up alert curious expression, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "1:1",
    subdir: "cat",
  },
  {
    name: "cat_walk_2",
    type: "character",
    description:
      "32x32 pixel art small orange tabby office cat mid-stride walk frame 2, right front paw and left back paw forward, tail up continuing walk cycle, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "1:1",
    subdir: "cat",
  },
  {
    name: "cat_sleep",
    type: "character",
    description:
      "32x32 pixel art small orange tabby office cat curled up sleeping, circular curled pose eyes closed tail over nose, small Z sleep indicator, peaceful cozy, 3/4 top-down RPG perspective, 1px dark outlines #2D2D3D, transparent background",
    aspectRatio: "1:1",
    subdir: "cat",
  },
];
