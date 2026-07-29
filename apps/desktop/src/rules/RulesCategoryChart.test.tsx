import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import type { RuleSummary } from "@cleanspace/desktop-api";
import { RulesCategoryChart } from "./RulesCategoryChart";

const rules: RuleSummary[] = [
  {
    id: "browser-cache",
    name: "Browser cache",
    category: "browser",
    risk: "low",
    type: "dir",
  },
];

describe("RulesCategoryChart", () => {
  it("renders one distribution view without a donut or duplicate table", () => {
    const html = renderToStaticMarkup(
      <RulesCategoryChart
        rules={rules}
        scannedSizes={{ "browser-cache": 2048 }}
        t={(key) => key}
        cat={(category) => category}
      />,
    );

    expect(html).toContain("bar-chart");
    expect(html).not.toContain("donut-chart");
    expect(html).not.toContain("<table");
  });
});
