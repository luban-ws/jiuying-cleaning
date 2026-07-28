import { useEffect, useState } from "react";
import {
  runAsyncJob,
  veloxInvoke,
  type DockerDesktopSizeRow,
  type DockerDiskUsageParsed,
  type DockerPresetJobStatus,
  type DockerPresetRunResult,
  type DockerPresetSummary,
  type DockerRefreshJobStatus,
  type DockerRefreshResult,
  type IPCJobHandle,
} from "@cleanspace/desktop-api";
import { WorkspaceGuide } from "../components/WorkspaceGuide";
import { useI18n } from "../i18n/useI18n";
import { formatBytes } from "../rules/format";
import { buildRulesCategorySlices } from "../rules/chartSlices";

export function DockerPage() {
  const { t } = useI18n();
  const [presets, setPresets] = useState<DockerPresetSummary[]>([]);
  const [df, setDf] = useState<DockerDiskUsageParsed | null>(null);
  const [desktop, setDesktop] = useState<DockerDesktopSizeRow[]>([]);
  const [log, setLog] = useState("");
  const [busy, setBusy] = useState(false);
  const [confirmPreset, setConfirmPreset] = useState<DockerPresetSummary | null>(null);
  const [progress, setProgress] = useState("");

  const refresh = async () => {
    setBusy(true);
    try {
      const refreshResult = await runAsyncJob<IPCJobHandle, DockerRefreshJobStatus, DockerRefreshResult>(
        "docker_refresh_start",
        {},
        "docker_refresh_poll",
        (status) => status.result,
      );
      setDf(refreshResult.df);
      setDesktop(refreshResult.desktop);
      setPresets(await veloxInvoke<DockerPresetSummary[]>("docker_presets"));
    } finally {
      setBusy(false);
    }
  };

  useEffect(() => {
    void refresh();
  }, []);

  const runPreset = async (preset: DockerPresetSummary) => {
    setConfirmPreset(null);
    setBusy(true);
    setProgress(t("docker.progress.starting"));
    try {
      const result = await runAsyncJob<IPCJobHandle, DockerPresetJobStatus, DockerPresetRunResult>(
        "docker_run_preset_start",
        { preset_id: preset.id },
        "docker_run_preset_poll",
        (status) => status.result,
      );
      setLog(result.log);
      setProgress(result.success ? t("docker.progress.working") : t("docker.alert.title"));
      await refresh();
    } finally {
      setBusy(false);
      setProgress("");
    }
  };

  const desktopSlices = buildRulesCategorySlices(
    desktop.map((row) => ({
      id: row.path,
      name: row.label,
      category: row.label,
      risk: "low",
      type: "dir",
    })),
    Object.fromEntries(desktop.map((r) => [r.path, r.bytes])),
    (c) => c,
  );

  return (
    <div className="workspace form-workspace">
      <h2>{t("nav.docker")}</h2>
      <WorkspaceGuide text={t("docker.intro")} />

      <div className="toolbar">
        <button type="button" className="btn ghost" disabled={busy} onClick={() => void refresh()}>
          {t("docker.refresh_output")}
        </button>
      </div>

      <h3 className="section-title">{t("docker.section.presets")}</h3>
      <div className="preset-grid">
        {presets.map((preset) => (
          <article key={preset.id} className={`card preset-card${preset.isDestructive ? " destructive" : ""}`}>
            <h4>{preset.title}</h4>
            <p className="muted">{preset.subtitle}</p>
            <button
              type="button"
              className={preset.isDestructive ? "btn danger" : "btn"}
              disabled={busy}
              onClick={() => (preset.isDestructive ? setConfirmPreset(preset) : void runPreset(preset))}
            >
              {preset.isDestructive ? t("docker.execute") : t("docker.run")}
            </button>
          </article>
        ))}
      </div>

      {progress && <p className="muted" aria-live="polite">{progress}</p>}

      {desktop.length > 0 && (
        <section className="card chart-card">
          <h3>{t("docker.chart.card_title")}</h3>
          <div className="bar-chart">
            {desktopSlices.map((slice) => (
              <div key={slice.id} className="bar-row">
                <span className="bar-label">{slice.label}</span>
                <div className="bar-track">
                  <div
                    className="bar-fill"
                    style={{
                      width: `${(slice.bytes / (desktopSlices[0]?.bytes || 1)) * 100}%`,
                      backgroundColor: slice.color,
                    }}
                  />
                </div>
                <span className="bar-value mono">{formatBytes(slice.bytes)}</span>
              </div>
            ))}
          </div>
        </section>
      )}

      <h3 className="section-title">{t("docker.section.df")}</h3>
      {df?.fatalErrorText && <p className="error">{df.fatalErrorText}</p>}
      {df && df.summaryRows.length > 0 ? (
        <table className="table">
          <thead>
            <tr>
              <th>TYPE</th>
              <th>TOTAL</th>
              <th>ACTIVE</th>
              <th>SIZE</th>
              <th>RECLAIMABLE</th>
            </tr>
          </thead>
          <tbody>
            {df.summaryRows.map((row) => (
              <tr key={row.resourceType}>
                <td>{row.resourceType}</td>
                <td>{row.total}</td>
                <td>{row.active}</td>
                <td>{row.size}</td>
                <td>{row.reclaimable}</td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : (
        <p className="muted">{t("docker.df_placeholder")}</p>
      )}

      {df?.detailSections.map((section) => (
        <section key={section.id} className="card">
          <h4>{section.title}</h4>
          {section.prefixLines.map((line) => (
            <p key={line} className="muted mono">
              {line}
            </p>
          ))}
          {section.columnTitles.length > 0 && section.rows.length > 0 && (
            <table className="table">
              <thead>
                <tr>
                  {section.columnTitles.map((col) => (
                    <th key={col}>{col}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {section.rows.map((row, i) => (
                  <tr key={i}>
                    {row.map((cell, j) => (
                      <td key={j}>{cell}</td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      ))}

      <h3 className="section-title">{t("docker.section.log")}</h3>
      <pre className="mono card log-panel" aria-live="polite">
        {log || t("docker.log.streaming_placeholder")}
      </pre>

      {confirmPreset && (
        <div className="modal-backdrop" onClick={() => setConfirmPreset(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} role="dialog">
            <h3>{t("docker.alert.title")}</h3>
            <p>
              {confirmPreset.isDestructive ? t("docker.alert.msg.destructive") : t("docker.alert.msg.safe")}
            </p>
            <p className="muted">{confirmPreset.title}</p>
            <div className="modal-actions">
              <button type="button" className="btn ghost" onClick={() => setConfirmPreset(null)}>
                {t("common.cancel")}
              </button>
              <button type="button" className="btn danger" onClick={() => void runPreset(confirmPreset)}>
                {t("docker.alert.run_destructive")}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
