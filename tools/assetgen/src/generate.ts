import path from "node:path";
import { mkdir, writeFile } from "node:fs/promises";
import { ART_BIBLE, TYPE_HINTS } from "./config.js";
import { writeMetadata, type AssetMetadata } from "./metadata.js";

/** Options accepted by generateAsset(). */
export interface GenerateOptions {
  name: string;
  type: string;
  description: string;
  aspectRatio?: string;
}

/** Result returned after generating (or stubbing) an asset. */
export interface GenerateResult {
  outputPath: string;
  metadataPath: string;
  stubbed: boolean;
}

const MODEL_ID = "bfl/flux-kontext-max";

/**
 * Generate a single pixel-art asset using the Vercel AI Gateway.
 *
 * Currently stubbed — logs what it *would* do and writes a placeholder PNG.
 * Once an API key is configured, replace the stub with real generation calls:
 *
 * ```ts
 * import { gateway } from "@ai-sdk/gateway";
 * import { generateImage } from "ai";
 * const result = await generateImage({
 *   model: gateway("bfl/flux-kontext-max"),
 *   prompt: fullPrompt,
 *   aspectRatio: options.aspectRatio,
 * });
 * ```
 */
export async function generateAsset(
  options: GenerateOptions,
): Promise<GenerateResult> {
  const { name, type, description, aspectRatio } = options;

  // Build the full prompt from art bible + type hint + description.
  const typeHint = TYPE_HINTS[type] ?? "";
  const fullPrompt = [ART_BIBLE, typeHint, description]
    .filter(Boolean)
    .join("\n\n");

  // Determine output path relative to the project root.
  const projectRoot = path.resolve(import.meta.dirname, "../../../..");
  const outputDir = path.join(projectRoot, "Assets", "Generated", type);
  const outputPath = path.join(outputDir, `${name}.png`);

  console.log(`\nGenerating asset: ${name}`);
  console.log(`  Type:   ${type}`);
  console.log(`  Ratio:  ${aspectRatio ?? "auto"}`);
  console.log(`  Output: ${path.relative(process.cwd(), outputPath)}`);
  console.log(`  Prompt: ${fullPrompt.slice(0, 120)}...`);

  // ── Stub: write a tiny 1x1 transparent PNG placeholder ────────────
  // TODO: Replace with real AI generation once API key is available.
  console.log("  [STUB] Skipping actual generation — no API key configured.");

  await mkdir(outputDir, { recursive: true });

  // Minimal valid 1x1 transparent PNG (67 bytes).
  const placeholderPng = Buffer.from(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "base64",
  );
  await writeFile(outputPath, placeholderPng);

  // ── Write sidecar metadata ────────────────────────────────────────
  const metadata: AssetMetadata = {
    name,
    type,
    prompt: fullPrompt,
    model: MODEL_ID,
    timestamp: new Date().toISOString(),
    dimensions: { width: 1, height: 1 }, // placeholder
  };

  await writeMetadata(outputPath, metadata);

  const metadataPath = `${outputPath}.meta.json`;
  console.log("  Done (stub).\n");

  return { outputPath, metadataPath, stubbed: true };
}
