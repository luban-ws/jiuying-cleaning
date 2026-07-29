import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  listenVeloxEvent,
  runAsyncJob,
  unlistenVeloxEvent,
  veloxInvoke,
  type ScanCompleteEvent,
  type ScanErrorEvent,
  type ScanJobStatus,
  type ScanProgressEvent,
  type ScanStartResult,
  type IPCJobHandle,
  type CleanRulesResult,
  type RulePreviewResult,
  type RulePreviewJobStatus,
  type RulesCleanJobStatus,
  type RuleSummary,
  type ScanRulesResult,
  type WorkspaceScope,
} from "@cleanspace/desktop-api";
import {
  displaysByteSize,
  displaysProcessCount,
  isPerformanceScope,
  RISK_ORDER,
  type SortKey,
} from "./constants";
import {
  completeScanActivity,
  progressScanActivity,
  startScanActivity,
  type RulesScanActivity,
} from "./scanActivity";

type ConfirmState = { message: string; risky: boolean } | null;

export function useRulesWorkspace(scope: WorkspaceScope) {
  const [rules, setRules] = useState<RuleSummary[]>([]);
  const [selectedRuleIds, setSelectedRuleIds] = useState<Set<string>>(new Set());
  const [focusedRuleId, setFocusedRuleId] = useState<string | null>(null);
  const [inspectorOpen, setInspectorOpen] = useState(false);
  const [sizes, setSizes] = useState<Record<string, number>>({});
  const [processCounts, setProcessCounts] = useState<Record<string, number>>({});
  const [deniedPaths, setDeniedPaths] = useState<string[]>([]);
  const [showFdaBanner, setShowFdaBanner] = useState(false);
  const [fdaDismissed, setFdaDismissed] = useState(false);
  const [search, setSearch] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("impact");
  const [loading, setLoading] = useState(true);
  const [isScanning, setIsScanning] = useState(false);
  const [scanActivity, setScanActivity] = useState<RulesScanActivity | null>(null);
  const [isCleaning, setIsCleaning] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState("");
  const [confirm, setConfirm] = useState<ConfirmState>(null);
  const [cleanResult, setCleanResult] = useState<CleanRulesResult | null>(null);
  const [previewOpen, setPreviewOpen] = useState(false);
  const [focusedPreview, setFocusedPreview] = useState<RulePreviewResult | null>(null);
  const isScanningRef = useRef(false);
  const scanRafRef = useRef<number | null>(null);
  const pendingScanUiRef = useRef<ScanProgressEvent | null>(null);

  const performance = isPerformanceScope(scope);

  const loadRules = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const rows = await veloxInvoke<RuleSummary[]>("list_rules", { scope });
      setRules(rows);
      setSelectedRuleIds(new Set());
      setSizes({});
      setProcessCounts({});
      setDeniedPaths([]);
      setShowFdaBanner(false);
      setFdaDismissed(false);
      setScanActivity(null);
      setInspectorOpen(false);
      setFocusedRuleId((prev) => {
        if (prev && rows.some((r) => r.id === prev)) return prev;
        return rows[0]?.id ?? null;
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setLoading(false);
    }
  }, [scope]);

  useEffect(() => {
    void loadRules();
  }, [loadRules]);

  const categories = useMemo(() => {
    const set = new Set(rules.map((r) => r.category));
    return [...set].sort();
  }, [rules]);

  const showCategoryColumn = categories.length > 1;

  const filteredRules = useMemo(() => {
    const q = search.trim().toLowerCase();
    return rules.filter((rule) => {
      if (categoryFilter && rule.category !== categoryFilter) return false;
      if (!q) return true;
      return (
        rule.name.toLowerCase().includes(q) ||
        rule.id.toLowerCase().includes(q) ||
        rule.category.toLowerCase().includes(q)
      );
    });
  }, [rules, search, categoryFilter]);

  const visibleRules = useMemo(() => {
    const rows = [...filteredRules];
    rows.sort((a, b) => {
      switch (sortKey) {
        case "name":
          return a.name.localeCompare(b.name);
        case "category":
          return a.category.localeCompare(b.category) || a.name.localeCompare(b.name);
        case "risk":
          return (RISK_ORDER[b.risk] ?? 0) - (RISK_ORDER[a.risk] ?? 0);
        case "impact":
        default: {
          const impact = (id: string, rule: RuleSummary) => {
            if (displaysProcessCount(rule)) return processCounts[id] ?? -1;
            return sizes[id] ?? -1;
          };
          return impact(b.id, b) - impact(a.id, a) || a.name.localeCompare(b.name);
        }
      }
    });
    return rows;
  }, [filteredRules, sortKey, sizes, processCounts]);

  const focusedRule = useMemo(
    () => rules.find((r) => r.id === focusedRuleId) ?? null,
    [rules, focusedRuleId],
  );

  const selectedPathRules = useMemo(
    () => rules.filter((r) => selectedRuleIds.has(r.id) && r.type === "dir"),
    [rules, selectedRuleIds],
  );

  const selectedCommandRules = useMemo(
    () => rules.filter((r) => selectedRuleIds.has(r.id) && r.type === "command"),
    [rules, selectedRuleIds],
  );

  const selectedRecoverableBytes = useMemo(
    () =>
      rules
        .filter((r) => selectedRuleIds.has(r.id))
        .reduce((sum, r) => sum + (sizes[r.id] ?? 0), 0),
    [rules, selectedRuleIds, sizes],
  );

  const selectedProcessCount = useMemo(
    () =>
      rules
        .filter((r) => selectedRuleIds.has(r.id))
        .reduce((sum, r) => sum + (processCounts[r.id] ?? 0), 0),
    [rules, selectedRuleIds, processCounts],
  );

  const scannedMetricCount = useMemo(() => {
    if (performance) {
      return Object.values(processCounts).filter((n) => n > 0).length;
    }
    return Object.values(sizes).filter((n) => n > 0).length;
  }, [performance, sizes, processCounts]);

  const hasDirScanResults = useMemo(
    () => rules.some((r) => displaysByteSize(r) && (sizes[r.id] ?? 0) > 0),
    [rules, sizes],
  );

  const analyzedSelectedCount = useMemo(
    () =>
      rules.filter((r) => selectedRuleIds.has(r.id)).filter((r) => {
        if (displaysProcessCount(r)) return processCounts[r.id] != null;
        return sizes[r.id] != null;
      }).length,
    [rules, selectedRuleIds, sizes, processCounts],
  );

  const sizedSelectedPathCount = useMemo(
    () => selectedPathRules.filter((r) => sizes[r.id] != null).length,
    [selectedPathRules, sizes],
  );

  const selectedInViewCount = useMemo(
    () => visibleRules.filter((r) => selectedRuleIds.has(r.id)).length,
    [visibleRules, selectedRuleIds],
  );

  const toggleSelected = (id: string) => {
    setSelectedRuleIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const selectAllVisible = () => {
    setSelectedRuleIds((prev) => {
      const next = new Set(prev);
      visibleRules.forEach((r) => next.add(r.id));
      return next;
    });
  };

  const selectNone = () => setSelectedRuleIds(new Set());

  const selectAll = () => setSelectedRuleIds(new Set(rules.map((r) => r.id)));

  const focusRule = (id: string) => {
    setFocusedRuleId(id);
    setInspectorOpen(true);
  };

  /** RFC 010 D4：异步扫描；始终 poll 收尾，避免事件丢失导致 isScanning 卡死。 */
  const scanAll = async () => {
    if (rules.length === 0 || isScanningRef.current) return;
    isScanningRef.current = true;
    setIsScanning(true);
    setError("");
    setScanActivity(startScanActivity(rules.length));

    let progressListener: number | null = null;
    let completeListener: number | null = null;
    let errorListener: number | null = null;
    let pollTimer: ReturnType<typeof setInterval> | null = null;

    const cleanupListeners = () => {
      unlistenVeloxEvent(progressListener);
      unlistenVeloxEvent(completeListener);
      unlistenVeloxEvent(errorListener);
      if (pollTimer) clearInterval(pollTimer);
      if (scanRafRef.current != null) {
        cancelAnimationFrame(scanRafRef.current);
        scanRafRef.current = null;
      }
      pendingScanUiRef.current = null;
    };

    const flushScanUi = () => {
      const payload = pendingScanUiRef.current;
      if (!payload) return;
      pendingScanUiRef.current = null;
      setScanActivity(
        progressScanActivity(
          payload.current,
          payload.total,
          payload.ruleId ?? undefined,
        ),
      );
      setSizes(payload.sizes);
      setProcessCounts(payload.processCounts);
      setDeniedPaths(payload.deniedPaths);
      setShowFdaBanner(payload.deniedPaths.length > 0);
    };

    const scheduleScanUi = (payload: ScanProgressEvent) => {
      pendingScanUiRef.current = payload;
      if (scanRafRef.current != null) return;
      scanRafRef.current = requestAnimationFrame(() => {
        scanRafRef.current = null;
        flushScanUi();
      });
    };

    const applyPartial = (payload: ScanProgressEvent) => {
      scheduleScanUi(payload);
    };

    const finishSuccess = (result: ScanRulesResult, total: number) => {
      if (scanRafRef.current != null) {
        cancelAnimationFrame(scanRafRef.current);
        scanRafRef.current = null;
      }
      pendingScanUiRef.current = null;
      setSizes(result.sizes);
      setProcessCounts(result.processCounts);
      setDeniedPaths(result.deniedPaths);
      setShowFdaBanner(result.deniedPaths.length > 0);
      setScanActivity(completeScanActivity(result, total));
    };

    const pollIntervalMs = 300;
    const scanTimeoutMs = 30 * 60 * 1000;

    try {
      const start = await veloxInvoke<ScanStartResult>("scan_all_rules_start", { scope });
      setScanActivity(startScanActivity(start.total));

      await new Promise<void>((resolve, reject) => {
        let settled = false;
        const startedAt = Date.now();

        const settle = (fn: () => void) => {
          if (settled) return;
          settled = true;
          cleanupListeners();
          fn();
        };

        const handleStatus = (status: ScanJobStatus) => {
          if (status.state === "running") {
            applyPartial({
              jobId: start.jobId,
              current: status.current,
              total: status.total,
              ruleId: status.currentRuleId,
              sizes: status.sizes,
              processCounts: status.processCounts,
              deniedPaths: status.deniedPaths,
            });
            return;
          }
          if (pollTimer) {
            clearInterval(pollTimer);
            pollTimer = null;
          }
          if (status.state === "completed" && status.result) {
            finishSuccess(status.result, status.total);
            settle(() => resolve());
          } else if (status.state === "failed") {
            settle(() => reject(new Error(status.error ?? "scan failed")));
          }
        };

        progressListener = listenVeloxEvent<ScanProgressEvent>("scan_progress", (payload) => {
          if (payload.jobId !== start.jobId) return;
          applyPartial(payload);
        });

        completeListener = listenVeloxEvent<ScanCompleteEvent>("scan_complete", (payload) => {
          if (payload.jobId !== start.jobId) return;
          finishSuccess(payload.result, start.total);
          settle(() => resolve());
        });

        errorListener = listenVeloxEvent<ScanErrorEvent>("scan_error", (payload) => {
          if (payload.jobId !== start.jobId) return;
          settle(() => reject(new Error(payload.message)));
        });

        const pollOnce = () => {
          if (Date.now() - startedAt > scanTimeoutMs) {
            settle(() => reject(new Error("scan timed out")));
            return;
          }
          void veloxInvoke<ScanJobStatus>("scan_all_rules_poll", { job_id: start.jobId })
            .then(handleStatus)
            .catch((err) => {
              settle(() =>
                reject(err instanceof Error ? err : new Error(String(err))),
              );
            });
        };

        // 立即 poll：避免 job 在监听器注册前完成而永远等事件
        pollOnce();
        pollTimer = setInterval(pollOnce, pollIntervalMs);
      });
    } catch (err) {
      cleanupListeners();
      setScanActivity({
        kind: "failed",
        message: err instanceof Error ? err.message : String(err),
      });
    } finally {
      cleanupListeners();
      isScanningRef.current = false;
      setIsScanning(false);
    }
  };

  const openCleanConfirm = () => {
    const selected = rules.filter((r) => selectedRuleIds.has(r.id));
    const risky = selected.some((r) => r.risk === "medium" || r.risk === "high");
    setConfirm({
      risky,
      message: risky ? "risky" : String(selected.length),
    });
  };

  const runClean = async () => {
    setConfirm(null);
    setIsCleaning(true);
    setError("");
    const batch = [...selectedRuleIds];
    try {
      const result = await runAsyncJob<
        ScanStartResult,
        RulesCleanJobStatus,
        CleanRulesResult
      >("clean_rules_start", { rule_ids: batch }, "clean_rules_poll", (status) => status.result);
      setCleanResult(result);
      setSelectedRuleIds((prev) => {
        const next = new Set(prev);
        batch.forEach((id) => next.delete(id));
        return next;
      });
      if (focusedRuleId && batch.includes(focusedRuleId)) {
        setFocusedRuleId(rules.find((r) => !batch.includes(r.id))?.id ?? null);
      }
      setSizes((prev) => {
        const next = { ...prev };
        batch.forEach((id) => delete next[id]);
        return next;
      });
      setProcessCounts((prev) => {
        const next = { ...prev };
        batch.forEach((id) => delete next[id]);
        return next;
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : String(err));
    } finally {
      setIsCleaning(false);
    }
  };

  const loadPreview = async (ruleId: string) => {
    try {
      return await runAsyncJob<IPCJobHandle, RulePreviewJobStatus, RulePreviewResult>(
        "preview_rule_start",
        { rule_id: ruleId },
        "preview_rule_poll",
        (status) => status.result,
      );
    } catch {
      return null;
    }
  };

  useEffect(() => {
    if (!focusedRule || isScanningRef.current) {
      if (!focusedRule) setFocusedPreview(null);
      return;
    }
    let cancelled = false;
    void loadPreview(focusedRule.id).then((preview) => {
      if (!cancelled) setFocusedPreview(preview);
    });
    return () => {
      cancelled = true;
    };
  }, [focusedRule, isScanning]);

  return {
    scope,
    performance,
    rules,
    visibleRules,
    categories,
    showCategoryColumn,
    selectedRuleIds,
    focusedRule,
    focusedRuleId,
    focusRule,
    inspectorOpen,
    setInspectorOpen,
    sizes,
    processCounts,
    deniedPaths,
    showFdaBanner,
    setShowFdaBanner,
    fdaDismissed,
    setFdaDismissed,
    search,
    setSearch,
    categoryFilter,
    setCategoryFilter,
    sortKey,
    setSortKey,
    loading,
    isScanning,
    scanActivity,
    dismissScanActivity: () => setScanActivity(null),
    isCleaning,
    busy,
    error,
    confirm,
    setConfirm,
    cleanResult,
    setCleanResult,
    previewOpen,
    setPreviewOpen,
    focusedPreview,
    toggleSelected,
    selectAllVisible,
    selectNone,
    selectAll,
    scanAll,
    openCleanConfirm,
    runClean,
    selectedPathRules,
    selectedCommandRules,
    selectedRecoverableBytes,
    selectedProcessCount,
    scannedMetricCount,
    hasDirScanResults,
    analyzedSelectedCount,
    sizedSelectedPathCount,
    selectedInViewCount,
  };
}

export type RulesWorkspaceState = ReturnType<typeof useRulesWorkspace>;
