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
  .option("-o, --output <dir>", "Output directory", "output")
  .option("-f, --force", "Regenerate even if file exists")
  .action(async (opts: { name: string; type?: string; description?: string; output: string; force?: boolean }) => {
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
      outputDir: opts.output,
      force: opts.force,
      subdir: entry?.subdir,
    });

    if (result.skipped) {
      console.log(`Skipped (already exists): ${result.outputPath}`);
    } else if (result.success) {
      console.log(`Asset generated: ${result.outputPath}`);
    } else {
      console.error(`Error: ${result.error}`);
      process.exit(1);
    }
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
  .option("-o, --output <dir>", "Output directory", "output")
  .option("-f, --force", "Regenerate even if files exist")
  .action(async (opts: { all?: boolean; type?: string; output: string; force?: boolean }) => {
    let assets = BULLPEN_ASSETS;

    if (opts.type) {
      assets = assets.filter((a) => a.type === opts.type);
    } else if (!opts.all) {
      // Default to all if no filter specified
      assets = BULLPEN_ASSETS;
    }

    const total = assets.length;
    let generated = 0;
    let skipped = 0;
    let failed = 0;

    console.log(`Generating ${total} assets to ${opts.output}...\n`);

    for (let i = 0; i < assets.length; i++) {
      const entry = assets[i];
      const idx = i + 1;
      console.log(`[${idx}/${total}] Generating ${entry.name}...`);

      const result = await generateAsset({
        name: entry.name,
        type: entry.type,
        description: entry.description,
        aspectRatio: entry.aspectRatio,
        outputDir: opts.output,
        force: opts.force,
        subdir: entry.subdir,
      });

      if (result.skipped) {
        console.log(`  Skipped (already exists): ${result.outputPath}`);
        skipped++;
      } else if (result.success) {
        console.log(`  Generated: ${result.outputPath}`);
        generated++;
      } else {
        console.error(`  FAILED: ${result.error}`);
        failed++;
      }
    }

    console.log(`\n--- Batch Summary ---`);
    console.log(`  Generated: ${generated}`);
    console.log(`  Skipped:   ${skipped}`);
    console.log(`  Failed:    ${failed}`);
    console.log(`  Total:     ${total}`);
  });

program.parse();
