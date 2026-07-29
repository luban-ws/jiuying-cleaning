import { describe, expect, it } from "vitest";
import { formatBytes, volumeUsageStats } from "./format";

describe("formatBytes", () => {
  it("formats compact file sizes without byte suffix", () => {
    expect(formatBytes(0)).toBe("0 B");
    expect(formatBytes(1024)).toBe("1 KB");
    expect(formatBytes(1_099_511_627_776)).toMatch(/1(\.0)? TB/);
  });

  it("returns dash for unknown", () => {
    expect(formatBytes(null)).toBe("—");
    expect(formatBytes(undefined)).toBe("—");
  });
});

describe("volumeUsageStats", () => {
  it("computes used and percents when capacity known", () => {
    const stats = volumeUsageStats(1_000_000, 400_000);
    expect(stats.used).toBe(600_000);
    expect(stats.usedPercent).toBe(60);
    expect(stats.freePercent).toBe(40);
    expect(stats.freeKnown).toBe(true);
  });

  it("marks free unknown when missing", () => {
    const stats = volumeUsageStats(1_000_000, null);
    expect(stats.used).toBeNull();
    expect(stats.freeKnown).toBe(false);
  });
});
