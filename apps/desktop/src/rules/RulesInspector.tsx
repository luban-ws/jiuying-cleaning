import type { RulePreviewResult } from "@cleanspace/desktop-api";
import type { useI18n } from "../i18n/useI18n";
import { displaysByteSize, displaysProcessCount } from "./constants";
import { formatBytes } from "./format";
import type { RulesWorkspaceState } from "./useRulesWorkspace";

type Props = {
  ws: RulesWorkspaceState;
  t: ReturnType<typeof useI18n>["t"];
  cat: ReturnType<typeof useI18n>["cat"];
  preview: RulePreviewResult | null;
};

export function RulesInspector({ ws, t, cat, preview }: Props) {
  const rule = ws.focusedRule;

  return (
    <aside className="rules-inspector" aria-label={t("rules.inspector.title")}>
      <h3 className="inspector-title">{t("rules.inspector.title")}</h3>
      {!rule ? (
        <div className="inspector-empty">
          <h4>{t("rules.inspector.empty.title")}</h4>
          <p className="muted">
            {ws.performance
              ? t("rules.inspector.empty.description.performance")
              : t("rules.inspector.empty.description")}
          </p>
        </div>
      ) : (
        <div className="inspector-body">
          <header className="inspector-header">
            <h4>{rule.name}</h4>
            <p className="muted">{cat(rule.category)}</p>
            {rule.warning ? <p className="warning">{rule.warning}</p> : null}
            <span className={`risk-chip risk-${rule.risk}`}>{rule.risk}</span>
          </header>

          <section className="inspector-metrics">
            <p className="muted label">
              {ws.performance
                ? t("performance.action.impact_label")
                : t("rules.action.recoverable_label")}
            </p>
            <p className="metric-value mono">
              {displaysProcessCount(rule)
                ? ws.processCounts[rule.id] != null
                  ? t("performance.list.process_count", { count: ws.processCounts[rule.id]! })
                  : t("performance.list.analyze_hint")
                : displaysByteSize(rule)
                  ? formatBytes(ws.sizes[rule.id])
                  : (rule.estimate ?? "—")}
            </p>
          </section>

          {preview ? <InspectorPreview preview={preview} t={t} /> : null}

          <label className="inspector-include">
            <input
              type="checkbox"
              checked={ws.selectedRuleIds.has(rule.id)}
              onChange={() => ws.toggleSelected(rule.id)}
            />
            {t("rules.inspector.include")}
          </label>
        </div>
      )}
    </aside>
  );
}

function InspectorPreview({
  preview,
  t,
}: {
  preview: RulePreviewResult;
  t: ReturnType<typeof useI18n>["t"];
}) {
  if (preview.kind === "directory" && preview.directoryTargets) {
    return (
      <section>
        <h5>{t("rules.inspector.paths.title")}</h5>
        {preview.directoryTargets.length === 0 ? (
          <p className="muted">{t("rules.dry_run.no_paths")}</p>
        ) : (
          <ul className="preview-list">
            {preview.directoryTargets.map((target) => (
              <li key={target.path}>
                <code>{target.path}</code>
                {!target.exists ? (
                  <span className="muted"> · {t("rules.dry_run.path_missing")}</span>
                ) : null}
              </li>
            ))}
          </ul>
        )}
      </section>
    );
  }

  if (preview.kind === "command" && preview.commandLine) {
    return (
      <section>
        <h5>{t("rules.inspector.command.title")}</h5>
        <pre className="mono">{preview.commandLine}</pre>
      </section>
    );
  }

  if (preview.kind === "processes" && preview.processes) {
    return (
      <section>
        <h5>{t("performance.workspace.processes_section_title")}</h5>
        {preview.processes.length === 0 ? (
          <p className="muted">{t("rules.dry_run.no_paths")}</p>
        ) : (
          <ul className="preview-list">
            {preview.processes.map((proc) => (
              <li key={proc.pid} className="mono">
                {t("rules.dry_run.process_line", { pid: proc.pid, command: proc.commandLine })}
              </li>
            ))}
          </ul>
        )}
      </section>
    );
  }

  return null;
}
