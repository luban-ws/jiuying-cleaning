import { useMemo } from "react";
import { categoryLabel, formatMessage, resolveLocale, type Locale, type MessageKey } from "./messages";

export function useI18n() {
  const locale = useMemo(() => resolveLocale(), []);

  const t = (key: MessageKey, vars?: Record<string, string | number>) =>
    formatMessage(locale, key, vars);

  const cat = (category: string) => categoryLabel(locale, category);

  return { locale, t, cat };
}

export type { Locale, MessageKey };
