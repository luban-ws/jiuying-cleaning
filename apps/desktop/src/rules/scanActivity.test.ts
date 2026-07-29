import { describe, expect, it } from "vitest";
import {
  completeScanActivity,
  progressScanActivity,
  startScanActivity,
} from "./scanActivity";

describe("scan activity", () => {
  it("starts at zero and reports the active rule during progress", () => {
    expect(startScanActivity(4)).toEqual({
      kind: "scanning",
      current: 0,
      total: 4,
    });
    expect(progressScanActivity(2, 4, "browser-cache")).toEqual({
      kind: "scanning",
      current: 2,
      total: 4,
      ruleId: "browser-cache",
    });
  });

  it("keeps a completed summary after every rule is analyzed", () => {
    expect(
      completeScanActivity(
        {
          sizes: { "browser-cache": 2048 },
          processCounts: { "mcp-leaked-processes": 2 },
          deniedPaths: [],
        },
        2,
      ),
    ).toEqual({
      kind: "completed",
      analyzed: 2,
      total: 2,
      deniedCount: 0,
    });
  });

  it("reports a partial result when paths were denied", () => {
    expect(
      completeScanActivity(
        {
          sizes: { "browser-cache": 2048 },
          processCounts: {},
          deniedPaths: ["/Library/Caches", "/private/var"],
        },
        3,
      ),
    ).toEqual({
      kind: "partial",
      analyzed: 1,
      total: 3,
      deniedCount: 2,
    });
  });
});
