import type { ScanRulesResult } from "./types";

type VeloxEventEnvelope<T> = {
  name: string;
  payload: T;
  id: number;
  timestamp: Date;
};

type VeloxEventsBridge = {
  listen: (eventName: string, handler: (event: VeloxEventEnvelope<unknown>) => void) => number;
  unlisten: (listenerId: number) => boolean;
};

const EVENT_BRIDGE_KEY = "__VELOX_EVENTS__";

function eventsBridge(): VeloxEventsBridge | null {
  const bridge = (globalThis as Record<string, unknown>)[EVENT_BRIDGE_KEY];
  if (!bridge || typeof bridge !== "object") return null;
  const listen = (bridge as VeloxEventsBridge).listen;
  if (typeof listen !== "function") return null;
  return bridge as VeloxEventsBridge;
}

/** 监听 Velox 原生推送到 WebView 的事件（需 DesktopApp 注入 event bridge）。 */
export function listenVeloxEvent<T>(
  eventName: string,
  handler: (payload: T) => void,
): number | null {
  const bridge = eventsBridge();
  if (!bridge) return null;
  return bridge.listen(eventName, (event) => handler(event.payload as T));
}

export function unlistenVeloxEvent(listenerId: number | null): void {
  if (listenerId == null) return;
  const bridge = eventsBridge();
  if (!bridge) return;
  bridge.unlisten(listenerId);
}

export type ScanProgressEvent = {
  jobId: string;
  current: number;
  total: number;
  ruleId: string | null;
  sizes: Record<string, number>;
  processCounts: Record<string, number>;
  deniedPaths: string[];
};

export type ScanCompleteEvent = {
  jobId: string;
  result: ScanRulesResult;
};

export type ScanErrorEvent = {
  jobId: string;
  message: string;
};

export type ScanStartResult = {
  jobId: string;
  total: number;
};

export type ScanJobStatus = {
  state: "running" | "completed" | "failed";
  current: number;
  total: number;
  currentRuleId: string | null;
  sizes: Record<string, number>;
  processCounts: Record<string, number>;
  deniedPaths: string[];
  result?: ScanRulesResult | null;
  error?: string | null;
};
