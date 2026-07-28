import { execFileSync, spawnSync } from "node:child_process";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  symlinkSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

import {
  deriveDevelopmentConfig,
  installDevelopmentBundleConfig,
  resolveDevelopmentAction,
} from "./velox-profile-config.mjs";

const scriptDirectory = dirname(fileURLToPath(import.meta.url));
const desktopRoot = join(scriptDirectory, "..");
const veloxRoot = join(desktopRoot, "desktop-velox");
const canonicalConfigPath = join(veloxRoot, "velox.json");
const profileRoot = join(
  veloxRoot,
  ".build",
  "velox-profile",
  "development",
);
const profileConfigPath = join(profileRoot, "velox.json");
const profileSourcesPath = join(profileRoot, "Sources");
const veloxCLI = join(
  veloxRoot,
  ".build",
  "checkouts",
  "velox",
  ".build",
  "debug",
  "velox",
);
const developmentBundle = join(
  veloxRoot,
  ".build",
  "debug",
  "Cleaning Dev.app",
);

const action = resolveDevelopmentAction(process.argv[2] ?? "");
const production = JSON.parse(readFileSync(canonicalConfigPath, "utf8"));
const development = deriveDevelopmentConfig(production);

mkdirSync(profileRoot, { recursive: true });
writeFileSync(profileConfigPath, `${JSON.stringify(development, null, 2)}\n`);

if (!existsSync(profileSourcesPath)) {
  symlinkSync(
    relative(profileRoot, join(veloxRoot, "Sources")),
    profileSourcesPath,
    "dir",
  );
}

if (!existsSync(veloxCLI)) {
  throw new Error(
    `缺少 Velox CLI: ${veloxCLI}\n先运行 pnpm run velox:cli:build`,
  );
}

const result = spawnSync(veloxCLI, action.args, {
  cwd: profileRoot,
  env: {
    ...process.env,
    CLEANING_BUNDLE_IDENTIFIER: development.identifier,
    ...(action.bundle ? { VELOX_BUNDLE_CONFIGURATION: "debug" } : {}),
  },
  stdio: "inherit",
});

if (result.error) {
  throw result.error;
}
if (result.status !== 0) {
  process.exit(result.status ?? 1);
}

if (action.bundle) {
  if (!existsSync(developmentBundle)) {
    throw new Error(`Velox 未生成 ${developmentBundle}`);
  }
  installDevelopmentBundleConfig(developmentBundle, development);
  execFileSync("/usr/bin/codesign", [
    "--force",
    "--sign",
    "-",
    developmentBundle,
  ], {
    stdio: "inherit",
  });
  execFileSync("/usr/bin/codesign", [
    "--verify",
    "--deep",
    "--strict",
    "--verbose=2",
    developmentBundle,
  ], {
    stdio: "inherit",
  });
  console.log(`velox-profile: 已生成 ${developmentBundle}`);
}
