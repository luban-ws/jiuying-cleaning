import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { RulesCommandBar } from "./RulesCommandBar";
import type { RulesWorkspaceState } from "./useRulesWorkspace";

describe("RulesCommandBar", () => {
  it("does not duplicate scan progress owned by the top activity banner", () => {
    const ws = {
      busy: false,
      isScanning: true,
      isCleaning: false,
      selectedRuleIds: new Set<string>(),
      analyzedSelectedCount: 0,
      performance: false,
      selectedProcessCount: 0,
      selectedRecoverableBytes: 0,
      rules: [{ id: "a" }],
      scanActivity: { kind: "scanning", current: 2, total: 4 },
      scanProgress: { current: 2, total: 4 },
      scanAll: () => undefined,
      setPreviewOpen: () => undefined,
      openCleanConfirm: () => undefined,
    } as unknown as RulesWorkspaceState;

    const html = renderToStaticMarkup(
      <RulesCommandBar ws={ws} t={(key) => key} />,
    );

    expect(html).toContain("rules.scanning");
    expect(html).not.toContain("(2/4)");
  });
});
