/** 与 Swift `SpaceFormat` / `ByteCountFormatter.file` 语义接近。 */
const BYTE_UNITS = ["B", "KB", "MB", "GB", "TB", "PB"] as const;

export function formatBytes(bytes?: number | null): string {
  if (bytes == null) return "—";
  if (bytes === 0) return "0 B";

  const sign = bytes < 0 ? -1 : 1;
  let value = Math.abs(bytes);
  let unitIndex = 0;

  while (value >= 1024 && unitIndex < BYTE_UNITS.length - 1) {
    value /= 1024;
    unitIndex += 1;
  }

  const digits = value >= 100 || unitIndex === 0 ? 0 : value >= 10 ? 1 : 2;
  const prefix = sign < 0 ? "-" : "";
  const raw = value.toFixed(digits);
  const trimmed = raw.includes(".") ? raw.replace(/\.0+$/, "").replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "") : raw;
  return `${prefix}${trimmed} ${BYTE_UNITS[unitIndex]}`;
}

export function formatPercent(part: number, total: number): string {
  if (total <= 0) return "0%";
  return `${Math.round((part / total) * 100)}%`;
}

export type VolumeUsageStats = {
  total: number | null;
  free: number | null;
  used: number | null;
  usedPercent: number;
  freePercent: number;
  hasCapacity: boolean;
  freeKnown: boolean;
};

/** 卷容量统计（用于用量条与环形图）。 */
export function volumeUsageStats(
  totalBytes: number | null | undefined,
  freeBytes: number | null | undefined,
): VolumeUsageStats {
  const total = totalBytes ?? null;
  const free = freeBytes ?? null;

  if (total == null || total <= 0) {
    return {
      total,
      free,
      used: null,
      usedPercent: 0,
      freePercent: 0,
      hasCapacity: false,
      freeKnown: free != null,
    };
  }

  if (free == null) {
    return {
      total,
      free: null,
      used: null,
      usedPercent: 0,
      freePercent: 0,
      hasCapacity: true,
      freeKnown: false,
    };
  }

  const used = Math.max(0, total - free);
  const usedPercent = Math.min(100, Math.max(0, (used / total) * 100));
  const freePercent = Math.min(100, Math.max(0, (free / total) * 100));

  return {
    total,
    free,
    used,
    usedPercent,
    freePercent,
    hasCapacity: true,
    freeKnown: true,
  };
}
