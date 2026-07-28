import { execFileSync } from "node:child_process";
import { copyFileSync, existsSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const veloxRoot = join(scriptDirectory, "..", "desktop-velox");
const libraryName = "libvelox_runtime_wry_ffi.dylib";
const bundledReference = `@executable_path/../Resources/${libraryName}`;

function paths(configuration) {
  return {
    executable: join(
      veloxRoot,
      ".build",
      configuration,
      "CleanSpaceDesktop",
    ),
    sourceLibrary: join(
      veloxRoot,
      ".build/plugins/outputs/velox/VeloxRuntimeWryFFI/destination/VeloxRustBuildPlugin/Artifacts/cargo-target",
      configuration,
      "deps",
      libraryName,
    ),
  };
}

function linkedLibrary(executable) {
  const dependencies = execFileSync("/usr/bin/otool", ["-L", executable], {
    encoding: "utf8",
  });
  const reference = dependencies
    .split("\n")
    .map((line) => line.trim())
    .find((line) => line.includes(libraryName))
    ?.split(" (compatibility version")[0];

  if (!reference) {
    throw new Error(`velox-ffi: ${executable} 未链接 ${libraryName}`);
  }
  return reference;
}

function relink(executable, currentReference, nextReference) {
  if (currentReference === nextReference) {
    return false;
  }
  execFileSync("/usr/bin/install_name_tool", [
    "-change",
    currentReference,
    nextReference,
    executable,
  ]);
  return true;
}

function sign(path) {
  execFileSync("/usr/bin/codesign", ["--force", "--sign", "-", path], {
    stdio: "inherit",
  });
}

function restoreDevelopmentExecutable() {
  const { executable, sourceLibrary } = paths("debug");
  if (!existsSync(executable)) {
    return;
  }
  if (!existsSync(sourceLibrary)) {
    throw new Error(`velox-ffi: 缺少 ${sourceLibrary}`);
  }
  if (relink(executable, linkedLibrary(executable), sourceLibrary)) {
    sign(executable);
    console.log(`velox-ffi: 已恢复开发链接 ${libraryName}`);
  }
}

function prepareBundle() {
  const configuration = process.env.VELOX_BUNDLE_CONFIGURATION;
  if (configuration !== "debug" && configuration !== "release") {
    throw new Error(
      "velox-ffi: VELOX_BUNDLE_CONFIGURATION 必须为 debug 或 release",
    );
  }

  const { executable, sourceLibrary } = paths(configuration);
  const stagedLibrary = join(
    veloxRoot,
    ".build",
    "velox-bundle",
    libraryName,
  );
  for (const requiredPath of [executable, sourceLibrary]) {
    if (!existsSync(requiredPath)) {
      throw new Error(`velox-ffi: 缺少 ${requiredPath}`);
    }
  }

  mkdirSync(dirname(stagedLibrary), { recursive: true });
  copyFileSync(sourceLibrary, stagedLibrary);
  relink(executable, linkedLibrary(executable), bundledReference);
  sign(stagedLibrary);
  sign(executable);
  console.log(`velox-ffi: ${libraryName} 已准备给 Velox Bundler`);
}

switch (process.argv[2]) {
  case "restore-dev":
    restoreDevelopmentExecutable();
    break;
  case "prepare-bundle":
    prepareBundle();
    break;
  default:
    throw new Error(`velox-ffi: 不支持动作 ${process.argv[2] ?? ""}`);
}
