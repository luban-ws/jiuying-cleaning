export type Locale = "en" | "zh-Hans";

export type MessageKey =
  | "nav.volumes"
  | "nav.rules"
  | "nav.aiTools"
  | "nav.docker"
  | "nav.performance"
  | "nav.monitor"
  | "common.cancel"
  | "common.ok"
  | "category.system"
  | "category.browser"
  | "category.docker"
  | "category.ai_tools_space"
  | "category.performance"
  | "category.custom"
  | "rules.chart.card_title"
  | "rules.scan"
  | "rules.clean"
  | "rules.scanning"
  | "rules.cleaning"
  | "rules.dry_run"
  | "rules.alert.confirm.title"
  | "rules.alert.result.title"
  | "rules.confirm.clean_risky"
  | "rules.confirm.clean_safe"
  | "rules.workspace.guide.storage"
  | "rules.workspace.guide.ai_tools"
  | "rules.workspace.guide.performance"
  | "rules.overview.chip.total"
  | "rules.overview.chip.selected"
  | "rules.overview.chip.scanned"
  | "rules.filter.search_placeholder"
  | "rules.filter.category_label"
  | "rules.filter.all_categories"
  | "rules.filter.sort_label"
  | "rules.filter.visible"
  | "rules.filter.selected_in_view"
  | "rules.filter.no_results.title"
  | "rules.filter.no_results.description"
  | "rules.sort.name"
  | "rules.sort.category"
  | "rules.sort.impact"
  | "rules.sort.risk"
  | "rules.action.select_all"
  | "rules.action.select_none"
  | "rules.action.select_filtered"
  | "rules.action.recoverable_label"
  | "rules.action.metric.placeholder"
  | "rules.action.metric.tap_analyze"
  | "rules.action.caption.none"
  | "rules.action.caption.counts"
  | "rules.table.category"
  | "rules.table.type"
  | "rules.table.type.path"
  | "rules.table.type.command"
  | "rules.inspector.title"
  | "rules.inspector.empty.title"
  | "rules.inspector.empty.description"
  | "rules.inspector.empty.description.performance"
  | "rules.inspector.include"
  | "rules.inspector.paths.title"
  | "rules.inspector.command.title"
  | "rules.dry_run.sheet_title"
  | "rules.dry_run.disclaimer"
  | "rules.dry_run.path_missing"
  | "rules.dry_run.no_paths"
  | "rules.dry_run.process_line"
  | "rules.dry_run.loading_processes"
  | "rules.fda.banner"
  | "rules.fda.dismiss"
  | "performance.boost"
  | "performance.scanning"
  | "performance.boosting"
  | "performance.overview.chip.analyzed"
  | "performance.action.impact_label"
  | "performance.list.process_count"
  | "performance.list.analyze_hint"
  | "performance.workspace.actions_section_title"
  | "performance.workspace.processes_section_title"
  | "nav.group.space"
  | "nav.group.resources"
  | "rules.fda.open_settings"
  | "disk.nav_title"
  | "disk.no_volumes"
  | "disk.picker.label"
  | "disk.select_volume_hint"
  | "disk.volume_picker_format"
  | "disk.hero.available"
  | "disk.hero.used"
  | "disk.hero.capacity"
  | "disk.show_in_finder"
  | "disk.scan_top_level"
  | "disk.scanning"
  | "disk.scan_hint_empty"
  | "disk.section.accounting"
  | "disk.accounting.footer"
  | "disk.sum_top_level"
  | "disk.unaccounted"
  | "disk.chart.card_title"
  | "disk.chart.whole_volume"
  | "disk.table.folder"
  | "disk.table.size"
  | "disk.table.percent"
  | "disk.open_finder"
  | "docker.intro"
  | "docker.loading"
  | "docker.section.presets"
  | "docker.section.df"
  | "docker.section.log"
  | "docker.refresh_output"
  | "docker.run"
  | "docker.execute"
  | "docker.chart.card_title"
  | "docker.df_placeholder"
  | "docker.log.streaming_placeholder"
  | "docker.alert.title"
  | "docker.alert.run_destructive"
  | "docker.alert.msg.destructive"
  | "docker.alert.msg.safe"
  | "docker.progress.starting"
  | "docker.progress.working"
  | "monitor.nav_title"
  | "monitor.intro"
  | "metrics.menu.cpu.headline"
  | "metrics.menu.cpu.current"
  | "metrics.menu.memory.headline"
  | "metrics.menu.memory.current"
  | "metrics.menu.network.headline"
  | "metrics.menu.network.short"
  | "chart.table.category"
  | "chart.table.sum"
  | "chart.table.percent";

