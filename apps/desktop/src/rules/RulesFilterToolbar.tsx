import { useState, useRef, useEffect } from "react";
import type { RuleSummary } from "@cleanspace/desktop-api";
import type { useI18n } from "../i18n/useI18n";
import type { RulesWorkspaceState } from "./useRulesWorkspace";

type T = ReturnType<typeof useI18n>["t"];

type Props = {
  ws: RulesWorkspaceState;
  t: T;
  cat: (category: string) => string;
};

type FancySelectProps = {
  value: string;
  onChange: (value: string) => void;
  options: { value: string; label: string }[];
  placeholder?: string;
  className?: string;
};

export function FancySelect({ value, onChange, options, placeholder, className }: FancySelectProps) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleOuterClick = (e: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener("mousedown", handleOuterClick);
    return () => document.removeEventListener("mousedown", handleOuterClick);
  }, []);

  const selectedOption = options.find((o) => o.value === value) || options[0];

  return (
    <div className={`fancy-select-container ${className || ""}`} ref={containerRef}>
      <button
        type="button"
        className="select-trigger"
        onClick={() => setIsOpen(!isOpen)}
        aria-haspopup="listbox"
        aria-expanded={isOpen}
      >
        <span>{selectedOption ? selectedOption.label : placeholder}</span>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="14"
          height="14"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          className="select-trigger-icon"
        >
          <path d="m6 9 6 6 6-6" />
        </svg>
      </button>
      {isOpen && (
        <div className="select-content" role="listbox">
          <div className="select-viewport">
            {options.map((opt) => (
              <div
                key={opt.value}
                className={`select-item ${opt.value === value ? "selected" : ""}`}
                role="option"
                aria-selected={opt.value === value}
                onClick={() => {
                  onChange(opt.value);
                  setIsOpen(false);
                }}
              >
                <span>{opt.label}</span>
                {opt.value === value && (
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    width="12"
                    height="12"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    className="select-item-indicator"
                  >
                    <path d="M20 6 9 17l-5-5" />
                  </svg>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}

export function RulesFilterToolbar({ ws, t, cat }: Props) {
  const categoryOptions = [
    { value: "", label: t("rules.filter.all_categories") },
    ...ws.categories.map((category) => ({
      value: category,
      label: cat(category),
    })),
  ];

  const sortOptions = [
    { value: "impact", label: t("rules.sort.impact") },
    { value: "name", label: t("rules.sort.name") },
    { value: "category", label: t("rules.sort.category") },
    { value: "risk", label: t("rules.sort.risk") },
  ];

  return (
    <div className="rules-filter">
      <div className="rules-filter-left">
        <input
          className="search"
          value={ws.search}
          onChange={(e) => ws.setSearch(e.target.value)}
          placeholder={t("rules.filter.search_placeholder")}
        />
        {ws.showCategoryColumn && (
          <FancySelect
            value={ws.categoryFilter}
            onChange={ws.setCategoryFilter}
            options={categoryOptions}
            placeholder={t("rules.filter.all_categories")}
          />
        )}
        <FancySelect
          value={ws.sortKey}
          onChange={(val) => ws.setSortKey(val as RulesWorkspaceState["sortKey"])}
          options={sortOptions}
          className="sort-select"
        />
        <span className="muted filter-meta">
          {t("rules.filter.visible", { visible: ws.visibleRules.length, total: ws.rules.length })}
          {ws.selectedInViewCount > 0
            ? ` · ${t("rules.filter.selected_in_view", { count: ws.selectedInViewCount })}`
            : ""}
        </span>
      </div>
      <div className="rules-filter-right">
        <div className="segmented-control">
          <button type="button" className="segment" onClick={ws.selectAll}>
            {t("rules.action.select_all")}
          </button>
          <button type="button" className="segment" onClick={ws.selectAllVisible}>
            {t("rules.action.select_filtered")}
          </button>
          <button type="button" className="segment" onClick={ws.selectNone}>
            {t("rules.action.select_none")}
          </button>
        </div>
      </div>
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
          <th aria-label={t("rules.table.select")} />
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
      className={`${focused ? "focused " : ""}${selected ? "queued" : ""}`.trim() || undefined}
      onClick={() => ws.focusRule(rule.id)}
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
