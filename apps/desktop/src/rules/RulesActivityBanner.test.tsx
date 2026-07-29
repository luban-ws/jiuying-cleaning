import { renderToStaticMarkup } from "react-dom/server";
import { describe, expect, it } from "vitest";
import { RulesActivityBanner } from "./RulesActivityBanner";
import type { RulesScanActivity } from "./scanActivity";

const t = (key: string, values?: Record<string, string | number>) => {
  if (!values) return key;
  return `${key}:${Object.values(values).join("/")}`;
};

function render(activity: RulesScanActivity) {
  return renderToStaticMarkup(
    <RulesActivityBanner
      activity={activity}
      performance={false}
      t={t}
      onDismiss={() => undefined}
    />,
  );
}

describe("RulesActivityBanner", () => {
  it("renders scanning progress in the live status region", () => {
    const html = render({
      kind: "scanning",
      current: 2,
      total: 4,
      ruleId: "browser-cache",
    });
    expect(html).toContain('role="status"');
    expect(html).toContain('aria-live="polite"');
    expect(html).toContain('value="2"');
    expect(html).toContain('max="4"');
    expect(html).toContain("browser-cache");
  });

  it("keeps a dismissible completion summary", () => {
    const html = render({
      kind: "completed",
      analyzed: 4,
      total: 4,
      deniedCount: 0,
    });
    expect(html).toContain("rules.activity.completed:4/4");
    expect(html).toContain('aria-label="rules.activity.dismiss"');
  });

  it("uses the partial summary when access was denied", () => {
    const html = render({
      kind: "partial",
      analyzed: 3,
      total: 4,
      deniedCount: 2,
    });
    expect(html).toContain("rules.activity.partial:3/4/2");
  });
});
