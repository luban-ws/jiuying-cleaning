import assert from "node:assert/strict";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import {
  deriveDevelopmentConfig,
  installDevelopmentBundleConfig,
  resolveDevelopmentAction,
} from "./velox-profile-config.mjs";

test("derives isolated Development identity without mutating Production config", () => {
  const production = {
    productName: "Cleaning",
    identifier: "me.systembug.cleaning",
    app: {
      windows: [
        { label: "main", title: "Cleaning" },
        { label: "secondary", title: "Secondary" },
      ],
    },
    build: {
      beforeDevCommand: "cd .. && pnpm exec vite",
      beforeBuildCommand: "cd .. && pnpm exec vite build",
      beforeBundleCommand: "cd .. && node scripts/velox-ffi.mjs prepare-bundle",
    },
  };

  const development = deriveDevelopmentConfig(production);

  assert.equal(development.productName, "Cleaning Dev");
  assert.equal(development.identifier, "me.systembug.cleaning.dev");
  assert.equal(development.app.windows[0].title, "Cleaning Dev");
  assert.equal(development.app.windows[1].title, "Secondary");
  assert.equal(
    development.build.beforeDevCommand,
    "cd ../../../.. && pnpm exec vite",
  );
  assert.equal(
    development.build.beforeBuildCommand,
    "cd ../../../.. && pnpm exec vite build",
  );
  assert.equal(
    development.build.beforeBundleCommand,
    "cd ../../../.. && node scripts/velox-ffi.mjs prepare-bundle",
  );

  assert.equal(production.productName, "Cleaning");
  assert.equal(production.identifier, "me.systembug.cleaning");
  assert.equal(production.app.windows[0].title, "Cleaning");
  assert.equal(production.build.beforeDevCommand, "cd .. && pnpm exec vite");
});

test("maps Development commands to official Velox CLI arguments", () => {
  assert.deepEqual(resolveDevelopmentAction("build:app"), {
    args: ["build", "--debug", "--bundle"],
    bundle: true,
  });
  assert.throws(
    () => resolveDevelopmentAction("release"),
    /不支持 Development 动作: release/,
  );
});

test("keeps the Velox main window usable at the approved compact size", () => {
  const config = JSON.parse(
    readFileSync(new URL("../desktop-velox/velox.json", import.meta.url), "utf8"),
  );
  const mainWindow = config.app.windows.find((window) => window.label === "main");

  assert.equal(mainWindow.minWidth, 840);
  assert.equal(mainWindow.minHeight, 700);
});

test("installs actual Development config into generated app bundle", () => {
  const temporaryRoot = mkdtempSync(join(tmpdir(), "cleaning-dev-bundle-"));
  const bundlePath = join(temporaryRoot, "Cleaning Dev.app");
  const resourcesPath = join(bundlePath, "Contents", "Resources");
  const bundledConfigPath = join(resourcesPath, "velox.json");
  const development = {
    productName: "Cleaning Dev",
    identifier: "me.systembug.cleaning.dev",
  };

  try {
    mkdirSync(resourcesPath, { recursive: true });
    writeFileSync(
      bundledConfigPath,
      JSON.stringify({
        productName: "Cleaning",
        identifier: "me.systembug.cleaning",
      }),
    );

    installDevelopmentBundleConfig(bundlePath, development);

    assert.deepEqual(
      JSON.parse(readFileSync(bundledConfigPath, "utf8")),
      development,
    );
  } finally {
    rmSync(temporaryRoot, { recursive: true, force: true });
  }
});
