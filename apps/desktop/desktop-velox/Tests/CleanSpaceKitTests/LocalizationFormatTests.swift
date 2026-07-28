@testable import CleanSpaceKit
import Foundation
import Testing

/// 校验带占位符的导航副标题 format 与 L10n 绑定正常（不依赖具体翻译句子）。
@Suite("Localization format strings")
struct LocalizationFormatTests {
    @Test("Rules nav subtitle format accepts two integers")
    func rulesNavSubtitleFormat() {
        let s = L10n.Rules.navSubtitleSelected(selected: 2, total: 5)
        #expect(s.contains("2"))
        #expect(s.contains("5"))
    }

    @Test("Docker nav subtitle is non-empty")
    func dockerNavSubtitleNonEmpty() {
        #expect(!L10n.Docker.navSubtitle.isEmpty)
    }

    @Test("Disk pick-volume subtitle is non-empty")
    func diskPickVolumeSubtitleNonEmpty() {
        #expect(!L10n.Disk.navSubtitlePickVolume.isEmpty)
    }

    @Test("File menu show main window label is non-empty")
    func menuShowMainWindowNonEmpty() {
        #expect(!L10n.Menu.showMainWindow.isEmpty)
    }

    @Test("Main window scene id matches Window scene")
    func appWindowSceneIdStable() {
        #expect(AppWindowSceneID.main == "main")
    }

    @Test("Menu bar open/quit format includes app name")
    func menuBarOpenQuitFormat() {
        let name = L10n.App.name
        #expect(L10n.Menu.openApp(name).contains(name))
        #expect(L10n.Menu.quitApp(name).contains(name))
    }

    @Test("Metrics menu bar live help format substitutes three placeholders")
    func metricsMenuBarLiveHelpFormat() {
        let s = L10n.Metrics.menuBarHelpLive(cpu: "12%", memory: "45%", network: "↑ 1 · ↓ 2")
        #expect(s.contains("12%"))
        #expect(s.contains("45%"))
        #expect(s.contains("↑ 1"))
    }

    @Test("Metrics popover chart axis labels are non-empty")
    func metricsChartNetworkAxisLabels() {
        #expect(!L10n.Metrics.chartNetworkAxisUpload.isEmpty)
        #expect(!L10n.Metrics.chartNetworkAxisDownload.isEmpty)
    }

    @Test("Rules flow how-to strings are non-empty")
    func rulesFlowHowToStringsNonEmpty() {
        #expect(!L10n.Rules.flowSectionTitle.isEmpty)
        #expect(!L10n.Rules.flowSteps.isEmpty)
        #expect(L10n.Rules.flowSteps.contains("1"))
    }

    @Test("Rules action workflow strings are non-empty")
    func rulesActionWorkflowStringsNonEmpty() {
        #expect(!L10n.Rules.actionTitle.isEmpty)
        #expect(!L10n.Rules.actionBlurb.isEmpty)
        #expect(!L10n.Rules.actionRecoverableLabel.isEmpty)
        #expect(!L10n.Rules.actionCaptionNone.isEmpty)
        let counts = L10n.Rules.actionCaptionCounts(selected: 2, pathRules: 1, commandRules: 1)
        #expect(counts.contains("2"))
        #expect(!L10n.Rules.actionSelectAll.isEmpty)
        #expect(!L10n.Rules.actionSelectNone.isEmpty)
    }

    @Test("Rules dry-run strings are non-empty")
    func rulesDryRunStringsNonEmpty() {
        #expect(!L10n.Rules.dryRun.isEmpty)
        #expect(!L10n.Rules.dryRunSheetTitle.isEmpty)
        #expect(!L10n.Rules.helpDryRun.isEmpty)
        #expect(!L10n.Rules.dryRunDisclaimer.isEmpty)
        #expect(!L10n.Rules.dryRunPathMissing.isEmpty)
        #expect(!L10n.Rules.dryRunNoPaths.isEmpty)
    }

    @Test("Menu bar popover tab labels and disk copy are non-empty")
    func menuBarPopoverStringsNonEmpty() {
        #expect(!L10n.MenuBarPopover.tabMonitor.isEmpty)
        #expect(!L10n.MenuBarPopover.tabDisk.isEmpty)
        #expect(!L10n.MenuBarPopover.tabManager.isEmpty)
        #expect(!L10n.MenuBarPopover.diskBootTitle.isEmpty)
        #expect(!L10n.MenuBarPopover.diskUnavailable.isEmpty)
        #expect(!L10n.MenuBarPopover.managerIntro.isEmpty)
    }
}
