import { veloxInvoke, type FdaBannerResult } from "@cleanspace/desktop-api";
import { useEffect, useState } from "react";
import type { MessageKey } from "../i18n/messages";

type Props = {
  deniedPaths: string[];
  t: (key: MessageKey, vars?: Record<string, string | number>) => string;
  onDismiss: () => void;
};

export function FullDiskAccessBanner({ deniedPaths, t, onDismiss }: Props) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    if (deniedPaths.length === 0) {
      setVisible(false);
      return;
    }
    void veloxInvoke<FdaBannerResult>("fda_should_show_banner", { denied_paths: deniedPaths }).then(
      (result) => setVisible(result.shouldShow),
    );
  }, [deniedPaths]);

  if (!visible) return null;

  return (
    <div className="fda-banner" role="status">
      <span>{t("rules.fda.banner")}</span>
      <div className="fda-actions">
        <button
          type="button"
          className="btn ghost"
          onClick={() => void veloxInvoke("fda_open_settings", {})}
        >
          {t("rules.fda.open_settings")}
        </button>
        <button
          type="button"
          className="btn ghost"
          onClick={() => {
            void veloxInvoke("fda_suppress_guidance", {}).then(onDismiss);
            setVisible(false);
          }}
        >
          {t("rules.fda.dismiss")}
        </button>
      </div>
    </div>
  );
}
