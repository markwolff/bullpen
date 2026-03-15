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
}

/** Full asset manifest for Bullpen. */
export const BULLPEN_ASSETS: AssetEntry[] = [
  // ── Claude character sprites (32x48, 2:3) ──────────────────────────
  {
    name: "char_claude_idle",
    type: "character",
    description:
      "Claude AI agent standing idle at their desk. Friendly humanoid figure with a warm orange/amber accent color. Relaxed posture, arms at sides, facing slightly toward the viewer in 3/4 perspective.",
    aspectRatio: "2:3",
  },
  {
    name: "char_claude_thinking",
    type: "character",
    description:
      "Claude AI agent in a thinking pose. Hand on chin, small thought-bubble or sparkle effect above head. Orange/amber accent color. Slight head tilt suggesting deep consideration.",
    aspectRatio: "2:3",
  },
  {
    name: "char_claude_writing",
    type: "character",
    description:
      "Claude AI agent actively writing or typing. Hands on keyboard, leaning slightly forward with focus. Orange/amber accent. Small motion lines near hands to suggest rapid typing.",
    aspectRatio: "2:3",
  },
  {
    name: "char_claude_reading",
    type: "character",
    description:
      "Claude AI agent reading a document or screen. Holding a paper or looking intently at a monitor. Orange/amber accent. Slightly squinted eyes suggesting careful attention.",
    aspectRatio: "2:3",
  },
  {
    name: "char_claude_command",
    type: "character",
    description:
      "Claude AI agent executing a command. Confident stance, one hand raised as if directing. Orange/amber accent. Small command prompt icon or gear symbol floating nearby.",
    aspectRatio: "2:3",
  },
  {
    name: "char_claude_searching",
    type: "character",
    description:
      "Claude AI agent searching through files. Looking left and right, hand shading eyes or holding a magnifying glass. Orange/amber accent. Scattered paper or file icons nearby.",
    aspectRatio: "2:3",
  },
  {
    name: "char_claude_waiting",
    type: "character",
    description:
      "Claude AI agent waiting patiently. Arms crossed or hands behind back, small clock or hourglass icon nearby. Orange/amber accent. Relaxed but attentive posture.",
    aspectRatio: "2:3",
  },
  {
    name: "char_claude_error",
    type: "character",
    description:
      "Claude AI agent reacting to an error. Surprised expression, hands up in a startled pose. Orange/amber accent. Small red exclamation mark or X symbol floating nearby.",
    aspectRatio: "2:3",
  },
  {
    name: "char_claude_finished",
    type: "character",
    description:
      "Claude AI agent celebrating task completion. Happy pose with one arm raised in triumph. Orange/amber accent. Small green checkmark or star effect nearby.",
    aspectRatio: "2:3",
  },

  // ── Codex character sprites (32x48, 2:3) ───────────────────────────
  {
    name: "char_codex_idle",
    type: "character",
    description:
      "Codex AI agent standing idle at their desk. Distinct humanoid figure with a cool blue/teal accent color. Professional posture, arms at sides, facing slightly toward the viewer in 3/4 perspective.",
    aspectRatio: "2:3",
  },
  {
    name: "char_codex_thinking",
    type: "character",
    description:
      "Codex AI agent in a thinking pose. Hand on chin, small thought-bubble or sparkle effect above head. Blue/teal accent color. Analytical expression suggesting careful reasoning.",
    aspectRatio: "2:3",
  },
  {
    name: "char_codex_writing",
    type: "character",
    description:
      "Codex AI agent actively writing or typing. Hands on keyboard, leaning slightly forward. Blue/teal accent. Small motion lines near hands to suggest rapid coding.",
    aspectRatio: "2:3",
  },
  {
    name: "char_codex_reading",
    type: "character",
    description:
      "Codex AI agent reading code or documentation. Studying a screen intently. Blue/teal accent. Slightly narrowed eyes suggesting deep code review.",
    aspectRatio: "2:3",
  },
  {
    name: "char_codex_command",
    type: "character",
    description:
      "Codex AI agent executing a command. Confident stance, one hand raised. Blue/teal accent. Terminal prompt icon or spinning gear symbol floating nearby.",
    aspectRatio: "2:3",
  },
  {
    name: "char_codex_searching",
    type: "character",
    description:
      "Codex AI agent searching through a codebase. Scanning left and right, magnifying glass in hand. Blue/teal accent. Code snippet fragments floating nearby.",
    aspectRatio: "2:3",
  },
  {
    name: "char_codex_waiting",
    type: "character",
    description:
      "Codex AI agent waiting for a process. Arms crossed, small loading spinner or hourglass icon nearby. Blue/teal accent. Patient but alert posture.",
    aspectRatio: "2:3",
  },
  {
    name: "char_codex_error",
    type: "character",
    description:
      "Codex AI agent reacting to a build error. Surprised expression, hands up. Blue/teal accent. Red exclamation mark or broken gear symbol floating nearby.",
    aspectRatio: "2:3",
  },
  {
    name: "char_codex_finished",
    type: "character",
    description:
      "Codex AI agent celebrating task completion. Satisfied pose with thumbs up or arm raised. Blue/teal accent. Green checkmark or merge icon effect nearby.",
    aspectRatio: "2:3",
  },

  // ── Furniture (32x32, 1:1) ─────────────────────────────────────────
  {
    name: "furniture_desk",
    type: "furniture",
    description:
      "A warm brown wooden office desk seen from 3/4 top-down view. Simple, clean design with visible wood grain texture. Slightly darker edges. Fits a cozy indie office aesthetic.",
    aspectRatio: "1:1",
  },
  {
    name: "furniture_chair",
    type: "furniture",
    description:
      "A simple office swivel chair in dark gray/charcoal. 3/4 top-down view showing the seat and backrest. Slightly rounded shape, comfortable looking.",
    aspectRatio: "1:1",
  },
  {
    name: "furniture_monitor_on",
    type: "furniture",
    description:
      "A small CRT-style monitor on a stand, screen glowing with a soft white/blue light. 3/4 top-down view. The screen shows generic code-like lines. Cozy retro-tech feel.",
    aspectRatio: "1:1",
  },
  {
    name: "furniture_monitor_off",
    type: "furniture",
    description:
      "A small CRT-style monitor on a stand, screen dark/off. 3/4 top-down view. The screen is a dark gray rectangle. Same shape as monitor_on but clearly powered down.",
    aspectRatio: "1:1",
  },
  {
    name: "furniture_monitor_green",
    type: "furniture",
    description:
      "A small CRT-style monitor with a green-tinted screen glow indicating success/healthy status. 3/4 top-down view. Small green checkmark or green tint on screen.",
    aspectRatio: "1:1",
  },
  {
    name: "furniture_monitor_red",
    type: "furniture",
    description:
      "A small CRT-style monitor with a red-tinted screen glow indicating error/failure status. 3/4 top-down view. Small red X or red tint on screen. Warning feel.",
    aspectRatio: "1:1",
  },
  {
    name: "furniture_monitor_amber",
    type: "furniture",
    description:
      "A small CRT-style monitor with an amber/yellow-tinted screen glow indicating in-progress/warning status. 3/4 top-down view. Warm amber tint on screen.",
    aspectRatio: "1:1",
  },

  // ── Decorations (various sizes) ────────────────────────────────────
  {
    name: "decor_plant_1",
    type: "decoration",
    description:
      "A small potted desk plant with round green leaves in a terracotta pot. 3/4 top-down view. Adds life and warmth to the office. About 16x24 pixels.",
    aspectRatio: "2:3",
  },
  {
    name: "decor_plant_2",
    type: "decoration",
    description:
      "A tall potted floor plant with long pointed leaves in a white ceramic pot. 3/4 top-down view. Taller than desk plant, placed on the floor. About 16x32 pixels.",
    aspectRatio: "1:2",
  },
  {
    name: "decor_coffee_mug",
    type: "decoration",
    description:
      "A small coffee mug with steam wisps rising from it. White or cream colored mug. 3/4 top-down view. Tiny but recognizable. About 8x8 or 16x16 pixels.",
    aspectRatio: "1:1",
  },
  {
    name: "decor_clock",
    type: "decoration",
    description:
      "A round wall clock with a simple face showing hour and minute hands. Mounted on wall perspective. Light frame, dark numbers. About 16x16 pixels.",
    aspectRatio: "1:1",
  },
  {
    name: "decor_window",
    type: "decoration",
    description:
      "An office window showing a soft blue sky outside. Simple rectangular frame with crossbars. Warm light streaming in. About 32x32 pixels. Wall-mounted perspective.",
    aspectRatio: "1:1",
  },
  {
    name: "decor_whiteboard",
    type: "decoration",
    description:
      "A wall-mounted whiteboard with faint scribbles and diagrams drawn on it. Silver/gray frame, white surface. 3/4 top-down wall perspective. About 32x24 pixels.",
    aspectRatio: "4:3",
  },
  {
    name: "decor_lamp",
    type: "decoration",
    description:
      "A small warm desk lamp with a cone-shaped shade casting a soft yellow glow. 3/4 top-down view. Cozy and inviting. About 16x24 pixels.",
    aspectRatio: "2:3",
  },

  // ── Tiles (16x16, 1:1) ────────────────────────────────────────────
  {
    name: "tile_floor_wood",
    type: "tile",
    description:
      "A seamless wooden floor tile with warm tan/honey wood planks (#C4B6A0 base tone). Subtle wood grain lines running horizontally. Must tile seamlessly in all directions.",
    aspectRatio: "1:1",
  },
  {
    name: "tile_wall",
    type: "tile",
    description:
      "A seamless office wall tile with an off-white/cream color (#EAE6DF base tone). Very subtle texture or slight vertical stripe pattern. Must tile seamlessly in all directions.",
    aspectRatio: "1:1",
  },

  // ── Office cat (32x32, 1:1) ───────────────────────────────────────
  {
    name: "cat_idle",
    type: "character",
    description:
      "A small orange tabby office cat sitting upright, tail wrapped around paws. 3/4 top-down view. Content expression, ears perked. The office mascot resting between desk visits.",
    aspectRatio: "1:1",
  },
  {
    name: "cat_walk_1",
    type: "character",
    description:
      "A small orange tabby office cat mid-stride, walking frame 1. 3/4 top-down view. Left front paw and right back paw forward. Tail up, alert and curious expression.",
    aspectRatio: "1:1",
  },
  {
    name: "cat_walk_2",
    type: "character",
    description:
      "A small orange tabby office cat mid-stride, walking frame 2. 3/4 top-down view. Right front paw and left back paw forward. Tail up, continuing the walk cycle.",
    aspectRatio: "1:1",
  },
  {
    name: "cat_sleep",
    type: "character",
    description:
      "A small orange tabby office cat curled up sleeping. 3/4 top-down view. Circular curled pose, eyes closed, tail over nose. Small 'Z' sleep indicator. Peaceful and cozy.",
    aspectRatio: "1:1",
  },
];
