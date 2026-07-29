import type { useI18n } from "../i18n/useI18n";
import type { RulesScanActivity } from "./scanActivity";

type Props = {
  activity: RulesScanActivity;
  performance: boolean;
  t: ReturnType<typeof useI18n>["t"];
  onDismiss: () => void;
};

export function RulesActivityBanner({ activity, performance, t, onDismiss }: Props) {
  const scanning = activity.kind === "scanning";

  return (
    <section
      className={`rules-activity rules-activity-${activity.kind}`}
      role="status"
      aria-live="polite"
    >
      <div className="rules-activity-copy">
        <strong>{activityTitle(activity, performance, t)}</strong>
        <span>{activityDetail(activity, t)}</span>
      </div>
      {scanning ? (
        <progress
          className="rules-activity-progress"
          value={activity.current}
          max={Math.max(activity.total, 1)}
        />
      ) : (
        <button
          type="button"
          className="rules-activity-dismiss"
          aria-label={t("rules.activity.dismiss")}
          onClick={onDismiss}
        >
          ×
        </button>
      )}
    </section>
  );
}

function activityTitle(
  activity: RulesScanActivity,
  performance: boolean,
  t: ReturnType<typeof useI18n>["t"],
) {
  if (activity.kind === "scanning") {
    return performance ? t("performance.scanning") : t("rules.scanning");
  }
  if (activity.kind === "completed") return t("rules.activity.completed_title");
  if (activity.kind === "partial") return t("rules.activity.partial_title");
  return t("rules.activity.failed_title");
}

function activityDetail(
  activity: RulesScanActivity,
  t: ReturnType<typeof useI18n>["t"],
) {
  switch (activity.kind) {
    case "scanning":
      return activity.ruleId
        ? t("rules.activity.progress_rule", {
            current: activity.current,
            total: activity.total,
            rule: activity.ruleId,
          })
        : t("rules.activity.progress", {
            current: activity.current,
            total: activity.total,
          });
    case "completed":
      return t("rules.activity.completed", {
        analyzed: activity.analyzed,
        total: activity.total,
      });
    case "partial":
      return t("rules.activity.partial", {
        analyzed: activity.analyzed,
        total: activity.total,
        denied: activity.deniedCount,
      });
    case "failed":
      return t("rules.activity.failed", { message: activity.message });
  }
}