type Catalog = Record<MessageKey, string>;

const EN: Catalog = {
  "nav.volumes": "Volumes",
  "nav.rules": "Rules",
  "nav.aiTools": "AI tools · Space",
  "nav.docker": "Docker",
  "nav.performance": "Performance",
  "nav.monitor": "Monitor",
  "nav.group.space": "Space",
  "nav.group.resources": "Resources",
  "common.cancel": "Cancel",
  "common.ok": "OK",
  "category.system": "System",
  "category.browser": "Browsers",
  "category.docker": "Docker",
  "category.ai_tools_space": "AI tools · Space",
  "category.performance": "Performance",
  "category.custom": "Custom",
  "rules.chart.card_title": "Size by category (scan)",
  "rules.scan": "Analyze",
  "rules.clean": "Run Clean",
  "rules.scanning": "Analyzing…",
  "rules.cleaning": "Cleaning…",
  "rules.dry_run": "Preview",
  "rules.alert.confirm.title": "Confirm clean",
  "rules.alert.result.title": "Clean result",
  "rules.confirm.clean_risky": "Selection includes medium/high risk. Continue?",
  "rules.confirm.clean_safe": "Clean {count} selected items?",
  "rules.workspace.guide.storage":
    "Choose what to clean, run Analyze to see sizes, then Preview before you confirm.",
  "rules.workspace.guide.ai_tools":
    "Select AI tool caches to remove, Analyze to check size, then Preview before cleaning.",
  "rules.workspace.guide.performance":
    "Select performance actions, Analyze to see impact, then Preview before boosting.",
  "rules.overview.chip.total": "{count} rules",
  "rules.overview.chip.selected": "{count} selected",
  "rules.overview.chip.scanned": "{count} sized",
  "rules.filter.search_placeholder": "Search rules…",
  "rules.filter.category_label": "Category",
  "rules.filter.all_categories": "All categories",
  "rules.filter.sort_label": "Sort",
  "rules.filter.visible": "{visible} shown · {total} total",
  "rules.filter.selected_in_view": "{count} selected in view",
  "rules.filter.no_results.title": "No matching items",
  "rules.filter.no_results.description": "Try a different search or reset the category filter.",
  "rules.sort.name": "Name",
  "rules.sort.category": "Category",
  "rules.sort.impact": "Impact",
  "rules.sort.risk": "Risk",
  "rules.action.select_all": "Select All",
  "rules.action.select_none": "Select None",
  "rules.action.select_filtered": "Select Shown",
  "rules.action.recoverable_label": "You can free",
  "rules.action.metric.placeholder": "No items selected",
  "rules.action.metric.tap_analyze": "Tap Analyze to measure",
  "rules.action.caption.none": "Use checkboxes in the list above, then Preview or Run Clean.",
  "rules.action.caption.counts": "{selected} selected · {path} path · {command} command",
  "rules.table.category": "Category",
  "rules.table.type": "Type",
  "rules.table.type.path": "Path",
  "rules.table.type.command": "Cmd",
  "rules.inspector.title": "Details",
  "rules.inspector.empty.title": "No selection",
  "rules.inspector.empty.description":
    "Select a row to review paths, commands, and impact before you continue.",
  "rules.inspector.empty.description.performance":
    "Select a row to review process impact before you boost.",
  "rules.inspector.include": "Include in clean-up",
  "rules.inspector.paths.title": "Paths",
  "rules.inspector.command.title": "Command",
  "rules.dry_run.sheet_title": "Preview selection",
  "rules.dry_run.disclaimer":
    "This is a dry run. No files are removed until you click Clean and confirm.",
  "rules.dry_run.path_missing": "Path not found (clean will skip if still missing).",
  "rules.dry_run.no_paths": "No paths resolved for this rule.",
  "rules.dry_run.process_line": "PID {pid}: {command}",
  "rules.dry_run.loading_processes": "Listing processes…",
  "rules.fda.banner": "Some paths could not be read. Grant Full Disk Access in System Settings.",
  "rules.fda.open_settings": "Open Settings",
  "rules.fda.dismiss": "Dismiss",
  "performance.boost": "Boost",
  "performance.scanning": "Analyzing…",
  "performance.boosting": "Boosting…",
  "performance.overview.chip.analyzed": "{count} analyzed",
  "performance.action.impact_label": "Estimated impact",
  "performance.list.process_count": "{count} processes",
  "performance.list.analyze_hint": "Analyze",
  "performance.workspace.actions_section_title": "Actions",
  "performance.workspace.processes_section_title": "Leaked processes",
  "chart.table.category": "Category",
  "chart.table.sum": "Size",
  "chart.table.percent": "Share",
  "disk.nav_title": "Volumes",
  "disk.no_volumes": "No volumes found.",
  "disk.picker.label": "Volume",
  "disk.select_volume_hint": "Pick a disk to see space and scan top-level folders.",
  "disk.volume_picker_format": "{name} · {free} free",
  "disk.hero.available": "Available",
  "disk.hero.used": "Used",
  "disk.hero.capacity": "Capacity",
  "disk.show_in_finder": "Show in Finder",
  "disk.scan_top_level": "Measure top-level usage",
  "disk.scanning": "Measuring…",
  "disk.scan_hint_empty": "Not scanned yet. Charts and table appear after scan.",
  "disk.section.accounting": "vs system “used”",
  "disk.accounting.footer": "“Used” comes from the system; folders are a file walk estimate.",
  "disk.sum_top_level": "Scanned top-level total",
  "disk.unaccounted": "Not counted by scan",
  "disk.chart.card_title": "Storage charts",
  "disk.chart.whole_volume": "Whole volume",
  "disk.table.folder": "Folder",
  "disk.table.size": "Size",
  "disk.table.percent": "% of scan",
  "disk.open_finder": "Finder",
  "docker.intro": "Run docker commands in order; use together with Rules if needed.",
  "docker.loading": "Loading…",
  "docker.section.presets": "Presets",
  "docker.section.df": "docker system df -v",
  "docker.section.log": "Execution log",
  "docker.refresh_output": "Refresh output",
  "docker.run": "Run",
  "docker.execute": "Execute",
  "docker.chart.card_title": "Docker Desktop folder sizes",
  "docker.df_placeholder": "Tap “Refresh output”",
  "docker.log.streaming_placeholder": "Output appears here after each step.",
  "docker.alert.title": "Confirm",
  "docker.alert.run_destructive": "Run clean",
  "docker.alert.msg.destructive": "Multiple clean commands will run in order.",
  "docker.alert.msg.safe": "Read-only; no data will be deleted.",
  "docker.progress.starting": "Starting…",
  "docker.progress.working": "Working…",
  "monitor.nav_title": "System Monitor",
  "monitor.intro": "Live CPU, memory, and network. When something looks high, open Performance or Rules.",
  "metrics.menu.cpu.headline": "CPU",
  "metrics.menu.cpu.current": "Current usage: {value}",
  "metrics.menu.memory.headline": "Memory",
  "metrics.menu.memory.current": "In use: {used} of {total} ({pct})",
  "metrics.menu.network.headline": "Network",
  "metrics.menu.network.short": "↑ {up} · ↓ {down}",
};

