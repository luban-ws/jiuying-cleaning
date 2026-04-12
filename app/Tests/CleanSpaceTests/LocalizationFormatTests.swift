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

    @Test("File menu new window label is non-empty")
    func menuNewMainWindowNonEmpty() {
        #expect(!L10n.Menu.newMainWindow.isEmpty)
    }

    @Test("Main window scene id matches WindowGroup")
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
}
