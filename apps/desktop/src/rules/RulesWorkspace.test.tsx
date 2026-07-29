import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it, vi } from "vitest";

vi.mock("../i18n/useI18n", () => ({
  useI18n: () => ({
    t: (key: string) => key,
    cat: (category: string) => category,
  }),
}));

vi.mock("./useRulesWorkspace", () => ({
  useRulesWorkspace: () => ({
    performance: false,
    rules: [],
    selectedRuleIds: new Set<string>(),
    scannedMetricCount: 0,
    showFdaBanner: false,
    fdaDismissed: false,
    deniedPaths: [],
    setFdaDismissed: () => undefined,
    loading: false,
    error: "",
    scanActivity: {
      kind: "scanning",
      current: 1,
      total: 3,
      ruleId: "browser-cache",
    },
    dismissScanActivity: () => undefined,
    previewOpen: false,
    setPreviewOpen: () => undefined,
    confirm: null,
    cleanResult: null,
  }),
}));

import { RulesWorkspace } from "./RulesWorkspace";

describe("RulesWorkspace", () => {
  it("places scan activity directly below the title area and before workspace content", () => {
    const html = renderToStaticMarkup(<RulesWorkspace scope="rules" />);
    const title = html.indexOf("nav.rules");
    const activity = html.indexOf("rules-activity");
    const content = html.indexOf("rules-workspace-content");

    expect(title).toBeGreaterThanOrEqual(0);
    expect(activity).toBeGreaterThan(title);
    expect(content).toBeGreaterThan(activity);
  });
});
