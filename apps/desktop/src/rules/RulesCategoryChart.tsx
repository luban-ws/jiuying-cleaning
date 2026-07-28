import type { RuleSummary } from "@cleanspace/desktop-api";
import type { useI18n } from "../i18n/useI18n";
import { buildRulesCategorySlices } from "./chartSlices";
import { formatBytes, formatPercent } from "./format";

type Props = {
  rules: RuleSummary[];
  scannedSizes: Record<string, number>;
  t: ReturnType<typeof useI18n>["t"];
  cat: ReturnType<typeof useI18n>["cat"];
};

export function RulesCategoryChart({ rules, scannedSizes, t, cat }: Props) {
  const slices = buildRulesCategorySlices(rules, scannedSizes, cat);
  if (slices.length === 0) return null;

  const total = slices.reduce((sum, s) => sum + s.bytes, 0);
  const maxBytes = slices[0]?.bytes ?? 1;

  let angle = 0;
  const donutSegments = slices.map((slice) => {
    const sweep = (slice.bytes / total) * 360;
    const start = angle;
    angle += sweep;
    return { ...slice, start, sweep };
  });

  return (
    <section className="card chart-card">
      <h3>{t("rules.chart.card_title")}</h3>
      <div className="chart-layout">
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
        <svg className="donut-chart" viewBox="0 0 100 100" aria-hidden>
          {donutSegments.map((seg) => (
            <path
              key={seg.id}
              d={describeArc(50, 50, 40, 28, seg.start, seg.start + seg.sweep)}
              fill={seg.color}
            />
          ))}
        </svg>
      </div>
      <table className="table chart-table">
        <thead>
          <tr>
            <th>{t("chart.table.category")}</th>
            <th>{t("chart.table.sum")}</th>
            <th>{t("chart.table.percent")}</th>
          </tr>
        </thead>
        <tbody>
          {slices.map((slice) => (
            <tr key={slice.id}>
              <td>{slice.label}</td>
              <td className="mono">{formatBytes(slice.bytes)}</td>
              <td className="mono muted">{formatPercent(slice.bytes, total)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}

function polarToCartesian(cx: number, cy: number, r: number, angleDeg: number) {
  const rad = ((angleDeg - 90) * Math.PI) / 180;
  return { x: cx + r * Math.cos(rad), y: cy + r * Math.sin(rad) };
}

function describeArc(cx: number, cy: number, outer: number, inner: number, start: number, end: number) {
  const startOuter = polarToCartesian(cx, cy, outer, end);
  const endOuter = polarToCartesian(cx, cy, outer, start);
  const startInner = polarToCartesian(cx, cy, inner, start);
  const endInner = polarToCartesian(cx, cy, inner, end);
  const large = end - start <= 180 ? 0 : 1;
  return [
    `M ${startOuter.x} ${startOuter.y}`,
    `A ${outer} ${outer} 0 ${large} 0 ${endOuter.x} ${endOuter.y}`,
    `L ${startInner.x} ${startInner.y}`,
    `A ${inner} ${inner} 0 ${large} 1 ${endInner.x} ${endInner.y}`,
    "Z",
  ].join(" ");
}
