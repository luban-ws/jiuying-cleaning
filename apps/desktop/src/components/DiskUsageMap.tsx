import { BRAND_CHART } from "../branding";
import { DonutChart } from "./DonutChart";
import { formatBytes, type VolumeUsageStats } from "../rules/format";

type LegendRow = {
  key: string;
  label: string;
  value: string;
  percent: number;
  color: string;
  muted?: boolean;
};

type Props = {
  stats: VolumeUsageStats;
  path: string;
  title: string;
  labels: {
    used: string;
    available: string;
    capacity: string;
    usedPercent: (percent: number) => string;
  };
};

export function DiskUsageMap({ stats, path, title, labels }: Props) {
  const rows: LegendRow[] = [];

  if (stats.hasCapacity) {
    rows.push({
      key: "capacity",
      label: labels.capacity,
      value: formatBytes(stats.total),
      percent: 100,
      color: "var(--color-border)",
      muted: true,
    });
  }

  if (stats.freeKnown && stats.used != null) {
    rows.push({
      key: "used",
      label: labels.used,
      value: formatBytes(stats.used),
      percent: stats.usedPercent,
      color: BRAND_CHART.volume,
    });
    rows.push({
      key: "free",
      label: labels.available,
      value: formatBytes(stats.free),
      percent: stats.freePercent,
      color: "var(--brand-slate)",
    });
  } else if (stats.hasCapacity) {
    rows.push({
      key: "used",
      label: labels.used,
      value: "—",
      percent: 0,
      color: BRAND_CHART.volume,
      muted: true,
    });
    rows.push({
      key: "free",
      label: labels.available,
      value: "—",
      percent: 0,
      color: "var(--brand-slate)",
      muted: true,
    });
  }

  const donutPercent =
    stats.freeKnown && stats.hasCapacity ? stats.usedPercent : 0;

  return (
    <section className="disk-usage-map" aria-label={title}>
      <h3 className="disk-usage-map-title">{title}</h3>
      <div className="disk-usage-map-body">
        <DonutChart
          percent={donutPercent}
          color={BRAND_CHART.volume}
          size={132}
          label={labels.usedPercent(Math.round(donutPercent))}
        />
        <div className="disk-usage-map-detail">
          <div className="disk-usage-stack" aria-hidden>
            {stats.hasCapacity && stats.freeKnown ? (
              <>
                <div
                  className="disk-usage-stack-used"
                  style={{ width: `${stats.usedPercent}%` }}
                />
                <div
                  className="disk-usage-stack-free"
                  style={{ width: `${stats.freePercent}%` }}
                />
              </>
            ) : stats.hasCapacity ? (
              <div className="disk-usage-stack-unknown" />
            ) : null}
          </div>
          <ul className="disk-usage-legend">
            {rows.map((row) => (
              <li key={row.key} className="disk-usage-legend-row">
                <span
                  className="disk-usage-swatch"
                  style={{ backgroundColor: row.color }}
                  aria-hidden
                />
                <span className="disk-usage-legend-label">{row.label}</span>
                <span className={`disk-usage-legend-value mono${row.muted ? " muted" : ""}`}>
                  {row.value}
                </span>
                {stats.freeKnown && row.key !== "capacity" ? (
                  <span className="disk-usage-legend-pct mono muted">
                    {Math.round(row.percent)}%
                  </span>
                ) : null}
              </li>
            ))}
          </ul>
          <p className="disk-usage-path mono muted">{path}</p>
        </div>
      </div>
    </section>
  );
}
