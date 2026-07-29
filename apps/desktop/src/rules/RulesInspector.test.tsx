import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { RulesInspector } from "./RulesInspector";
import type { RulesWorkspaceState } from "./useRulesWorkspace";

describe("RulesInspector", () => {
  it("exposes Details and Distribution without moving them below the table", () => {
    const ws = {
      focusedRule: null,
      performance: false,
      inspectorOpen: true,
      setInspectorOpen: () => undefined,
      selectedRuleIds: new Set<string>(),
      toggleSelected: () => undefined,
      rules: [],
      sizes: {},
      processCounts: {},
      hasDirScanResults: false,
    } as unknown as RulesWorkspaceState;

    const html = renderToStaticMarkup(
      <RulesInspector
        ws={ws}
        t={(key) => key}
        cat={(category) => category}
        preview={null}
      />,
    );

    expect(html).toContain("rules.inspector.details_tab");
    expect(html).toContain("rules.inspector.distribution_tab");
    expect(html).toContain('aria-label="rules.inspector.close"');
  });
});
