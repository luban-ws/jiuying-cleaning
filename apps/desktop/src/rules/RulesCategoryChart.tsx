import type { RuleSummary } from "@cleanspace/desktop-api";
import type { useI18n } from "../i18n/useI18n";
import { buildRulesCategorySlices } from "./chartSlices";
import { formatBytes } from "./format";

type Props = {
  rules: RuleSummary[];
  scannedSizes: Record<string, number>;
  t: ReturnType<typeof useI18n>["t"];
  cat: ReturnType<typeof useI18n>["cat"];
};

export function RulesCategoryChart({ rules, scannedSizes, t, cat }: Props) {
  const slices = buildRulesCategorySlices(rules, scannedSizes, cat);
  if (slices.length === 0) return null;

  const maxBytes = slices[0]?.bytes ?? 1;

  return (
    <section className="inspector-distribution">
      <h4>{t("rules.chart.card_title")}</h4>
      <div className="bar-chart" role="img" aria-label={t("rules.chart.card_title")}>
        {slices.map((slice) => (
          <div key={slice.id} className="bar-row">
            <span className="bar-label">{slice.label}</span>
            <div className="bar-track">
              <div
                className="bar-fill"
                style={{
                  width: `${(slice.bytes / maxBytes) * 100}%`,
                  backgroundColor: slice.color,
                }}
              />
            </div>
            <span className="bar-value mono">{formatBytes(slice.bytes)}</span>
          </div>
        ))}
      </div>
    </section>
  );
}
