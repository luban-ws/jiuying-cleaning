import type { useI18n } from "../i18n/useI18n";
import { formatBytes } from "./format";
import type { RulesWorkspaceState } from "./useRulesWorkspace";

type Props = {
  ws: RulesWorkspaceState;
  t: ReturnType<typeof useI18n>["t"];
};

export function RulesCommandBar({ ws, t }: Props) {
  const disabled = ws.busy || ws.isScanning || ws.isCleaning;
  const hasSelection = ws.selectedRuleIds.size > 0;

  const metric = (() => {
    if (!hasSelection) return t("rules.action.metric.placeholder");
    if (ws.performance) {
      if (ws.analyzedSelectedCount === 0) return t("rules.action.metric.tap_analyze");
      return t("performance.list.process_count", { count: ws.selectedProcessCount });
    }
    if (ws.selectedRecoverableBytes > 0) return formatBytes(ws.selectedRecoverableBytes);
    if (ws.analyzedSelectedCount === 0) return t("rules.action.metric.tap_analyze");
    return formatBytes(ws.selectedRecoverableBytes);
  })();

  const caption = hasSelection
    ? t("rules.action.caption.counts", {
        selected: ws.selectedRuleIds.size,
        path: ws.selectedPathRules.length,
        command: ws.selectedCommandRules.length,
      })
    : t("rules.action.caption.none");

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
    <footer className="rules-command-bar" aria-label="Cleaning actions">
      <div className="command-metric">
        <p className="muted label">
          {ws.performance ? t("performance.action.impact_label") : t("rules.action.recoverable_label")}
        </p>
        <p className={`metric${hasSelection ? " mono" : " metric-placeholder"}`}>{metric}</p>
        <p className="muted caption">{caption}</p>
      </div>
      <div className="command-actions">
        <button type="button" className="btn" disabled={disabled || ws.rules.length === 0} onClick={() => void ws.scanAll()}>
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
          className="btn danger"
          disabled={disabled || !hasSelection}
          onClick={ws.openCleanConfirm}
        >
          {ws.isCleaning ? cleanBusyLabel : cleanLabel}
        </button>
      </div>
    </footer>
  );
}
