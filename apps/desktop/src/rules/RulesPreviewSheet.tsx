import { useEffect, useState } from "react";
import {
  runAsyncJob,
  type IPCJobHandle,
  type RulePreviewJobStatus,
  type RulePreviewResult,
  type RuleSummary,
} from "@cleanspace/desktop-api";
import type { useI18n } from "../i18n/useI18n";

type Props = {
  open: boolean;
  rules: RuleSummary[];
  selectedIds: Set<string>;
  onClose: () => void;
  t: ReturnType<typeof useI18n>["t"];
};

export function RulesPreviewSheet({ open, rules, selectedIds, onClose, t }: Props) {
  const selected = rules.filter((r) => selectedIds.has(r.id));

  if (!open) return null;

  return (
    <div className="modal-backdrop" onClick={onClose}>
      <div className="modal preview-sheet" onClick={(e) => e.stopPropagation()} role="dialog">
        <header className="preview-header">
          <h2>{t("rules.dry_run.sheet_title")}</h2>
          <button type="button" className="btn ghost" onClick={onClose}>
            {t("common.ok")}
          </button>
        </header>
        <p className="muted">{t("rules.dry_run.disclaimer")}</p>
        <div className="preview-sections">
          {selected.map((rule) => (
            <RulePreviewSection key={rule.id} rule={rule} t={t} />
          ))}
        </div>
      </div>
    </div>
  );
}

function RulePreviewSection({
  rule,
  t,
}: {
  rule: RuleSummary;
  t: ReturnType<typeof useI18n>["t"];
}) {
  const [preview, setPreview] = useState<RulePreviewResult | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    void runAsyncJob<IPCJobHandle, RulePreviewJobStatus, RulePreviewResult>(
      "preview_rule_start",
      { rule_id: rule.id },
      "preview_rule_poll",
      (status) => status.result,
    )
      .then((result) => {
        if (!cancelled) setPreview(result);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [rule.id]);

  return (
    <section className="preview-section">
      <h3>{rule.name}</h3>
      {loading ? <p className="muted">{t("rules.dry_run.loading_processes")}</p> : null}
      {!loading && preview?.kind === "directory" ? (
        <ul className="preview-list">
          {(preview.directoryTargets ?? []).map((target) => (
            <li key={target.path}>
              <code>{target.path}</code>
              {!target.exists ? <span className="muted"> · {t("rules.dry_run.path_missing")}</span> : null}
            </li>
          ))}
          {(preview.directoryTargets ?? []).length === 0 ? (
            <li className="muted">{t("rules.dry_run.no_paths")}</li>
          ) : null}
        </ul>
      ) : null}
      {!loading && preview?.kind === "command" ? (
        <pre className="mono">{preview.commandLine}</pre>
      ) : null}
      {!loading && preview?.kind === "processes" ? (
        <ul className="preview-list">
          {(preview.processes ?? []).map((proc) => (
            <li key={proc.pid} className="mono">
              {t("rules.dry_run.process_line", { pid: proc.pid, command: proc.commandLine })}
            </li>
          ))}
        </ul>
      ) : null}
    </section>
  );
}
