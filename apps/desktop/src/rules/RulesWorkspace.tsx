import type { WorkspaceScope } from "@cleanspace/desktop-api";
import { useI18n } from "../i18n/useI18n";
import { FullDiskAccessBanner } from "../components/FullDiskAccessBanner";
import { WorkspaceGuide } from "../components/WorkspaceGuide";
import { workspaceGuideKey } from "./constants";
import { PerformanceLayout } from "./PerformanceLayout";
import { RulesCategoryChart } from "./RulesCategoryChart";
import { RulesCommandBar } from "./RulesCommandBar";
import { RulesFilterToolbar, RulesTable } from "./RulesFilterToolbar";
import { RulesInspector } from "./RulesInspector";
import { RulesPreviewSheet } from "./RulesPreviewSheet";
import { formatBytes } from "./format";
import { useRulesWorkspace } from "./useRulesWorkspace";

type Props = { scope: WorkspaceScope };

export function RulesWorkspace({ scope }: Props) {
  const { t, cat } = useI18n();
  const ws = useRulesWorkspace(scope);

  const title =
    scope === "performance"
      ? t("nav.performance")
      : scope === "ai_tools_space"
        ? t("nav.aiTools")
        : t("nav.rules");

  return (
    <div className="rules-workspace">
      <header className="rules-header">
        <h2>{title}</h2>
        <WorkspaceGuide text={t(workspaceGuideKey(scope))} />
        {ws.showFdaBanner && !ws.fdaDismissed ? (
          <FullDiskAccessBanner
            deniedPaths={ws.deniedPaths}
            t={t}
            onDismiss={() => ws.setFdaDismissed(true)}
          />
        ) : null}
        <div className="overview-chips">
          <span className="chip">{t("rules.overview.chip.total", { count: ws.rules.length })}</span>
          <span className={`chip${ws.selectedRuleIds.size > 0 ? " emphasized" : ""}`}>
            {t("rules.overview.chip.selected", { count: ws.selectedRuleIds.size })}
          </span>
          <span className={`chip${ws.scannedMetricCount > 0 ? " emphasized" : ""}`}>
            {ws.performance
              ? t("performance.overview.chip.analyzed", { count: ws.scannedMetricCount })
              : t("rules.overview.chip.scanned", { count: ws.scannedMetricCount })}
          </span>
        </div>
      </header>

      {ws.loading ? <p className="muted">Loading…</p> : null}
      {ws.error ? <p className="error">{ws.error}</p> : null}

      <div className="rules-workspace-scroll">
        {!ws.loading && ws.rules.length === 0 ? (
          <div className="empty-state">
            <h3>No rules</h3>
          </div>
        ) : null}

        {!ws.loading && ws.rules.length > 0 ? (
          <div className="rules-body">
            {ws.performance ? (
              <PerformanceLayout ws={ws} t={t} />
            ) : (
              <>
                <RulesFilterToolbar ws={ws} t={t} cat={cat} />
                <div className="rules-split">
                  <div className="rules-table-pane">
                    <RulesTable ws={ws} t={t} cat={cat} formatBytes={formatBytes} />
                  </div>
                  <RulesInspector ws={ws} t={t} cat={cat} preview={ws.focusedPreview} />
                </div>
                {ws.hasDirScanResults && ws.showChart ? (
                  <div className="chart-toolbar">
                    <label className="chart-toggle">
                      <input
                        type="checkbox"
                        checked={ws.showChart}
                        onChange={(e) => ws.setShowChart(e.target.checked)}
                      />
                      {t("rules.chart.card_title")}
                    </label>
                  </div>
                ) : null}
                {ws.hasDirScanResults && ws.showChart ? (
                  <RulesCategoryChart
                    rules={ws.rules}
                    scannedSizes={ws.sizes}
                    t={t}
                    cat={cat}
                  />
                ) : null}
              </>
            )}
          </div>
        ) : null}

        {ws.isScanning && ws.scanProgress ? (
          <div className="scan-progress" role="status">
            <div
              className="scan-progress-bar"
              style={{ width: `${(ws.scanProgress.current / ws.scanProgress.total) * 100}%` }}
            />
            <p className="scan-progress-label">
              {t("rules.scanning")} {ws.scanProgress.current}/{ws.scanProgress.total}
              {ws.scanProgress.ruleId ? (
                <span className="mono"> · {ws.scanProgress.ruleId}</span>
              ) : null}
            </p>
          </div>
        ) : null}
      </div>

      {!ws.loading && ws.rules.length > 0 ? <RulesCommandBar ws={ws} t={t} /> : null}

      <RulesPreviewSheet
        open={ws.previewOpen}
        rules={ws.rules}
        selectedIds={ws.selectedRuleIds}
        onClose={() => ws.setPreviewOpen(false)}
        t={t}
      />

      {ws.confirm ? (
        <div className="modal-backdrop" onClick={() => ws.setConfirm(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} role="dialog">
            <h3>{t("rules.alert.confirm.title")}</h3>
            <p>
              {ws.confirm.risky
                ? t("rules.confirm.clean_risky")
                : t("rules.confirm.clean_safe", { count: ws.selectedRuleIds.size })}
            </p>
            <div className="modal-actions">
              <button type="button" className="btn ghost" onClick={() => ws.setConfirm(null)}>
                {t("common.cancel")}
              </button>
              <button type="button" className="btn danger" onClick={() => void ws.runClean()}>
                {ws.performance ? t("performance.boost") : t("rules.clean")}
              </button>
            </div>
          </div>
        </div>
      ) : null}

      {ws.cleanResult ? (
        <div className="modal-backdrop" onClick={() => ws.setCleanResult(null)}>
          <div className="modal" onClick={(e) => e.stopPropagation()} role="dialog">
            <h3>{t("rules.alert.result.title")}</h3>
            <ul className="clean-result-list">
              {ws.cleanResult.items.map((item) => (
                <li key={item.ruleId}>
                  <code>{item.ruleId}</code>: {item.success ? "OK" : "FAIL"} — {item.message}
                </li>
              ))}
            </ul>
            <button type="button" className="btn" onClick={() => ws.setCleanResult(null)}>
              {t("common.ok")}
            </button>
          </div>
        </div>
      ) : null}
    </div>
  );
}
