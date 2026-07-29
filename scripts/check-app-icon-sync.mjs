import { execFileSync } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(scriptDir, "..");
const sourceIcon = join(repoRoot, "design/icon.png");
const reactPng = join(repoRoot, "apps/desktop/src/assets/logo.png");
const veloxPng = join(
  repoRoot,
  "apps/desktop/desktop-velox/Sources/CleanSpaceDesktop/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png",
);
const veloxIcns = join(
  repoRoot,
  "apps/desktop/desktop-velox/Sources/CleanSpaceDesktop/Resources/AppIcon.icns",
);

function formatOf(path) {
  const output = execFileSync("/usr/bin/sips", ["-g", "format", path], {
    encoding: "utf8",
  });
  return output.match(/format:\s*(\S+)/)?.[1];
}

function sha256(path) {
  return createHash("sha256").update(readFileSync(path)).digest("hex");
}

for (const icon of [sourceIcon, reactPng, veloxPng]) {
  const format = formatOf(icon);
  if (format !== "png") {
    throw new Error(`icon-check: ${icon} 编码为 ${format ?? "未知"}，必须为 png`);
  }
}

const sourceHash = sha256(sourceIcon);
for (const icon of [reactPng, veloxPng]) {
  if (sha256(icon) !== sourceHash) {
    throw new Error(`icon-check: ${icon} 未与 design/icon.png 同步`);
  }
}

if (!existsSync(veloxIcns)) {
  throw new Error("icon-check: Velox AppIcon.icns 缺失");
}

console.log("icon-check: React 与 Velox 图标已同步");
