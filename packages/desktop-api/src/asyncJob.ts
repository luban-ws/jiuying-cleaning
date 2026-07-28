import { veloxInvoke } from "./velox";

export type IPCJobState = "running" | "completed" | "failed";

export type IPCJobHandle = {
  jobId: string;
};

type PollOptions<TStatus> = {
  intervalMs?: number;
  timeoutMs?: number;
  onProgress?: (status: TStatus) => void;
};

const DEFAULT_POLL_MS = 300;
const DEFAULT_TIMEOUT_MS = 30 * 60 * 1000;

/** 轮询 async job 直至 completed；poll IPC 为瞬时读取。 */
export async function pollJobUntilDone<
  TStatus extends { state: IPCJobState; error?: string | null },
  TResult,
>(
  pollCommand: string,
  jobId: string,
  pickResult: (status: TStatus) => TResult | null | undefined,
  options?: PollOptions<TStatus>,
): Promise<TResult> {
  const intervalMs = options?.intervalMs ?? DEFAULT_POLL_MS;
  const timeoutMs = options?.timeoutMs ?? DEFAULT_TIMEOUT_MS;
  const startedAt = Date.now();

  return new Promise<TResult>((resolve, reject) => {
    let timer: ReturnType<typeof setInterval> | null = null;

    const finish = (fn: () => void) => {
      if (timer) clearInterval(timer);
      fn();
    };

    const pollOnce = async () => {
      if (Date.now() - startedAt > timeoutMs) {
        finish(() => reject(new Error("job timed out")));
        return;
      }
      try {
        const status = await veloxInvoke<TStatus>(pollCommand, { job_id: jobId });
        if (status.state === "running") {
          options?.onProgress?.(status);
          return;
        }
        if (status.state === "completed") {
          const result = pickResult(status);
          if (result != null) {
            finish(() => resolve(result));
          } else {
            finish(() => reject(new Error("job completed without result")));
          }
          return;
        }
        if (status.state === "failed") {
          finish(() => reject(new Error(status.error ?? "job failed")));
        }
      } catch (err) {
        finish(() => reject(err instanceof Error ? err : new Error(String(err))));
      }
    };

    void pollOnce();
    timer = setInterval(() => void pollOnce(), intervalMs);
  });
}

/** start 后立即 poll 直到完成。 */
export async function runAsyncJob<
  TStart extends IPCJobHandle,
  TStatus extends { state: IPCJobState; error?: string | null },
  TResult,
>(
  startCommand: string,
  startArgs: Record<string, unknown>,
  pollCommand: string,
  pickResult: (status: TStatus) => TResult | null | undefined,
  options?: PollOptions<TStatus>,
): Promise<TResult> {
  const start = await veloxInvoke<TStart>(startCommand, startArgs);
  return pollJobUntilDone<TStatus, TResult>(pollCommand, start.jobId, pickResult, options);
}
