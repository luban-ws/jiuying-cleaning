import { afterEach, describe, expect, it, vi } from "vitest";
import { pollJobUntilDone, runAsyncJob } from "../src/asyncJob";
import * as veloxModule from "../src/velox";

describe("asyncJob", () => {
  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("runAsyncJob polls until completed", async () => {
    const invoke = vi.spyOn(veloxModule, "veloxInvoke");
    invoke.mockResolvedValueOnce({ jobId: "job-1" });
    invoke.mockResolvedValueOnce({ state: "running" as const });
    invoke.mockResolvedValueOnce({ state: "completed" as const, result: { ok: true } });

    const result = await runAsyncJob(
      "scan_volume_start",
      { volume_path: "/" },
      "scan_volume_poll",
      (status: { state: "running" | "completed" | "failed"; result?: { ok: boolean } | null }) =>
        status.result,
    );

    expect(result).toEqual({ ok: true });
    expect(invoke).toHaveBeenCalledTimes(3);
    expect(invoke).toHaveBeenNthCalledWith(1, "scan_volume_start", { volume_path: "/" });
    expect(invoke).toHaveBeenNthCalledWith(2, "scan_volume_poll", { job_id: "job-1" });
  });

  it("pollJobUntilDone rejects on failed state", async () => {
    const invoke = vi.spyOn(veloxModule, "veloxInvoke");
    invoke.mockResolvedValueOnce({ state: "failed" as const, error: "boom" });

    await expect(
      pollJobUntilDone(
        "clean_rules_poll",
        "job-2",
        (status: { state: "running" | "completed" | "failed"; result?: unknown }) => status.result,
      ),
    ).rejects.toThrow("boom");
  });
});
