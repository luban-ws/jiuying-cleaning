import type { VolumeSummary } from "@cleanspace/desktop-api";
import { BRAND_CHART } from "../branding";
import { formatBytes, volumeUsageStats } from "../rules/format";

type Props = {
  volumes: VolumeSummary[];
  selectedId: string;
  onSelect: (id: string) => void;
  freeLabel: (free: string) => string;
};

export function VolumePicker({ volumes, selectedId, onSelect, freeLabel }: Props) {
  return (
    <div className="volume-picker" role="listbox" aria-label="Volumes">
      {volumes.map((volume) => {
        const stats = volumeUsageStats(volume.totalBytes, volume.freeBytes);
        const selected = volume.id === selectedId;
        const pathLabel = volume.path.split("/").filter(Boolean).pop() ?? volume.path;

        return (
          <button
            key={volume.id}
            type="button"
            role="option"
            aria-selected={selected}
            className={`volume-picker-card${selected ? " selected" : ""}`}
            onClick={() => onSelect(volume.id)}
          >
            <div className="volume-picker-head">
              <span className="volume-picker-name">{volume.name}</span>
              {stats.hasCapacity && stats.freeKnown ? (
                <span className="volume-picker-pct mono">
                  {Math.round(stats.usedPercent)}%
                </span>
              ) : (
                <span className="volume-picker-pct muted">—</span>
              )}
            </div>
            <div className="volume-picker-track" aria-hidden>
              {stats.hasCapacity && stats.freeKnown ? (
                <>
                  <div
                    className="volume-picker-used"
                    style={{
                      width: `${stats.usedPercent}%`,
                      backgroundColor: selected ? BRAND_CHART.volume : "var(--brand-stone)",
                    }}
                  />
                  <div
                    className="volume-picker-free"
                    style={{ width: `${stats.freePercent}%` }}
                  />
                </>
              ) : (
                <div className="volume-picker-unknown" />
              )}
            </div>
            <div className="volume-picker-meta">
              <span className="mono">
                {stats.freeKnown ? freeLabel(formatBytes(stats.free)) : "—"}
              </span>
              <span className="muted mono">{formatBytes(stats.total)}</span>
            </div>
            {pathLabel !== volume.name && (
              <span className="volume-picker-path mono muted">{pathLabel}</span>
            )}
          </button>
        );
      })}
    </div>
  );
}
