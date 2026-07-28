import type { useI18n } from "../i18n/useI18n";
import { formatBytes } from "./format";
import type { RulesWorkspaceState } from "./useRulesWorkspace";

type Props = {
  ws: RulesWorkspaceState;
  t: ReturnType<typeof useI18n>["t"];
};

export function RulesCommandBar({ ws, t }: Props) {
  const disabled = ws.busy || ws.isScanning || ws.isCleaning;
  const selectedCount = ws.selectedRuleIds.size;
  const hasSelection = selectedCount > 0;
  const needsAnalyze = hasSelection && ws.analyzedSelectedCount < selectedCount;

  const impactLabel = ws.performance
    ? t("performance.action.impact_label")
    : t("rules.action.recoverable_label");

  const impactValue = (() => {
    if (!hasSelection) return "—";
    if (ws.performance) {
      if (ws.analyzedSelectedCount === 0) return "—";
      return t("performance.list.process_count", { count: ws.selectedProcessCount });
    }
    if (ws.analyzedSelectedCount === 0) return "—";
    return formatBytes(ws.selectedRecoverableBytes);
  })();

  const hint = !hasSelection
    ? t("rules.action.bar.hint_select")
    : needsAnalyze
      ? t("rules.action.metric.tap_analyze")
      : null;

  const cleanLabel = ws.performance ? t("performance.boost") : t("rules.clean");
  const scanLabel = ws.isScanning
    ? ws.scanProgress
      ? `${ws.performance ? t("performance.scanning") : t("rules.scanning")} (${ws.scanProgress.current}/${ws.scanProgress.total})`
      : ws.performance
        ? t("performance.scanning")
        : t("rules.scanning")
    : t("rules.scan");
  const cleanBusyLabel = ws.performance ? t("performance.boosting") : t("rules.cleaning");

  return (
    <footer className="rules-command-bar" aria-label={t("rules.action.bar.aria")}>
      <div className="command-bar-leading">
        <div className="command-bar-stats">
          <div className="command-stat" aria-label={t("rules.action.bar.selected_aria", { count: selectedCount })}>
            <span className={`command-stat-value${hasSelection ? " emphasized" : ""}`}>{selectedCount}</span>
            <span className="command-stat-label">{t("rules.action.bar.selected_label")}</span>
          </div>
          <span className="command-stat-sep" aria-hidden />
          <div className="command-stat">
            <span className={`command-stat-value${impactValue !== "—" ? " mono emphasized" : ""}`}>
              {impactValue}
            </span>
            <span className="command-stat-label">{impactLabel}</span>
          </div>
        </div>
        {hint ? <p className="command-bar-hint">{hint}</p> : null}
      </div>

      <div className="command-bar-actions">
        <button
          type="button"
          className={`btn${needsAnalyze || !hasSelection ? "" : " ghost"}`}
          disabled={disabled || ws.rules.length === 0}
          onClick={() => void ws.scanAll()}
        >
          {scanLabel}
        </button>
        <button
          type="button"
          className="btn ghost"
          disabled={disabled || !hasSelection}
          onClick={() => ws.setPreviewOpen(true)}
        >
          {t("rules.dry_run")}
        </button>
        <button
          type="button"
          className={`btn danger${hasSelection && !needsAnalyze ? " command-cta-ready" : ""}`}
          disabled={disabled || !hasSelection}
          onClick={ws.openCleanConfirm}
        >
          {ws.isCleaning ? cleanBusyLabel : cleanLabel}
        </button>
      </div>
    </footer>
  );
}
