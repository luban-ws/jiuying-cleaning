//
//  L10n.swift
//  CleanSpaceKit
//
//  用户可见文案统一走 Localizable.strings；代码中禁止硬编码自然语言句子。
//

import Foundation

/// 本地化键与 `en.lproj` / `zh-Hans.lproj` 中条目对应。
enum L10n {
    private static let bundle = Bundle.module

    private static func tr(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: bundle)
    }

    enum Common {
        static var cancel: String { tr("common.cancel") }
        static var ok: String { tr("common.ok") }
    }

    enum Sidebar {
        static var rules: String { tr("sidebar.rules") }
        static var docker: String { tr("sidebar.docker") }
        static var volumes: String { tr("sidebar.volumes") }
        /// 侧栏第二行：各分区一句话说明（类似 App Store / 系统设置侧栏副文案）。
        static var volumesBlurb: String { tr("sidebar.volumes.blurb") }
        static var rulesBlurb: String { tr("sidebar.rules.blurb") }
        static var dockerBlurb: String { tr("sidebar.docker.blurb") }
    }

    enum Rules {
        static var emptyTitle: String { tr("rules.empty.title") }
        static var emptyDescription: String { tr("rules.empty.description") }
        static var intro: String { tr("rules.intro") }
        static var chartCardTitle: String { tr("rules.chart.card_title") }
        static var navTitle: String { tr("rules.nav_title") }
        /// 导航副标题：已选规则数 / 总规则数。
        static func navSubtitleSelected(selected: Int, total: Int) -> String {
            String(format: tr("rules.nav_subtitle_format"), selected, total)
        }
        static var overviewTitle: String { tr("rules.overview.title") }
        static var overviewBlurb: String { tr("rules.overview.blurb") }
        static func overviewChipTotal(_ n: Int) -> String {
            String(format: tr("rules.overview.chip.total_format"), n)
        }
        static func overviewChipSelected(_ n: Int) -> String {
            String(format: tr("rules.overview.chip.selected_format"), n)
        }
        static func overviewChipScanned(_ n: Int) -> String {
            String(format: tr("rules.overview.chip.scanned_format"), n)
        }
        static var scan: String { tr("rules.scan") }
        static var clean: String { tr("rules.clean") }
        static var scanning: String { tr("rules.scanning") }
        static var cleaning: String { tr("rules.cleaning") }
        static var alertConfirmTitle: String { tr("rules.alert.confirm.title") }
        static var cancel: String { Common.cancel }
        static var alertResultTitle: String { tr("rules.alert.result.title") }
        static var ok: String { Common.ok }
        static var estimateCommand: String { tr("rules.estimate.command") }
        static var riskMedium: String { tr("rules.risk.medium") }
        static var riskHigh: String { tr("rules.risk.high") }
        static func confirmCleanRisky() -> String { tr("rules.confirm.clean_risky") }
        static func confirmCleanSafe(_ count: Int) -> String {
            String(format: tr("rules.confirm.clean_safe_format"), count)
        }
        static func cleanResultLine(name: String, success: Bool, message: String) -> String {
            let status = success ? tr("rules.clean.status.success") : tr("rules.clean.status.fail")
            return String(format: tr("rules.clean.result_line_format"), name, status, message)
        }

        /// 工具栏与指针悬停提示（macOS HIG：桌面应用应提供 `.help`）
        static var helpScan: String { tr("rules.help.scan") }
        static var helpClean: String { tr("rules.help.clean") }

        /// 浏览器类规则表格列标题
        static var browserTableClean: String { tr("rules.browser.table.clean") }
        static var browserTableItem: String { tr("rules.browser.table.item") }
        static var browserTableSize: String { tr("rules.browser.table.size") }
        static var browserTableRisk: String { tr("rules.browser.table.risk") }
    }

    enum Docker {
        static var intro: String { tr("docker.intro") }
        static var sectionDesktop: String { tr("docker.section.desktop") }
        static var loading: String { tr("docker.loading") }
        static var chartCardTitle: String { tr("docker.chart.card_title") }
        static var refreshSizes: String { tr("docker.refresh_sizes") }
        static var sectionPresets: String { tr("docker.section.presets") }
        static var run: String { tr("docker.run") }
        static var execute: String { tr("docker.execute") }
        static var sectionDf: String { tr("docker.section.df") }
        static var refreshOutput: String { tr("docker.refresh_output") }
        static var dfPlaceholder: String { tr("docker.df_placeholder") }
        static var sectionLog: String { tr("docker.section.log") }
        static var running: String { tr("docker.running") }
        static var progressWorking: String { tr("docker.progress.working") }
        static var logStreamingPlaceholder: String { tr("docker.log.streaming_placeholder") }
        static func progressCompleted(_ completed: Int, _ total: Int) -> String {
            if total <= 0 { return tr("docker.progress.starting") }
            return String(format: tr("docker.progress.completed_format"), completed, total)
        }
        static var alertTitle: String { tr("docker.alert.title") }
        static var alertRunDestructive: String { tr("docker.alert.run_destructive") }
        static var alertRunSafe: String { tr("docker.alert.run_safe") }
        static var alertMsgDestructive: String { tr("docker.alert.msg.destructive") }
        static var alertMsgSafe: String { tr("docker.alert.msg.safe") }
        static func presetTitle(_ key: String) -> String { tr("docker.preset.\(key).title") }
        static func presetSubtitle(_ key: String) -> String { tr("docker.preset.\(key).subtitle") }
        static var desktopLabelGroupContainers: String { tr("docker.desktop.group_containers") }
        static var desktopLabelAppSupport: String { tr("docker.desktop.app_support") }
        static var desktopLabelCaches: String { tr("docker.desktop.caches") }
        static var desktopLabelContainers: String { tr("docker.desktop.containers") }
        static var helpRefreshSizes: String { tr("docker.help.refresh_sizes") }
        static var helpRefreshDf: String { tr("docker.help.refresh_df") }
        /// 导航副标题：概括本页能力（预设、Desktop 目录、df 输出）。
        static var navSubtitle: String { tr("docker.nav_subtitle") }
        /// `docker system df` 结构化展示：摘要表标题、各详细区块、原始输出折叠项等。
        static var dfSummarySectionTitle: String { tr("docker.df.summary.section") }
        static var dfSummaryUnavailable: String { tr("docker.df.summary.unavailable") }
        static var dfRawOutputToggle: String { tr("docker.df.raw.toggle") }
        static var dfOrphanLinesNote: String { tr("docker.df.orphan.note") }
        static var dfColResource: String { tr("docker.df.col.resource") }
        static var dfColTotal: String { tr("docker.df.col.total") }
        static var dfColActive: String { tr("docker.df.col.active") }
        static var dfColSize: String { tr("docker.df.col.size") }
        static var dfColReclaimable: String { tr("docker.df.col.reclaimable") }
        static func dfDetailSectionTitle(key: String) -> String { tr("docker.df.section.\(key)") }
    }

    enum Disk {
        static var noVolumes: String { tr("disk.no_volumes") }
        static var pickerLabel: String { tr("disk.picker.label") }
        static var pickerPlaceholder: String { tr("disk.picker.placeholder") }
        static var path: String { tr("disk.path") }
        static var usedSpace: String { tr("disk.used_space") }
        static var available: String { tr("disk.available") }
        static func usedOverTotal(usedFormatted: String, totalFormatted: String) -> String {
            String(format: tr("disk.used_over_total_format"), usedFormatted, totalFormatted)
        }
        static var chartCardTitle: String { tr("disk.chart.card_title") }
        static var sectionTopLevel: String { tr("disk.section.top_level") }
        static var scanTopLevel: String { tr("disk.scan_top_level") }
        static var showInFinder: String { tr("disk.show_in_finder") }
        static var scanning: String { tr("disk.scanning") }
        static var scanHintEmpty: String { tr("disk.scan_hint_empty") }
        static var sumTopLevel: String { tr("disk.sum_top_level") }
        static var unaccounted: String { tr("disk.unaccounted") }
        static var sectionAccounting: String { tr("disk.section.accounting") }
        static var accountingFooter: String { tr("disk.accounting.footer") }
        static var selectVolumeHint: String { tr("disk.select_volume_hint") }
        static var navTitle: String { tr("disk.nav_title") }
        static var heroAvailable: String { tr("disk.hero.available") }
        static var heroUsed: String { tr("disk.hero.used") }
        static var heroCapacity: String { tr("disk.hero.capacity") }
        static var sectionSource: String { tr("disk.section.source") }
        static var sectionQuickActions: String { tr("disk.section.quick_actions") }
        /// 有卷但未在 Picker 中选定目标卷时的导航副标题。
        static var navSubtitlePickVolume: String { tr("disk.nav_subtitle_pick_volume") }
        /// 卷选择器一行（`freeFormatted` 为 `ByteCountFormatter` 等生成的可用空间数字串；「可用/free」由各语言 format 模板附带）。
        static func volumePickerLine(name: String, freeFormatted: String) -> String {
            String(format: tr("disk.volume_picker_format"), name, freeFormatted)
        }
        static var chartWholeVolume: String { tr("disk.chart.whole_volume") }
        static var chartBreakdown: String { tr("disk.chart.breakdown") }
        static var chartNoPositive: String { tr("disk.chart.no_positive") }
        static var tableTitle: String { tr("disk.table.title") }
        static var tableFolder: String { tr("disk.table.folder") }
        static var tableSize: String { tr("disk.table.size") }
        static var tablePercent: String { tr("disk.table.percent") }
        static var openFinder: String { tr("disk.open_finder") }
        static var helpScanTopLevel: String { tr("disk.help.scan_top_level") }
        static var helpShowInFinder: String { tr("disk.help.show_in_finder") }
        static var helpRevealFolder: String { tr("disk.help.reveal_folder") }
    }

    enum Chart {
        static var axisBytes: String { tr("chart.axis.bytes") }
        static var axisCategory: String { tr("chart.axis.category") }
        static var axisShare: String { tr("chart.axis.share") }
        static var axisCapacity: String { tr("chart.axis.capacity") }
        static var axisEstimate: String { tr("chart.axis.estimate") }
        static var axisDirectory: String { tr("chart.axis.directory") }
        static var sliceUsed: String { tr("chart.slice.used") }
        static var sliceFree: String { tr("chart.slice.free") }
        static func topLevelOtherTail(_ count: Int) -> String {
            String(format: tr("chart.top_level.other_format"), count)
        }
        static var sliceUnaccounted: String { tr("chart.slice.unaccounted") }
        static var tableCategory: String { tr("chart.table.category") }
        static var tableSum: String { tr("chart.table.sum") }
        static var tablePercent: String { tr("chart.table.percent") }
    }

    enum Category {
        static var system: String { tr("category.system") }
        static var browser: String { tr("category.browser") }
        static var docker: String { tr("category.docker") }
        static var aiTools: String { tr("category.ai_tools") }
        static var custom: String { tr("category.custom") }
    }

    enum Clean {
        static func deleted(_ n: Int) -> String { String(format: tr("clean.deleted_format"), n) }
        static func partialFail(_ msg: String) -> String { String(format: tr("clean.partial_fail_format"), msg) }
        static var missingCommand: String { tr("clean.missing_command") }
        static var executed: String { tr("clean.executed") }
        static func exitCode(_ code: Int32, _ output: String) -> String {
            String(format: tr("clean.exit_code_format"), code, output)
        }
    }

    enum DockerService {
        static var dfEmpty: String { tr("docker.service.df_empty") }
        static func dfFail(code: Int32, output: String) -> String {
            String(format: tr("docker.service.df_fail_format"), code, output)
        }
        static var stepDone: String { tr("docker.service.step_done") }
        static var stepNoOutput: String { tr("docker.service.step_no_output") }
    }

    enum App {
        static var name: String { tr("app.name") }
    }

    /// 应用级菜单（File 等），与 `Commands` / `WindowGroup(id:)` 配合。
    enum Menu {
        /// 无文档型应用仍须提供此项，关窗后或 Dock 再次打开时可显式创建主窗口。
        static var newMainWindow: String { tr("menu.new_main_window") }
        /// 菜单栏下拉：打开或前置主窗口（`%@` 为应用名）。
        static func openApp(_ name: String) -> String {
            String(format: tr("menu.bar.open_format"), name)
        }
        /// 菜单栏 / 标准退出（`%@` 为应用名）。
        static func quitApp(_ name: String) -> String {
            String(format: tr("menu.quit_format"), name)
        }
    }

    /// 工具栏系统监控（CPU / 内存 / 网络）与阈值通知文案。
    enum Metrics {
        static var menuBarAccessibilityLabel: String { tr("metrics.menu_bar.accessibility") }
        /// 悬停菜单栏图标时的实时摘要（`%@` 依次为 CPU、内存占比、网络简写）。
        static func menuBarHelpLive(cpu: String, memory: String, network: String) -> String {
            String(format: tr("metrics.menu_bar.help_live_format"), cpu, memory, network)
        }
        /// VoiceOver 朗读的实时数值（`%@` 同上）。
        static func menuBarAccessibilityValue(cpu: String, memory: String, network: String) -> String {
            String(format: tr("metrics.menu_bar.accessibility_value_format"), cpu, memory, network)
        }
        /// 网络柱图横轴：上传。
        static var chartNetworkAxisUpload: String { tr("metrics.chart.network.axis_upload") }
        /// 网络柱图横轴：下载。
        static var chartNetworkAxisDownload: String { tr("metrics.chart.network.axis_download") }
        static var menuCpuHeadline: String { tr("metrics.menu.cpu.headline") }
        static func menuCpuCurrent(_ value: String) -> String {
            String(format: tr("metrics.menu.cpu.current_format"), value)
        }
        static func menuThresholdCpu(_ pct: Int) -> String {
            String(format: tr("metrics.menu.threshold.cpu_format"), pct)
        }
        static var menuMemoryHeadline: String { tr("metrics.menu.memory.headline") }
        static func menuMemoryCurrent(used: String, total: String, pct: String) -> String {
            String(format: tr("metrics.menu.memory.current_format"), used, total, pct)
        }
        static func menuThresholdMemory(_ pct: Int) -> String {
            String(format: tr("metrics.menu.threshold.memory_format"), pct)
        }
        static var menuNetworkHeadline: String { tr("metrics.menu.network.headline") }
        static func menuNetworkUp(_ rate: String) -> String {
            String(format: tr("metrics.menu.network.up_format"), rate)
        }
        static func menuNetworkDown(_ rate: String) -> String {
            String(format: tr("metrics.menu.network.down_format"), rate)
        }
        static func menuNetworkShort(up: String, down: String) -> String {
            String(format: tr("metrics.menu.network.short_format"), up, down)
        }
        static func menuThresholdNetwork(_ rate: String) -> String {
            String(format: tr("metrics.menu.threshold.network_format"), rate)
        }
        static var menuNetworkNotifyOff: String { tr("metrics.menu.network.notify_off") }
        static var notifCpuTitle: String { tr("metrics.notif.cpu.title") }
        static func notifCpuBody(pct: Int) -> String {
            String(format: tr("metrics.notif.cpu.body_format"), pct)
        }
        static var notifMemoryTitle: String { tr("metrics.notif.memory.title") }
        static func notifMemoryBody(pct: Int) -> String {
            String(format: tr("metrics.notif.memory.body_format"), pct)
        }
        static var notifNetworkTitle: String { tr("metrics.notif.network.title") }
        static func notifNetworkBody(down: String, up: String) -> String {
            String(format: tr("metrics.notif.network.body_format"), down, up)
        }
    }
}