const ZH: Catalog = {
  "nav.volumes": "磁盘",
  "nav.rules": "规则清理",
  "nav.aiTools": "AI 工具 · 空间",
  "nav.docker": "Docker",
  "nav.performance": "性能",
  "nav.monitor": "监控",
  "nav.group.space": "空间",
  "nav.group.resources": "资源",
  "common.cancel": "取消",
  "common.ok": "好",
  "category.system": "系统",
  "category.browser": "浏览器",
  "category.docker": "Docker",
  "category.ai_tools_space": "AI 工具 · 空间",
  "category.performance": "性能",
  "category.custom": "自定义",
  "rules.chart.card_title": "按分类占用（扫描）",
  "rules.scan": "分析",
  "rules.clean": "运行清理",
  "rules.scanning": "正在分析…",
  "rules.cleaning": "正在清理…",
  "rules.dry_run": "预览",
  "rules.alert.confirm.title": "清理确认",
  "rules.alert.result.title": "清理结果",
  "rules.confirm.clean_risky": "所选包含中/高风险项，确认后将执行。",
  "rules.confirm.clean_safe": "确认清理 {count} 项？",
  "rules.workspace.guide.storage": "选择要清理的项目，运行「分析」查看大小，确认前先「预览」。",
  "rules.workspace.guide.ai_tools": "选择要删除的 AI 工具缓存，「分析」查看大小，清理前先「预览」。",
  "rules.workspace.guide.performance": "选择性能操作，「分析」查看影响，加速前先「预览」。",
  "rules.overview.chip.total": "共 {count} 条规则",
  "rules.overview.chip.selected": "已选 {count} 条",
  "rules.overview.chip.scanned": "已测 {count} 条",
  "rules.filter.search_placeholder": "搜索规则…",
  "rules.filter.category_label": "分类",
  "rules.filter.all_categories": "全部分类",
  "rules.filter.sort_label": "排序",
  "rules.filter.visible": "显示 {visible} 条 · 共 {total} 条",
  "rules.filter.selected_in_view": "当前列表已选 {count} 条",
  "rules.filter.no_results.title": "没有匹配项",
  "rules.filter.no_results.description": "尝试其他搜索词或重置分类筛选。",
  "rules.sort.name": "名称",
  "rules.sort.category": "分类",
  "rules.sort.impact": "影响",
  "rules.sort.risk": "风险",
  "rules.action.select_all": "全选",
  "rules.action.select_none": "全不选",
  "rules.action.select_filtered": "选中当前列表",
  "rules.action.recoverable_label": "预计可释放",
  "rules.action.metric.placeholder": "未选择项目",
  "rules.action.metric.tap_analyze": "点击「分析」测算大小",
  "rules.action.caption.none": "在上方列表勾选项目后，可预览或执行清理。",
  "rules.action.caption.counts": "已选 {selected} 条 · 路径类 {path} · 命令类 {command}",
  "rules.table.category": "分类",
  "rules.table.type": "类型",
  "rules.table.type.path": "路径",
  "rules.table.type.command": "命令",
  "rules.inspector.title": "详情",
  "rules.inspector.empty.title": "未选择",
  "rules.inspector.empty.description": "选择一行以查看路径、命令和影响，然后再继续。",
  "rules.inspector.empty.description.performance": "选择一行以查看进程影响，然后再加速。",
  "rules.inspector.include": "纳入清理",
  "rules.inspector.paths.title": "路径",
  "rules.inspector.command.title": "命令",
  "rules.dry_run.sheet_title": "预览所选",
  "rules.dry_run.disclaimer": "这是演练预览。点击清理并确认前不会删除任何文件。",
  "rules.dry_run.path_missing": "路径不存在（若仍缺失，清理时将跳过）。",
  "rules.dry_run.no_paths": "此规则未解析到路径。",
  "rules.dry_run.process_line": "PID {pid}：{command}",
  "rules.dry_run.loading_processes": "正在列出进程…",
  "rules.fda.banner": "部分路径无法读取。请在系统设置中授予「完全磁盘访问权限」。",
  "rules.fda.open_settings": "打开设置",
  "rules.fda.dismiss": "关闭",
  "performance.boost": "加速",
  "performance.scanning": "正在分析…",
  "performance.boosting": "正在加速…",
  "performance.overview.chip.analyzed": "已分析 {count} 条",
  "performance.action.impact_label": "预计影响",
  "performance.list.process_count": "{count} 个进程",
  "performance.list.analyze_hint": "分析",
  "performance.workspace.actions_section_title": "操作",
  "performance.workspace.processes_section_title": "泄漏进程",
  "chart.table.category": "分类",
  "chart.table.sum": "大小",
  "chart.table.percent": "占比",
  "disk.nav_title": "磁盘",
  "disk.no_volumes": "未找到卷。",
  "disk.picker.label": "卷",
  "disk.select_volume_hint": "选择磁盘以查看空间并扫描顶层文件夹。",
  "disk.volume_picker_format": "{name} · 可用 {free}",
  "disk.hero.available": "可用",
  "disk.hero.used": "已用",
  "disk.hero.capacity": "总容量",
  "disk.show_in_finder": "在 Finder 中显示",
  "disk.scan_top_level": "测量顶层占用",
  "disk.scanning": "正在测量…",
  "disk.scan_hint_empty": "尚未扫描。扫描后将显示图表与表格。",
  "disk.section.accounting": "与系统「已用」对比",
  "disk.accounting.footer": "「已用」来自系统；文件夹为遍历估算。",
  "disk.sum_top_level": "已扫描顶层合计",
  "disk.unaccounted": "扫描未计入",
  "disk.chart.card_title": "存储图表",
  "disk.chart.whole_volume": "整卷",
  "disk.table.folder": "文件夹",
  "disk.table.size": "大小",
  "disk.table.percent": "占扫描比",
  "disk.open_finder": "Finder",
  "docker.intro": "按顺序运行 docker 命令；可与规则清理配合使用。",
  "docker.loading": "加载中…",
  "docker.section.presets": "预设",
  "docker.section.df": "docker system df -v",
  "docker.section.log": "执行日志",
  "docker.refresh_output": "刷新输出",
  "docker.run": "运行",
  "docker.execute": "执行",
  "docker.chart.card_title": "Docker Desktop 文件夹大小",
  "docker.df_placeholder": "点击「刷新输出」",
  "docker.log.streaming_placeholder": "每步执行后日志显示于此。",
  "docker.alert.title": "确认",
  "docker.alert.run_destructive": "运行清理",
  "docker.alert.msg.destructive": "将按顺序运行多条清理命令。",
  "docker.alert.msg.safe": "只读；不会删除数据。",
  "docker.progress.starting": "正在启动…",
  "docker.progress.working": "正在执行…",
  "monitor.nav_title": "系统监控",
  "monitor.intro": "实时 CPU、内存与网络。若偏高，可前往性能或规则页处理。",
  "metrics.menu.cpu.headline": "CPU",
  "metrics.menu.cpu.current": "当前占用：{value}",
  "metrics.menu.memory.headline": "内存",
  "metrics.menu.memory.current": "已用 {used} / {total}（{pct}）",
  "metrics.menu.network.headline": "网络",
  "metrics.menu.network.short": "↑ {up} · ↓ {down}",
};

const CATALOGS: Record<Locale, Catalog> = { en: EN, "zh-Hans": ZH };

export function resolveLocale(): Locale {
  const lang = typeof navigator !== "undefined" ? navigator.language : "en";
  return lang.startsWith("zh") ? "zh-Hans" : "en";
}

export function formatMessage(
  locale: Locale,
  key: MessageKey,
  vars?: Record<string, string | number>,
): string {
  let text = CATALOGS[locale][key] ?? CATALOGS.en[key] ?? key;
  if (vars) {
    for (const [k, v] of Object.entries(vars)) {
      text = text.replaceAll(`{${k}}`, String(v));
    }
  }
  return text;
}

const CATEGORY_KEYS: Record<string, MessageKey> = {
  system: "category.system",
  browser: "category.browser",
  docker: "category.docker",
  "ai-tools": "category.ai_tools_space",
  performance: "category.performance",
  custom: "category.custom",
};

export function categoryLabel(locale: Locale, category: string): string {
  const key = CATEGORY_KEYS[category];
  if (key) return formatMessage(locale, key);
  return category;
}
