import type { ReactNode } from "react";
import { matchPath, useLocation } from "react-router-dom";

type Props = {
  path: string;
  /** 额外视为激活的路径（如 `/` 对应 volumes）。 */
  alsoActive?: string[];
  children: ReactNode;
};

/** 侧栏切换时保持子树挂载，避免页面状态被卸载重置。 */
export function PersistentPage({ path, alsoActive = [], children }: Props) {
  const location = useLocation();
  const active =
    matchPath({ path, end: true }, location.pathname) != null ||
    alsoActive.some((p) => matchPath({ path: p, end: true }, location.pathname) != null);

  return (
    <div className="persistent-page" hidden={!active} aria-hidden={!active}>
      {children}
    </div>
  );
}
