import type { RuleSummary } from "@cleanspace/desktop-api";
import { BRAND_CHART_SERIES } from "../branding";

export type ChartSlice = {
  id: string;
  label: string;
  bytes: number;
  color: string;
};

const CHART_COLORS = BRAND_CHART_SERIES;

/** 按分类汇总路径类规则的扫描体积（对齐 SpaceChartSliceBuilder.rulesCategorySlices）。 */
export function buildRulesCategorySlices(
  rules: RuleSummary[],
  scannedSizes: Record<string, number>,
  labelForCategory: (category: string) => string,
): ChartSlice[] {
  const byCategory: Record<string, number> = {};

  for (const rule of rules) {
    if (rule.type !== "dir") continue;
    const bytes = scannedSizes[rule.id];
    if (!bytes || bytes <= 0) continue;
    byCategory[rule.category] = (byCategory[rule.category] ?? 0) + bytes;
  }

  return Object.entries(byCategory)
    .map(([id, bytes]) => ({ id, bytes, label: labelForCategory(id) }))
    .sort((a, b) => b.bytes - a.bytes)
    .map((row, index) => ({
      ...row,
      color: CHART_COLORS[index % CHART_COLORS.length]!,
    }));
}
