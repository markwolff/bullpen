# Milestone 5: Pixel Art Asset Generation

**Goal**: Use the `tools/assetgen/` tool (scaffolded in Milestone 1) to generate all pixel art assets via Vercel AI Gateway + FLUX Kontext Max. After this milestone, the `Assets/` directory contains production-quality pixel art PNGs for all characters, furniture, decorations, and tiles.

**Human involvement needed at end**:
1. Provide `AI_GATEWAY_API_KEY` in `tools/assetgen/.env`
2. Run `pnpm tsx src/index.ts batch` and review generated art quality
3. Re-run individual assets that need improvement (tweak prompts)
4. Approve final asset set before integration

**Depends on**: Milestone 1 (assetgen scaffolded, art bible defined, manifest defined)

**NOTE**: This milestone is independent of Milestones 2–4. It can run in parallel with log reader and scene work.

---

## Tasks

### 5.1 Implement the `generate` command
- **What**: Wire up the CLI `generate` subcommand in `src/index.ts`.
- **Behavior**:
  - Flags: `-t, --type <type>` (character/furniture/tile/decoration/icon), `-d, --description <desc>`, `-n, --name <name>`, `-m, --model <model>` (default: `bfl/flux-kontext-max`), `-a, --aspect-ratio <ratio>` (default: `1:1`), `-o, --output <dir>` (default: `output/`)
  - Validates inputs with Zod schema
  - Builds prompt: ART_BIBLE + type hint + "Asset description: " + description
  - Calls `generateImage()` from `@ai-sdk/gateway`
  - Saves PNG and `.meta.json` sidecar to output directory
- **Verify**: `pnpm tsx src/index.ts generate -t furniture -d "wooden office desk" -n test_desk` creates `output/test_desk.png` and `output/test_desk.meta.json`. (Requires API key.)

