/**
 * Velox IPC client — prefers `window.Velox.invoke`, falls back to `fetch(ipc://…)`.
 */

type VeloxWindow = {
  Velox?: {
    invoke: (command: string, args?: Record<string, unknown>) => Promise<unknown>;
  };
};

export async function veloxInvoke<T>(
  command: string,
  args: Record<string, unknown> = {},
): Promise<T> {
  const win = globalThis as typeof globalThis & VeloxWindow;
  if (win.Velox?.invoke) {
    return (await win.Velox.invoke(command, args)) as T;
  }

  const response = await fetch(`ipc://localhost/${command}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(args),
  });
  const data = (await response.json()) as { result?: T; error?: string };
  if (data.error) {
    throw new Error(data.error);
  }
  return data.result as T;
}
