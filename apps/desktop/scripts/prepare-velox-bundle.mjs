import { execFileSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDir = dirname(fileURLToPath(import.meta.url));
const desktopRoot = join(scriptDir, "..");
const veloxRoot = join(desktopRoot, "desktop-velox");
const configuration = process.env.VELOX_BUNDLE_CONFIGURATION;
const libraryName = "libvelox_runtime_wry_ffi.dylib";
const bundledReference = `@executable_path/../Resources/${libraryName}`;

if (configuration !== "debug" && configuration !== "release") {
  throw new Error("bundle-ffi: VELOX_BUNDLE_CONFIGURATION 必须为 debug 或 release");
}

const executable = join(
  veloxRoot,
  ".build",
  configuration,
  "CleanSpaceDesktop",
);
const sourceLibrary = join(
  veloxRoot,
  ".build/plugins/outputs/velox/VeloxRuntimeWryFFI/destination/VeloxRustBuildPlugin/Artifacts/cargo-target",
  configuration,
  "deps",
  libraryName,
);
const stagedLibrary = join(
  veloxRoot,
  ".build/velox-bundle",
  libraryName,
);

for (const requiredPath of [executable, sourceLibrary]) {
  if (!existsSync(requiredPath)) {
    throw new Error(`bundle-ffi: 缺少 ${requiredPath}`);
  }
}

const dependencies = execFileSync("/usr/bin/otool", ["-L", executable], {
  encoding: "utf8",
});
const currentReference = dependencies
  .split("\n")
  .map((line) => line.trim())
  .find((line) => line.includes(libraryName))
  ?.split(" (compatibility version")[0];

if (!currentReference) {
  throw new Error(`bundle-ffi: ${executable} 未链接 ${libraryName}`);
}

mkdirSync(dirname(stagedLibrary), { recursive: true });
copyFileSync(sourceLibrary, stagedLibrary);

if (currentReference !== bundledReference) {
  execFileSync("/usr/bin/install_name_tool", [
    "-change",
    currentReference,
    bundledReference,
    executable,
  ]);
}

for (const path of [stagedLibrary, executable]) {
  execFileSync("/usr/bin/codesign", ["--force", "--sign", "-", path], {
    stdio: "inherit",
  });
}

console.log(`bundle-ffi: ${libraryName} 已准备给 Velox Bundler`);
