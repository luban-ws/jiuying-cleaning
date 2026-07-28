/**
 * JS mirror of branding/tokens.css — for SVG strokes & chart slices.
 * Keep hex values in sync when tokens.css changes.
 */
export const BRAND_CHART_SERIES = [
  "#d4af37",
  "#e6c158",
  "#a3a3a3",
  "#34d399",
  "#fbbf24",
  "#6b7280",
] as const;

export const BRAND_CHART = {
  volume: "#d4af37",
  network: "#64d2ff",
} as const;

export const BRAND_METRIC = {
  neutral: "#d4af37",
  warn: "#fbbf24",
  critical: "#f87171",
} as const;

/** Donut / gauge tint by utilization percent. */
export function metricTint(percent: number): string {
  if (percent >= 85) return BRAND_METRIC.critical;
  if (percent >= 65) return BRAND_METRIC.warn;
  return BRAND_METRIC.neutral;
}
