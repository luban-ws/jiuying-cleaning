import { useEffect, useMemo, useState } from "react";
import {
  runAsyncJob,
  veloxInvoke,
  type VolumeScanJobStatus,
  type VolumeScanResult,
  type VolumeSummary,
  type IPCJobHandle,
} from "@cleanspace/desktop-api";
import { FullDiskAccessBanner } from "../components/FullDiskAccessBanner";
import { BRAND_CHART } from "../branding";
import { DonutChart } from "../components/DonutChart";
import { WorkspaceGuide } from "../components/WorkspaceGuide";
import { useI18n } from "../i18n/useI18n";
import { formatBytes, formatPercent } from "../rules/format";
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

  const usedBytes = useMemo(() => {
    if (!selected?.totalBytes || selected.freeBytes == null) return null;
    return Math.max(0, selected.totalBytes - selected.freeBytes);
  }, [selected]);

  const usedPercent = useMemo(() => {
    if (!selected?.totalBytes || usedBytes == null || selected.totalBytes <= 0) return 0;
    return (usedBytes / selected.totalBytes) * 100;
  }, [selected, usedBytes]);

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
    <div className="workspace form-workspace">
      <h2>{t("disk.nav_title")}</h2>
      <WorkspaceGuide text={t("disk.select_volume_hint")} />

      {loading && <p className="muted">{t("docker.loading")}</p>}
      {error && <p className="error">{error}</p>}

      {!loading && volumes.length === 0 && <p className="muted">{t("disk.no_volumes")}</p>}

      {!loading && volumes.length > 0 && (
        <>
          <label className="field-label" htmlFor="volume-picker">
            {t("disk.picker.label")}
          </label>
          <select
            id="volume-picker"
            className="select"
            value={selectedId}
            onChange={(e) => setSelectedId(e.target.value)}
          >
            {volumes.map((v) => (
              <option key={v.id} value={v.id}>
                {t("disk.volume_picker_format", {
                  name: v.name,
                  free: formatBytes(v.freeBytes ?? 0),
                })}
              </option>
            ))}
          </select>

          {selected && (
            <>
              <section className="card hero-card">
                <div className="hero-metrics">
                  <div>
                    <p className="muted label">{t("disk.hero.available")}</p>
                    <p className="hero-value">{formatBytes(selected.freeBytes)}</p>
                  </div>
                  <div>
                    <p className="muted label">{t("disk.hero.used")}</p>
                    <p className="hero-value">{formatBytes(usedBytes)}</p>
                  </div>
                  <div>
                    <p className="muted label">{t("disk.hero.capacity")}</p>
                    <p className="hero-value">{formatBytes(selected.totalBytes)}</p>
                  </div>
                </div>
                <div className="hero-bar">
                  <div className="hero-bar-fill" style={{ width: `${usedPercent}%` }} />
                </div>
                <p className="muted mono">{selected.path}</p>
                <div className="toolbar">
                  <button type="button" className="btn ghost" onClick={() => openPath(selected.path)}>
                    {t("disk.show_in_finder")}
                  </button>
                  <button type="button" className="btn" disabled={scanning} onClick={() => void runScan()}>
                    {scanning ? t("disk.scanning") : t("disk.scan_top_level")}
                  </button>
                </div>
              </section>

              {!scan && !scanning && <p className="muted">{t("disk.scan_hint_empty")}</p>}

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
                    <DonutChart percent={usedPercent} color={BRAND_CHART.volume} label={t("disk.chart.whole_volume")} />
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
