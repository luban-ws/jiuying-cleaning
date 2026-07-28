import { describe, expect, it } from "vitest";
import type { RuleSummary } from "@cleanspace/desktop-api";
import { buildRulesCategorySlices } from "./chartSlices";

const rules: RuleSummary[] = [
  {
    id: "a",
    name: "A",
    category: "system",
    risk: "low",
    type: "dir",
  },
  {
    id: "b",
    name: "B",
    category: "browser",
    risk: "low",
    type: "dir",
  },
  {
    id: "c",
    name: "C",
    category: "system",
    risk: "low",
    type: "command",
  },
];

describe("buildRulesCategorySlices", () => {
  it("aggregates dir rules by category", () => {
    const slices = buildRulesCategorySlices(
      rules,
      { a: 100, b: 50, c: 999 },
      (cat) => cat,
    );
    expect(slices).toHaveLength(2);
    expect(slices[0]).toMatchObject({ id: "system", bytes: 100 });
    expect(slices[1]).toMatchObject({ id: "browser", bytes: 50 });
  });

  it("ignores zero or missing sizes", () => {
    const slices = buildRulesCategorySlices(rules, { a: 0 }, (cat) => cat);
    expect(slices).toHaveLength(0);
  });
});
