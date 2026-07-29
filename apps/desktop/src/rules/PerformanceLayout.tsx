import type { RuleSummary } from "@cleanspace/desktop-api";
import type { useI18n } from "../i18n/useI18n";
import type { RulesWorkspaceState } from "./useRulesWorkspace";

type Props = {
  ws: RulesWorkspaceState;
  t: ReturnType<typeof useI18n>["t"];
};

export function PerformanceLayout({ ws, t }: Props) {
  const focused = ws.focusedRule ?? ws.rules[0] ?? null;

  return (
    <div className="performance-layout">
      <h3 className="section-title">{t("performance.workspace.actions_section_title")}</h3>
      <div className="performance-cards">
        {ws.rules.map((rule) => (
          <PerformanceCard
            key={rule.id}
            rule={rule}
            included={ws.selectedRuleIds.has(rule.id)}
            focused={ws.focusedRuleId === rule.id}
            processCount={ws.processCounts[rule.id]}
            onToggle={() => ws.toggleSelected(rule.id)}
            onFocus={() => ws.focusRule(rule.id)}
            t={t}
          />
        ))}
      </div>
      {focused ? (
        <>
          <h3 className="section-title">{t("performance.workspace.processes_section_title")}</h3>
          <div className="card performance-detail">
            <h4>{focused.name}</h4>
            <p className="mono">
              {ws.processCounts[focused.id] != null
                ? t("performance.list.process_count", { count: ws.processCounts[focused.id]! })
                : t("performance.list.analyze_hint")}
            </p>
            {focused.warning ? <p className="warning">{focused.warning}</p> : null}
          </div>
        </>
      ) : null}
    </div>
  );
}

function PerformanceCard({
  rule,
  included,
  focused,
  processCount,
  onToggle,
  onFocus,
  t,
}: {
  rule: RuleSummary;
  included: boolean;
  focused: boolean;
  processCount?: number;
  onToggle: () => void;
  onFocus: () => void;
  t: ReturnType<typeof useI18n>["t"];
}) {
  return (
    <article
      className={`performance-card card${focused ? " focused" : ""}`}
      onClick={onFocus}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === "Enter" || e.key === " ") onFocus();
      }}
    >
      <label className="performance-card-check" onClick={(e) => e.stopPropagation()}>
        <input type="checkbox" checked={included} onChange={onToggle} aria-label={rule.name} />
      </label>
      <div className="performance-card-body">
        <h4>{rule.name}</h4>
        {rule.warning ? <p className="warning">{rule.warning}</p> : null}
        <p className="mono metric">
          {processCount != null
            ? t("performance.list.process_count", { count: processCount })
            : t("performance.list.analyze_hint")}
        </p>
      </div>
    </article>
  );
}
