import path from "node:path";
import { mkdir, writeFile, access } from "node:fs/promises";
import { generateImage } from "ai";
import { gateway } from "@ai-sdk/gateway";
import { ART_BIBLE, TYPE_HINTS } from "./config.js";
import { writeMetadata, type AssetMetadata } from "./metadata.js";

/** Options accepted by generateAsset(). */
export interface GenerateOptions {
  name: string;
  type: string;
  description: string;
  aspectRatio?: string;
  model?: string;
  outputDir?: string;
  force?: boolean;
  subdir?: string;
}

/** Result returned after generating an asset. */
export interface GenerateResult {
  success: boolean;
  outputPath?: string;
  skipped?: boolean;
  error?: string;
}

const DEFAULT_MODEL = "bfl/flux-kontext-max";

/**
 * Generate a single pixel-art asset using the Vercel AI Gateway.
 */
export async function generateAsset(
  options: GenerateOptions,
): Promise<GenerateResult> {
  const {
    name,
    type,
    description,
    aspectRatio = "1:1",
    model = DEFAULT_MODEL,
    outputDir = "output",
    force = false,
    subdir,
  } = options;

  // Build the full prompt from art bible + type hint + description.
  const typeHint = TYPE_HINTS[type] ?? "";
  const fullPrompt = [ART_BIBLE, typeHint, description]
    .filter(Boolean)
    .join("\n\n");

  // Determine output path
  const resolvedDir = subdir ? path.join(outputDir, subdir) : outputDir;
  const outputPath = path.join(resolvedDir, `${name}.png`);

  // Skip if output already exists (unless --force)
  if (!force) {
    try {
      await access(outputPath);
      return { success: true, outputPath, skipped: true };
    } catch {
      // File doesn't exist, proceed with generation
    }
  }

  try {
    await mkdir(resolvedDir, { recursive: true });

    const result = await generateImage({
      model: gateway.image(model),
      prompt: fullPrompt,
      aspectRatio: aspectRatio as `${number}:${number}`,
    });

    // Write image data from the result
    if (result.image) {
      const imageData = Buffer.from(result.image.uint8Array);
      await writeFile(outputPath, imageData);
    } else {
      return { success: false, error: "No image data in response" };
    }

    // Write sidecar metadata
    const metadata: AssetMetadata = {
      name,
      type,
      prompt: fullPrompt,
      model,
      timestamp: new Date().toISOString(),
      dimensions: { width: 0, height: 0 }, // populated by consumer if needed
    };

    await writeMetadata(outputPath, metadata);

    return { success: true, outputPath };
  } catch (error: any) {
    return { success: false, error: error.message || String(error) };
  }
}
