import { execFileSync } from "node:child_process";
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  rmSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const designDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(designDir, "..");
const sourcePng = join(designDir, "icon.png");
const sourceSvg = join(designDir, "icon.svg");
const kitCatalog = join(
  repoRoot,
  "apps/desktop/desktop-velox/Sources/CleanSpaceKit/Resources/Assets.xcassets/AppIcon.appiconset",
);
const veloxCatalog = join(
  repoRoot,
  "apps/desktop/desktop-velox/Sources/CleanSpaceDesktop/Resources/Assets.xcassets/AppIcon.appiconset",
);
const kitPng = join(kitCatalog, "AppIcon-1024.png");
const veloxPng = join(veloxCatalog, "AppIcon-1024.png");
const reactPng = join(repoRoot, "apps/desktop/src/assets/logo.png");
const veloxIcns = join(
  repoRoot,
  "apps/desktop/desktop-velox/Sources/CleanSpaceDesktop/Resources/AppIcon.icns",
);
const sips = "/usr/bin/sips";
const xcrun = "/usr/bin/xcrun";

function run(command, args, options = {}) {
  return execFileSync(command, args, {
    encoding: "utf8",
    stdio: ["ignore", "pipe", "inherit"],
    ...options,
  });
}

function findRsvgConvert() {
  return [
    "/opt/homebrew/bin/rsvg-convert",
    "/usr/local/bin/rsvg-convert",
  ].find(existsSync);
}

for (const directory of [kitCatalog, veloxCatalog, dirname(reactPng)]) {
  mkdirSync(directory, { recursive: true });
}

if (existsSync(sourcePng)) {
  const format = run(sips, ["-g", "format", sourcePng])
    .match(/format:\s*(\S+)/)?.[1];
  if (format !== "png") {
    throw new Error(`design: icon.png 实际编码为 ${format ?? "未知"}，必须为 png`);
  }
  copyFileSync(sourcePng, kitPng);
} else {
  const rsvgConvert = findRsvgConvert();
  if (!existsSync(sourceSvg)) {
    throw new Error("design: 缺少 icon.png 与 icon.svg");
  }
  if (!rsvgConvert) {
    throw new Error("design: 未找到 rsvg-convert，无法从 icon.svg 生成 PNG");
  }
  run(rsvgConvert, ["-w", "1024", "-h", "1024", "-o", kitPng, sourceSvg]);
}

copyFileSync(kitPng, veloxPng);
copyFileSync(kitPng, reactPng);

const entries = [
  [16, "icon_16x16.png"],
  [32, "icon_16x16@2x.png"],
  [32, "icon_32x32.png"],
  [64, "icon_32x32@2x.png"],
  [128, "icon_128x128.png"],
  [256, "icon_128x128@2x.png"],
  [256, "icon_256x256.png"],
  [512, "icon_256x256@2x.png"],
  [512, "icon_512x512.png"],
  [1024, "icon_512x512@2x.png"],
];

for (const [size, filename] of entries) {
  const kitOutput = join(kitCatalog, filename);
  run(sips, [
    "-s",
    "format",
    "png",
    "-z",
    String(size),
    String(size),
    kitPng,
    "--out",
    kitOutput,
  ]);
  copyFileSync(kitOutput, join(veloxCatalog, filename));
}

const actoolOutput = mkdtempSync(join(tmpdir(), "cleanspace-actool-"));
try {
  run(xcrun, [
    "actool",
    "--compile",
    actoolOutput,
    "--platform",
    "macosx",
    "--minimum-deployment-target",
    "15.0",
    "--app-icon",
    "AppIcon",
    "--output-partial-info-plist",
    join(actoolOutput, "partial-info.plist"),
    join(
      repoRoot,
      "apps/desktop/desktop-velox/Sources/CleanSpaceKit/Resources/Assets.xcassets",
    ),
  ]);
  const generatedIcns = join(actoolOutput, "AppIcon.icns");
  if (!existsSync(generatedIcns)) {
    throw new Error("design: actool 未生成 AppIcon.icns");
  }
  copyFileSync(generatedIcns, veloxIcns);
} finally {
  rmSync(actoolOutput, { recursive: true, force: true });
}

run(process.execPath, [join(repoRoot, "scripts/check-app-icon-sync.mjs")], {
  stdio: "inherit",
});
console.log("design: React 与 Velox 图标已生成");
