import type { RuleSummary, WorkspaceScope } from "@cleanspace/desktop-api";

/** MCP 泄漏进程规则 id（与 CleanSpaceKit 一致）。 */
export const MCP_RULE_ID = "mcp-leaked-processes";

export const RISK_ORDER: Record<string, number> = {
  low: 0,
  medium: 1,
  high: 2,
};

export type SortKey = "name" | "category" | "impact" | "risk";

export function isPerformanceScope(scope: WorkspaceScope): boolean {
  return scope === "performance";
}

export function displaysProcessCount(rule: RuleSummary): boolean {
  return rule.id === MCP_RULE_ID;
}

export function displaysByteSize(rule: RuleSummary): boolean {
  return rule.type === "dir";
}

export function workspaceGuideKey(scope: WorkspaceScope):
  | "rules.workspace.guide.storage"
  | "rules.workspace.guide.ai_tools"
  | "rules.workspace.guide.performance" {
  switch (scope) {
    case "ai_tools_space":
      return "rules.workspace.guide.ai_tools";
    case "performance":
      return "rules.workspace.guide.performance";
    default:
      return "rules.workspace.guide.storage";
  }
}
