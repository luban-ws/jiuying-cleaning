import { NavLink } from "react-router-dom";
import logoImg from "./assets/logo.png";
import { PersistentPage } from "./components/PersistentPage";
import {
  IconAiTools,
  IconDocker,
  IconMonitor,
  IconPerformance,
  IconRules,
  IconVolumes,
} from "./components/icons";
import { useI18n } from "./i18n/useI18n";
import { DockerPage } from "./pages/DockerPage";
import { MonitorPage } from "./pages/MonitorPage";
import { RulesPage } from "./pages/RulesPage";
import { VolumesPage } from "./pages/VolumesPage";

const NAV_ICONS = {
  volumes: IconVolumes,
  docker: IconDocker,
  monitor: IconMonitor,
  rules: IconRules,
  aiTools: IconAiTools,
  performance: IconPerformance,
} as const;

export function App() {
  const { t } = useI18n();

  const GROUPS = [
    {
      label: t("nav.group.resources"),
      items: [
        { to: "/volumes", label: t("nav.volumes"), icon: NAV_ICONS.volumes },
        { to: "/docker", label: t("nav.docker"), icon: NAV_ICONS.docker },
        { to: "/monitor", label: t("nav.monitor"), icon: NAV_ICONS.monitor },
      ],
    },
    {
      label: t("nav.group.space"),
      items: [
        { to: "/rules", label: t("nav.rules"), icon: NAV_ICONS.rules },
        { to: "/ai-tools", label: t("nav.aiTools"), icon: NAV_ICONS.aiTools },
        { to: "/performance", label: t("nav.performance"), icon: NAV_ICONS.performance },
      ],
    },
  ] as const;

  return (
    <div className="shell">
      <aside className="sidebar" aria-label={t("nav.group.resources")}>
        <div className="app-brand">
          <span className="app-brand-mark" aria-hidden style={{ background: "none" }}>
            <img src={logoImg} alt="Cleaning" style={{ width: "100%", height: "100%", borderRadius: "inherit", objectFit: "cover" }} />
          </span>
          <div className="app-brand-text">
            <p className="app-brand-name">Cleaning</p>
            <p className="app-brand-tag">{t("nav.group.space")}</p>
          </div>
        </div>
        <div className="sidebar-nav">
          <nav>
            {GROUPS.map((group) => (
              <div key={group.label} className="nav-group">
                <p className="nav-group-label">{group.label}</p>
                {group.items.map((item) => (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    className={({ isActive }) => (isActive ? "nav active" : "nav")}
                  >
                    <span className="nav-icon" aria-hidden>
                      <item.icon />
                    </span>
                    <span className="nav-label">{item.label}</span>
                  </NavLink>
                ))}
              </div>
            ))}
          </nav>
        </div>
      </aside>
      <main className="main">
        <PersistentPage path="/volumes" alsoActive={["/"]}>
          <VolumesPage />
        </PersistentPage>
        <PersistentPage path="/rules">
          <RulesPage scope="rules" />
        </PersistentPage>
        <PersistentPage path="/ai-tools">
          <RulesPage scope="ai_tools_space" />
        </PersistentPage>
        <PersistentPage path="/performance">
          <RulesPage scope="performance" />
        </PersistentPage>
        <PersistentPage path="/docker">
          <DockerPage />
        </PersistentPage>
        <PersistentPage path="/monitor">
          <MonitorPage />
        </PersistentPage>
      </main>
    </div>
  );
}
