/** 字节格式化（与 Swift SpaceFormat 语义接近）。 */
export function formatBytes(bytes?: number | null): string {
  if (bytes == null || bytes <= 0) return "—";
  return new Intl.NumberFormat(undefined, {
    style: "unit",
    unit: "byte",
    notation: "compact",
    maximumFractionDigits: 1,
  }).format(bytes);
}

export function formatPercent(part: number, total: number): string {
  if (total <= 0) return "0%";
  return `${Math.round((part / total) * 100)}%`;
}
