import type { RuleSummary } from "@cleanspace/desktop-api";
import type { useI18n } from "../i18n/useI18n";
import type { RulesWorkspaceState } from "./useRulesWorkspace";

type T = ReturnType<typeof useI18n>["t"];

type Props = {
  ws: RulesWorkspaceState;
  t: T;
  cat: (category: string) => string;
};

export function RulesFilterToolbar({ ws, t, cat }: Props) {
  return (
    <div className="rules-filter">
      <input
        className="search"
        value={ws.search}
        onChange={(e) => ws.setSearch(e.target.value)}
        placeholder={t("rules.filter.search_placeholder")}
      />
      {ws.showCategoryColumn && (
        <select
          className="select"
          value={ws.categoryFilter}
          onChange={(e) => ws.setCategoryFilter(e.target.value)}
          aria-label={t("rules.filter.category_label")}
        >
          <option value="">{t("rules.filter.all_categories")}</option>
          {ws.categories.map((category) => (
            <option key={category} value={category}>
              {cat(category)}
            </option>
          ))}
        </select>
      )}
      <select
        className="select sort-select"
        value={ws.sortKey}
        onChange={(e) => ws.setSortKey(e.target.value as RulesWorkspaceState["sortKey"])}
        aria-label={t("rules.filter.sort_label")}
      >
        <option value="impact">{t("rules.sort.impact")}</option>
        <option value="name">{t("rules.sort.name")}</option>
        <option value="category">{t("rules.sort.category")}</option>
        <option value="risk">{t("rules.sort.risk")}</option>
      </select>
      <span className="muted filter-meta">
        {t("rules.filter.visible", { visible: ws.visibleRules.length, total: ws.rules.length })}
        {ws.selectedInViewCount > 0
          ? ` · ${t("rules.filter.selected_in_view", { count: ws.selectedInViewCount })}`
          : ""}
      </span>
      <button type="button" className="btn ghost" onClick={ws.selectAllVisible}>
        {t("rules.action.select_filtered")}
      </button>
      <button type="button" className="btn ghost" onClick={ws.selectAll}>
        {t("rules.action.select_all")}
      </button>
      <button type="button" className="btn ghost" onClick={ws.selectNone}>
        {t("rules.action.select_none")}
      </button>
    </div>
  );
}

type TableProps = Props & {
  cat: ReturnType<typeof useI18n>["cat"];
  formatBytes: (n?: number) => string;
};

export function RulesTable({ ws, t, cat, formatBytes }: TableProps) {
  if (ws.visibleRules.length === 0) {
    return (
      <div className="empty-state">
        <h3>{t("rules.filter.no_results.title")}</h3>
        <p className="muted">{t("rules.filter.no_results.description")}</p>
      </div>
    );
  }

  return (
    <table className="table rules-table">
      <thead>
        <tr>
          <th aria-label="Select" />
          {ws.showCategoryColumn && <th>{t("rules.table.category")}</th>}
          <th>{t("rules.sort.name")}</th>
          <th>{t("rules.sort.risk")}</th>
          <th>{ws.performance ? t("performance.action.impact_label") : t("chart.table.sum")}</th>
          {!ws.performance && <th>{t("rules.table.type")}</th>}
        </tr>
      </thead>
      <tbody>
        {ws.visibleRules.map((rule) => (
          <RulesTableRow
            key={rule.id}
            rule={rule}
            ws={ws}
            t={t}
            cat={cat}
            formatBytes={formatBytes}
          />
        ))}
      </tbody>
    </table>
  );
}

function RulesTableRow({
  rule,
  ws,
  t,
  cat,
  formatBytes,
}: {
  rule: RuleSummary;
  ws: RulesWorkspaceState;
  t: T;
  cat: (c: string) => string;
  formatBytes: (n?: number) => string;
}) {
  const focused = ws.focusedRuleId === rule.id;
  const selected = ws.selectedRuleIds.has(rule.id);
  const processCount = ws.processCounts[rule.id];
  const bytes = ws.sizes[rule.id];

  const metric =
    rule.id === "mcp-leaked-processes"
      ? processCount != null
        ? t("performance.list.process_count", { count: processCount })
        : t("performance.list.analyze_hint")
      : formatBytes(bytes);

  return (
    <tr
      className={focused ? "focused" : undefined}
      onClick={() => ws.setFocusedRuleId(rule.id)}
    >
      <td onClick={(e) => e.stopPropagation()}>
        <input
          type="checkbox"
          checked={selected}
          onChange={() => ws.toggleSelected(rule.id)}
          aria-label={rule.name}
        />
      </td>
      {ws.showCategoryColumn && <td>{cat(rule.category)}</td>}
      <td>
        <div className="rule-name">{rule.name}</div>
        <code className="muted rule-id">{rule.id}</code>
      </td>
      <td>
        <span className={`risk-chip risk-${rule.risk}`}>{rule.risk}</span>
      </td>
      <td className="mono">{metric}</td>
      {!ws.performance && (
        <td>{rule.type === "dir" ? t("rules.table.type.path") : t("rules.table.type.command")}</td>
      )}
    </tr>
  );
}
