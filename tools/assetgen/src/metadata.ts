import { writeFile } from "node:fs/promises";
import path from "node:path";

/** Metadata sidecar for a generated asset. */
export interface AssetMetadata {
  name: string;
  type: string;
  prompt: string;
  model: string;
  timestamp: string;
  dimensions: { width: number; height: number };
}

/**
 * Write a `.meta.json` sidecar file next to the generated asset.
 *
 * For example, given `Assets/Generated/character/char_claude_idle.png`,
 * this writes `Assets/Generated/character/char_claude_idle.png.meta.json`.
 */
export async function writeMetadata(
  assetPath: string,
  metadata: AssetMetadata,
): Promise<void> {
  const metaPath = `${assetPath}.meta.json`;
  const content = JSON.stringify(metadata, null, 2) + "\n";
  await writeFile(metaPath, content, "utf-8");
  console.log(`  Metadata written to ${path.relative(process.cwd(), metaPath)}`);
}
