import type { ScanRulesResult } from "@cleanspace/desktop-api";

export type RulesScanActivity =
  | { kind: "scanning"; current: number; total: number; ruleId?: string }
  | { kind: "completed" | "partial"; analyzed: number; total: number; deniedCount: number }
  | { kind: "failed"; message: string };

export function startScanActivity(total: number): RulesScanActivity {
  return { kind: "scanning", current: 0, total };
}

export function progressScanActivity(
  current: number,
  total: number,
  ruleId?: string,
): RulesScanActivity {
  return { kind: "scanning", current, total, ...(ruleId ? { ruleId } : {}) };
}

export function completeScanActivity(
  result: ScanRulesResult,
  total: number,
): RulesScanActivity {
  const analyzed = new Set([
    ...Object.keys(result.sizes),
    ...Object.keys(result.processCounts),
  ]).size;
  const deniedCount = result.deniedPaths.length;
  return {
    kind: deniedCount > 0 ? "partial" : "completed",
    analyzed,
    total,
    deniedCount,
  };
}
