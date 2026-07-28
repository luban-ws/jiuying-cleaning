import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";

const canonicalHookPrefix = "cd .. && ";
const profileHookPrefix = "cd ../../../.. && ";

export function deriveDevelopmentConfig(production) {
  const development = structuredClone(production);

  development.productName = "Cleaning Dev";
  development.identifier = "me.systembug.cleaning.dev";
  development.app.windows = development.app.windows.map((window) =>
    window.label === "main" ? { ...window, title: "Cleaning Dev" } : window,
  );

  for (const key of [
    "beforeDevCommand",
    "beforeBuildCommand",
    "beforeBundleCommand",
  ]) {
    const command = development.build?.[key];
    if (command?.startsWith(canonicalHookPrefix)) {
      development.build[key] =
        profileHookPrefix + command.slice(canonicalHookPrefix.length);
    }
  }

  return development;
}

export function resolveDevelopmentAction(action) {
  switch (action) {
    case "build:app":
      return { args: ["build", "--debug", "--bundle"], bundle: true };
    default:
      throw new Error(`不支持 Development 动作: ${action}`);
  }
}

export function installDevelopmentBundleConfig(bundlePath, development) {
  const bundledConfigPath = join(bundlePath, "Contents", "Resources", "velox.json");
  mkdirSync(dirname(bundledConfigPath), { recursive: true });
  writeFileSync(bundledConfigPath, `${JSON.stringify(development, null, 2)}\n`);
}
