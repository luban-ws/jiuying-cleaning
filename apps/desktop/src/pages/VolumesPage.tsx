import { useEffect, useMemo, useState } from "react";
import {
  runAsyncJob,
  veloxInvoke,
  type VolumeScanJobStatus,
  type VolumeScanResult,
  type VolumeSummary,
  type IPCJobHandle,
} from "@cleanspace/desktop-api";
import { DiskUsageMap } from "../components/DiskUsageMap";
import { FullDiskAccessBanner } from "../components/FullDiskAccessBanner";
import { VolumePicker } from "../components/VolumePicker";
import { BRAND_CHART } from "../branding";
import { DonutChart } from "../components/DonutChart";
import { WorkspaceGuide } from "../components/WorkspaceGuide";
import { useI18n } from "../i18n/useI18n";
import { formatBytes, formatPercent, volumeUsageStats } from "../rules/format";
import { buildRulesCategorySlices, type ChartSlice } from "../rules/chartSlices";

export function VolumesPage() {
  const { t } = useI18n();
  const [volumes, setVolumes] = useState<VolumeSummary[]>([]);
  const [selectedId, setSelectedId] = useState("");
  const [scan, setScan] = useState<VolumeScanResult | null>(null);
  const [loading, setLoading] = useState(true);
  const [scanning, setScanning] = useState(false);
  const [error, setError] = useState("");
  const [fdaDismissed, setFdaDismissed] = useState(false);

  const selected = volumes.find((v) => v.id === selectedId);
  const usage = volumeUsageStats(selected?.totalBytes, selected?.freeBytes);

  useEffect(() => {
    void (async () => {
      try {
        const rows = await veloxInvoke<VolumeSummary[]>("list_volumes");
        setVolumes(rows);
        if (rows[0]) setSelectedId(rows[0].id);
      } catch (err) {
        setError(err instanceof Error ? err.message : String(err));
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  useEffect(() => {
    setScan(null);
    setFdaDismissed(false);
  }, [selectedId]);

  const folderSlices: ChartSlice[] = useMemo(() => {
    if (!scan?.folders.length) return [];
    const sizes = Object.fromEntries(scan.folders.map((f) => [f.path, f.bytes]));
    const pseudoRules = scan.folders.map((f) => ({
      id: f.path,
      name: f.name,
      category: f.name,
      risk: "low",
      type: "dir",
    }));
    return buildRulesCategorySlices(pseudoRules, sizes, (c) => c);
  }, [scan]);

  const runScan = async () => {
    if (!selected) return;
    setScanning(true);
    setError("");
    try {
      const result = await runAsyncJob<IPCJobHandle, VolumeScanJobStatus, VolumeScanResult>(
        "scan_volume_start",
        {
          volume_path: selected.path,
          total_bytes: selected.totalBytes ?? undefined,
          free_bytes: selected.freeBytes ?? undefined,
        },
        "scan_volume_poll",
        (status) => status.result,
      );
      setScan(result);
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setScanning(false);
    }
  };

  const openPath = (path: string) => void veloxInvoke("open_path", { path });

  return (
    <div className="workspace form-workspace volumes-workspace">
      <h2>{t("disk.nav_title")}</h2>
      <WorkspaceGuide text={t("disk.select_volume_hint")} />

      {loading && <p className="muted">{t("docker.loading")}</p>}
      {error && <p className="error">{error}</p>}

      {!loading && volumes.length === 0 && <p className="muted">{t("disk.no_volumes")}</p>}

      {!loading && volumes.length > 0 && (
        <>
          <p className="field-label">{t("disk.picker.label")}</p>
          <VolumePicker
            volumes={volumes}
            selectedId={selectedId}
            onSelect={setSelectedId}
            freeLabel={(free) => t("disk.free_short", { free })}
          />

          {selected && (
            <>
              <section className="card volume-hero-card">
                <DiskUsageMap
                  stats={usage}
                  path={selected.path}
                  title={t("disk.map.title")}
                  labels={{
                    used: t("disk.hero.used"),
                    available: t("disk.hero.available"),
                    capacity: t("disk.hero.capacity"),
                    usedPercent: (percent) => t("disk.usage_percent", { percent }),
                  }}
                />
                <div className="toolbar volume-hero-actions">
                  <button type="button" className="btn ghost" onClick={() => openPath(selected.path)}>
                    {t("disk.show_in_finder")}
                  </button>
                  <button type="button" className="btn" disabled={scanning} onClick={() => void runScan()}>
                    {scanning ? t("disk.scanning") : t("disk.scan_top_level")}
                  </button>
                </div>
              </section>

              {!scan && !scanning && <p className="muted scan-hint">{t("disk.scan_hint_empty")}</p>}

              {scan && !fdaDismissed && (
                <FullDiskAccessBanner
                  deniedPaths={scan.deniedPaths}
                  t={t}
                  onDismiss={() => setFdaDismissed(true)}
                />
              )}

              {scan && scan.accounting && (
                <section className="card">
                  <h3>{t("disk.section.accounting")}</h3>
                  <p className="muted">{t("disk.accounting.footer")}</p>
                  <dl className="accounting-dl">
                    <div>
                      <dt>{t("disk.sum_top_level")}</dt>
                      <dd className="mono">{formatBytes(scan.accounting.topLevelSum)}</dd>
                    </div>
                    <div>
                      <dt>{t("disk.unaccounted")}</dt>
                      <dd className="mono">{formatBytes(scan.accounting.unaccountedBytes)}</dd>
                    </div>
                  </dl>
                </section>
              )}

              {scan && folderSlices.length > 0 && (
                <section className="card chart-card">
                  <h3>{t("disk.chart.card_title")}</h3>
                  <div className="chart-layout">
                    <DonutChart
                      percent={usage.usedPercent}
                      color={BRAND_CHART.volume}
                      label={t("disk.chart.whole_volume")}
                    />
                    <div className="bar-chart">
                      {folderSlices.map((slice) => (
                        <div key={slice.id} className="bar-row">
                          <span className="bar-label">{slice.label}</span>
                          <div className="bar-track">
                            <div
                              className="bar-fill"
                              style={{
                                width: `${(slice.bytes / (folderSlices[0]?.bytes || 1)) * 100}%`,
                                backgroundColor: slice.color,
                              }}
                            />
                          </div>
                          <span className="bar-value mono">{formatBytes(slice.bytes)}</span>
                        </div>
                      ))}
                    </div>
                  </div>
                </section>
              )}

              {scan && scan.folders.length > 0 && (
                <table className="table">
                  <thead>
                    <tr>
                      <th>{t("disk.table.folder")}</th>
                      <th>{t("disk.table.size")}</th>
                      <th>{t("disk.table.percent")}</th>
                      <th />
                    </tr>
                  </thead>
                  <tbody>
                    {scan.folders.map((folder) => (
                      <tr key={folder.path}>
                        <td>{folder.name}</td>
                        <td className="mono">{formatBytes(folder.bytes)}</td>
                        <td className="mono muted">
                          {formatPercent(folder.bytes, scan.accounting?.topLevelSum ?? folder.bytes)}
                        </td>
                        <td>
                          <button type="button" className="btn ghost" onClick={() => openPath(folder.path)}>
                            {t("disk.open_finder")}
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </>
          )}
        </>
      )}
    </div>
  );
}
