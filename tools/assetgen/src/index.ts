#!/usr/bin/env node
import "dotenv/config";
import { Command } from "commander";
import { generateAsset } from "./generate.js";
import { BULLPEN_ASSETS, TYPE_HINTS } from "./config.js";

const program = new Command();

program
  .name("bullpen-assetgen")
  .description("Pixel art asset generator for Bullpen using Vercel AI Gateway")
  .version("0.1.0");

// ── generate ────────────────────────────────────────────────────────
program
  .command("generate")
  .description("Generate a single pixel art asset")
  .requiredOption("-n, --name <name>", "Asset name (e.g. char_claude_idle)")
  .option(
    "-t, --type <type>",
    `Asset type (${Object.keys(TYPE_HINTS).join(", ")})`,
  )
  .option("-d, --description <desc>", "Generation prompt / description")
  .action(async (opts: { name: string; type?: string; description?: string }) => {
    // If name matches a manifest entry, fill in defaults from there.
    const entry = BULLPEN_ASSETS.find((a) => a.name === opts.name);
    const type = opts.type ?? entry?.type;
    const description = opts.description ?? entry?.description;

    if (!type) {
      console.error(
        `Error: --type is required (or use a name from the manifest).`,
      );
      process.exit(1);
    }
    if (!description) {
      console.error(
        `Error: --description is required (or use a name from the manifest).`,
      );
      process.exit(1);
    }

    const result = await generateAsset({
      name: opts.name,
      type,
      description,
      aspectRatio: entry?.aspectRatio,
    });

    console.log(
      result.stubbed
        ? "Asset stubbed successfully."
        : `Asset generated: ${result.outputPath}`,
    );
  });

// ── batch ───────────────────────────────────────────────────────────
program
  .command("batch")
  .description("Generate assets in bulk from the built-in manifest")
  .option("-a, --all", "Generate all assets in the manifest")
  .option(
    "-t, --type <type>",
    "Generate only assets of this type (character, furniture, etc.)",
  )
  .action(async (opts: { all?: boolean; type?: string }) => {
    let assets = BULLPEN_ASSETS;

    if (opts.type) {
      assets = assets.filter((a) => a.type === opts.type);
    } else if (!opts.all) {
      console.error("Error: specify --all or --type <type>.");
      process.exit(1);
    }

    console.log(`Generating ${assets.length} assets...\n`);

    for (const entry of assets) {
      await generateAsset({
        name: entry.name,
        type: entry.type,
        description: entry.description,
        aspectRatio: entry.aspectRatio,
      });
    }

    console.log(`\nBatch complete: ${assets.length} assets processed.`);
  });

program.parse();
