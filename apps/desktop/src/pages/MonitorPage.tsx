import { useEffect, useRef, useState } from "react";
import {
  veloxInvoke,
  type MetricsCpuTicks,
  type MetricsNetworkCounters,
  type MetricsSnapshot,
  type MetricsSnapshotPayload,
} from "@cleanspace/desktop-api";
import { BRAND_CHART, metricTint } from "../branding";
import { DonutChart, formatBps } from "../components/DonutChart";
import { WorkspaceGuide } from "../components/WorkspaceGuide";
import { useI18n } from "../i18n/useI18n";
import { formatBytes } from "../rules/format";

const POLL_MS = 1500;

export function MonitorPage() {
  const { t } = useI18n();
  const [snapshot, setSnapshot] = useState<MetricsSnapshot | null>(null);
  const ticksRef = useRef<MetricsCpuTicks | null>(null);
  const networkRef = useRef<MetricsNetworkCounters | null>(null);

  useEffect(() => {
    const poll = async () => {
      const args: Record<string, unknown> = {};
      if (ticksRef.current) args.previous_ticks = ticksRef.current;
      if (networkRef.current) args.previous_network = networkRef.current;
      const data = await veloxInvoke<MetricsSnapshotPayload>("metrics_snapshot", args);
      ticksRef.current = data.ticks;
      networkRef.current = data.network;
      setSnapshot(data.snapshot);
    };
    void poll();
    const id = setInterval(() => void poll(), POLL_MS);
    return () => clearInterval(id);
  }, []);

  const netPeak = Math.max(snapshot?.networkDownBps ?? 0, snapshot?.networkUpBps ?? 0);
  const netPercent = Math.min(100, (netPeak / (10 * 1024 * 1024)) * 100);

  return (
    <div className="workspace form-workspace">
      <h2>{t("monitor.nav_title")}</h2>
      <WorkspaceGuide text={t("monitor.intro")} />

      <div className="monitor-grid">
        <article className="card monitor-card">
          <h3>{t("metrics.menu.cpu.headline")}</h3>
          <DonutChart
            percent={snapshot?.cpuPercent ?? 0}
            color={metricTint(snapshot?.cpuPercent ?? 0)}
            label={t("metrics.menu.cpu.headline")}
          />
          <p className="muted">
            {t("metrics.menu.cpu.current", {
              value: `${(snapshot?.cpuPercent ?? 0).toFixed(1)}%`,
            })}
          </p>
        </article>

        <article className="card monitor-card">
          <h3>{t("metrics.menu.memory.headline")}</h3>
          <DonutChart
            percent={snapshot?.memoryPercent ?? 0}
            color={metricTint(snapshot?.memoryPercent ?? 0)}
            label={t("metrics.menu.memory.headline")}
          />
          <p className="muted">
            {t("metrics.menu.memory.current", {
              used: formatBytes(snapshot?.memoryUsedBytes),
              total: formatBytes(snapshot?.memoryTotalBytes),
              pct: `${(snapshot?.memoryPercent ?? 0).toFixed(1)}%`,
            })}
          </p>
        </article>

        <article className="card monitor-card">
          <h3>{t("metrics.menu.network.headline")}</h3>
          <DonutChart percent={netPercent} color={BRAND_CHART.network} label={t("metrics.menu.network.headline")} />
          <p className="muted mono">
            {t("metrics.menu.network.short", {
              up: formatBps(snapshot?.networkUpBps ?? 0),
              down: formatBps(snapshot?.networkDownBps ?? 0),
            })}
          </p>
        </article>
      </div>
    </div>
  );
}
