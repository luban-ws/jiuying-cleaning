type Props = {
  percent: number;
  color: string;
  size?: number;
  label?: string;
};

export function DonutChart({ percent, color, size = 120, label }: Props) {
  const clamped = Math.max(0, Math.min(100, percent));
  const stroke = 12;
  const radius = (size - stroke) / 2;
  const circumference = 2 * Math.PI * radius;
  const offset = circumference * (1 - clamped / 100);

  return (
    <div className="donut-wrap" style={{ width: size, height: size }} role="img" aria-label={label}>
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`}>
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          className="donut-track"
          stroke="var(--donut-track)"
          strokeWidth={stroke}
        />
        <circle
          cx={size / 2}
          cy={size / 2}
          r={radius}
          fill="none"
          stroke={color}
          strokeWidth={stroke}
          strokeDasharray={circumference}
          strokeDashoffset={offset}
          strokeLinecap="round"
          transform={`rotate(-90 ${size / 2} ${size / 2})`}
        />
      </svg>
      <span className="donut-center">{clamped.toFixed(0)}%</span>
    </div>
  );
}

export function formatBps(bps: number): string {
  if (bps <= 0) return "0 B/s";
  return new Intl.NumberFormat(undefined, {
    style: "unit",
    unit: "byte",
    notation: "compact",
    maximumFractionDigits: 1,
  }).format(bps) + "/s";
}
