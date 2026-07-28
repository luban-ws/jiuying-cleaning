export type WorkspaceScope = "rules" | "ai_tools_space" | "performance";

export type RuleSummary = {
  id: string;
  name: string;
  category: string;
  risk: string;
  type: string;
  warning?: string | null;
  estimate?: string | null;
};

export type ScanRulesResult = {
  sizes: Record<string, number>;
  processCounts: Record<string, number>;
  deniedPaths: string[];
};

export type RulePreviewResult = {
  kind: string;
  directoryTargets?: { path: string; exists: boolean }[];
  commandLine?: string;
  processes?: { pid: number; commandLine: string }[];
};

export type CleanRulesResult = {
  items: { ruleId: string; success: boolean; message: string }[];
};

export type VolumeSummary = {
  id: string;
  name: string;
  path: string;
  totalBytes: number | null;
  freeBytes: number | null;
};

export type VolumeAccounting = {
  volumeUsedBytes: number | null;
  topLevelSum: number;
  unaccountedBytes: number | null;
};

export type VolumeScanResult = {
  folders: { name: string; path: string; bytes: number }[];
  deniedPaths: string[];
  accounting?: VolumeAccounting | null;
};

export type MetricsSnapshot = {
  cpuPercent: number;
  memoryPercent: number;
  memoryUsedBytes: number;
  memoryTotalBytes: number;
  networkUpBps: number;
  networkDownBps: number;
};

export type MetricsCpuTicks = {
  user: number;
  system: number;
  idle: number;
  nice: number;
};

export type MetricsNetworkCounters = {
  bytesIn: number;
  bytesOut: number;
};

export type MetricsSnapshotPayload = {
  snapshot: MetricsSnapshot;
  ticks: MetricsCpuTicks;
  network: MetricsNetworkCounters;
};

export type DockerDiskUsageResult = {
  summaryOutput: string;
  verboseOutput: string;
  failed: boolean;
};

export type DockerDfSummaryRow = {
  resourceType: string;
  total: string;
  active: string;
  size: string;
  reclaimable: string;
};

export type DockerDfDetailSection = {
  id: string;
  title: string;
  prefixLines: string[];
  columnTitles: string[];
  rows: string[][];
  orphanLines: string[];
};

export type DockerDiskUsageParsed = {
  summaryRows: DockerDfSummaryRow[];
  detailSections: DockerDfDetailSection[];
  summaryCommandFailed: boolean;
  verboseCommandFailed: boolean;
  fatalErrorText: string | null;
  rawSummary: string;
  rawVerbose: string;
};

export type DockerDesktopSizeRow = {
  label: string;
  path: string;
  bytes: number;
};

export type DockerPresetSummary = {
  id: string;
  title: string;
  subtitle: string;
  isDestructive: boolean;
};

export type DockerPresetRunResult = {
  log: string;
  success: boolean;
};

export type OpenPathResult = { success: boolean };

export type FdaBannerResult = { shouldShow: boolean; suppressed: boolean };

export type VolumeScanJobStatus = {
  state: IPCJobState;
  result?: VolumeScanResult | null;
  error?: string | null;
};

export type RulePreviewJobStatus = {
  state: IPCJobState;
  result?: RulePreviewResult | null;
  error?: string | null;
};

export type RulesCleanJobStatus = {
  state: IPCJobState;
  current: number;
  total: number;
  currentRuleId: string | null;
  result?: CleanRulesResult | null;
  error?: string | null;
};

export type DockerRefreshResult = {
  df: DockerDiskUsageParsed;
  desktop: DockerDesktopSizeRow[];
};

export type DockerRefreshJobStatus = {
  state: IPCJobState;
  result?: DockerRefreshResult | null;
  error?: string | null;
};

export type DockerPresetJobStatus = {
  state: IPCJobState;
  result?: DockerPresetRunResult | null;
  error?: string | null;
};

export type IPCJobState = "running" | "completed" | "failed";