### 5.2 Implement the `batch` command
- **What**: Wire up the CLI `batch` subcommand that generates all assets from the manifest.
- **Behavior**:
  - Reads `BULLPEN_ASSETS` array from config
  - Generates each asset sequentially (to avoid rate limiting)
  - Skips assets that already exist in output directory (unless `--force` flag)
  - Prints progress: `[3/42] Generating char_claude_idle...`
  - On error: logs the error, continues with next asset (doesn't abort batch)
  - Summary at end: X generated, Y skipped, Z failed
- **Verify**: `pnpm tsx src/index.ts batch --help` shows usage. With `--force`, regenerates all assets.

### 5.3 Write character sprite prompts — Claude Code agent (9 states)
- **What**: Write detailed descriptions for each Claude Code character sprite in the manifest.
- **Prompts must specify**:
  - 32x48 pixel character, 3/4 top-down view
  - Orange/warm-tinted character (Anthropic brand association)
  - Specific pose per state:
    - `char_claude_idle`: "Pixel art character sitting at desk, relaxed posture, gentle bob, occasional blink. Orange-tinted hoodie, warm skin tones."
    - `char_claude_thinking`: "Pixel art character leaning back in chair, hand on chin, looking upward thoughtfully. Orange-tinted hoodie."
    - `char_claude_writing`: "Pixel art character seated at desk, hands on keyboard, rapid typing posture, leaned slightly forward. Orange-tinted hoodie."
    - `char_claude_reading`: "Pixel art character leaned forward toward monitor, slow head tilt, studying screen intently. Orange-tinted hoodie."
    - `char_claude_command`: "Pixel art character watching screen intently, still posture, focused expression. Orange-tinted hoodie."
    - `char_claude_searching`: "Pixel art character looking left and right, scanning motion, alert expression. Orange-tinted hoodie."
    - `char_claude_waiting`: "Pixel art character tapping foot, drumming fingers on desk, impatient posture. Orange-tinted hoodie."
    - `char_claude_error`: "Pixel art character in facepalm pose, hands on head, frustrated expression, slight recoil. Orange-tinted hoodie."
    - `char_claude_finished`: "Pixel art character standing up from desk, stretching arms above head, satisfied expression. Orange-tinted hoodie."
- **Verify**: All 9 descriptions are in the manifest with type "character" and aspect ratio "1:1".

### 5.4 Write character sprite prompts — Codex agent (9 states)
- **What**: Same as 5.3 but for Codex/OpenAI agent.
- **Differences**: Blue-tinted character (OpenAI brand association). Same 9 poses but with blue hoodie/shirt instead of orange.
- **Verify**: All 9 Codex character descriptions in manifest.

### 5.5 Write furniture sprite prompts
- **What**: Write descriptions for office furniture.
- **Assets**:
  - `furniture_desk`: "Pixel art wooden office desk, 3/4 top-down view, warm brown wood (#8B6544), with darker accents. 32x32 pixels."
  - `furniture_chair`: "Pixel art rolling office chair, 3/4 top-down view, dark metal frame (#5A6670), gray cushion. 32x32 pixels."
  - `furniture_monitor_on`: "Pixel art computer monitor on desk, screen glowing soft blue (#7BA3C4), 3/4 view. 32x32 pixels."
  - `furniture_monitor_off`: "Pixel art computer monitor on desk, screen dark/powered off, 3/4 view. 32x32 pixels."
  - `furniture_monitor_green`: "Same monitor but screen glowing green (#50C878) — agent is writing code."
  - `furniture_monitor_red`: "Same monitor but screen glowing red (#E05050) — agent has error."
  - `furniture_monitor_amber`: "Same monitor but screen glowing amber (#E89040) — agent running command."
- **Verify**: All 7 furniture descriptions in manifest.

### 5.6 Write decoration and ambient sprite prompts
- **What**: Write descriptions for office decorations.
- **Assets**:
  - `decor_plant_1`: "Pixel art small potted plant on desk, green leaves (#6B8F4E), terracotta pot. 16x16 pixels."
  - `decor_plant_2`: "Pixel art tall floor plant in white pot, broader leaves, slightly different shade of green. 32x32 pixels."
  - `decor_coffee_mug`: "Pixel art coffee mug on desk, ceramic white with small handle, dark liquid visible. 16x16 pixels."
  - `decor_clock`: "Pixel art round wall clock, white face, black numbers, red second hand. 16x16 pixels."
  - `decor_window`: "Pixel art office window, warm daylight streaming in, simple white frame, blue sky with clouds visible. 32x32 pixels."
  - `decor_whiteboard`: "Pixel art whiteboard on wall, white surface with faint marker scribbles, silver frame. 32x32 pixels."
  - `decor_lamp`: "Pixel art desk lamp, warm orange light (#D4956A), adjustable arm, metal base. 16x16 pixels."
- **Verify**: All 7 decoration descriptions in manifest.

### 5.7 Write tile prompts
- **What**: Write descriptions for floor and wall tiles.
- **Assets**:
  - `tile_floor_wood`: "Pixel art wooden floor tile, seamless, warm tan (#C4B6A0) with darker grain lines (#A89882). 16x16 pixels."
  - `tile_wall`: "Pixel art office wall tile, seamless, warm off-white (#EAE6DF) with subtle texture. 16x16 pixels."
- **Verify**: Both tile descriptions in manifest.

### 5.8 Write office cat sprite prompts
- **What**: Write descriptions for the office cat NPC.
- **Assets**:
  - `cat_idle`: "Pixel art small orange tabby cat sitting on floor, 3/4 top-down view, tail curled, eyes open, content expression. 32x32 pixels."
  - `cat_walk_1`: "Pixel art small orange tabby cat walking, left paw forward, 3/4 top-down view. 32x32 pixels."
  - `cat_walk_2`: "Pixel art small orange tabby cat walking, right paw forward, 3/4 top-down view. 32x32 pixels."
  - `cat_sleep`: "Pixel art small orange tabby cat curled up sleeping, 3/4 top-down view, eyes closed, peaceful. 32x32 pixels."
- **Verify**: All 4 cat descriptions in manifest.

### 5.9 Run batch generation and save to Assets/
- **What**: Execute the batch command to generate all assets.
- **Behavior**:
  - `cd tools/assetgen && pnpm tsx src/index.ts batch -o ../../Assets/sprites/`
  - Creates `Assets/sprites/` directory with all PNGs
  - Creates `Assets/sprites/*.meta.json` sidecars
  - Total: ~38 assets (18 characters + 7 furniture + 7 decorations + 2 tiles + 4 cat)
- **Human step**: Review generated images. Re-run specific assets with tweaked prompts if quality is off.

### 5.10 Implement a `preview` command (optional but helpful)
- **What**: CLI command that generates a single asset and opens it in Preview.app for quick review.
- **Behavior**: `pnpm tsx src/index.ts preview -t character -d "..." -n test` → generates PNG → `open test.png`
- **Why**: Speeds up prompt iteration cycle for the human reviewer.
- **Verify**: Running preview opens the generated image.

### 5.11 Create texture atlas organization
- **What**: Organize generated PNGs into the directory structure expected by SpriteKit.
- **Structure**:
  ```
  Assets/
  ├── sprites/
  │   ├── characters/
  │   │   ├── claude/     (9 state PNGs)
  │   │   └── codex/      (9 state PNGs)
  │   ├── furniture/      (7 PNGs)
  │   ├── decorations/    (7 PNGs)
  │   ├── tiles/          (2 PNGs)
  │   └── cat/            (4 PNGs)
  └── atlases/            (generated texture atlases — Milestone 6)
  ```
- **Verify**: All PNGs are in the correct subdirectory. No PNGs missing from the manifest.

### 5.12 Verify all assets generated and organized
- **What**: Count all PNGs in `Assets/sprites/`. Verify count matches manifest. Verify all files are valid PNGs (non-zero size, valid header).
- **Milestone gate**: All pixel art assets are generated and organized. Ready for integration in Milestone 6.

---

## Parallelism

The following tasks can be done in parallel:
- **[5.3, 5.4, 5.5, 5.6, 5.7, 5.8]** — All prompt writing tasks are independent
- **5.1 and 5.2** must be done before 5.9
- **5.9** depends on 5.1–5.8 (needs generate command and all prompts)
- **5.10** is optional, can be done anytime after 5.1
- **5.11** depends on 5.9 (needs generated files to organize)
- **5.12** depends on 5.11

**This entire milestone can run in parallel with Milestones 2, 3, and 4** since it only depends on Milestone 1.
