@testable import CleanSpaceKit
import Testing

/// Docker 预设元数据（供卡片 UI 使用）保持稳定。
@Suite("Docker preset metadata")
struct DockerPresetMetadataTests {
    @Test("Each preset exposes a non-empty SF Symbol name", arguments: DockerCleanPreset.allCases)
    func symbolNamesNonEmpty(preset: DockerCleanPreset) {
        #expect(!preset.symbolName.isEmpty)
    }
}
