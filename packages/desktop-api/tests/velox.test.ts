import { afterEach, describe, expect, it, vi } from "vitest";
import { veloxInvoke } from "../src/velox";

describe("veloxInvoke", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    delete (globalThis as { Velox?: unknown }).Velox;
  });

  it("uses window.Velox.invoke when present", async () => {
    const invoke = vi.fn().mockResolvedValue(["rule-a"]);
    vi.stubGlobal("Velox", { invoke });

    const result = await veloxInvoke<string[]>("list_rules", { scope: "rules" });
    expect(result).toEqual(["rule-a"]);
    expect(invoke).toHaveBeenCalledWith("list_rules", { scope: "rules" });
  });

  it("falls back to fetch ipc protocol", async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      json: async () => ({ result: { ok: true } }),
    });
    vi.stubGlobal("fetch", fetchMock);

    const result = await veloxInvoke<{ ok: boolean }>("ping");
    expect(result).toEqual({ ok: true });
    expect(fetchMock).toHaveBeenCalledWith(
      "ipc://localhost/ping",
      expect.objectContaining({ method: "POST" }),
    );
  });

  it("throws when response contains error", async () => {
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({
      json: async () => ({ error: "bad request" }),
    }));

    await expect(veloxInvoke("bad")).rejects.toThrow("bad request");
  });
});
