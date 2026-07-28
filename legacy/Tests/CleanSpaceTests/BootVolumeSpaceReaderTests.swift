@testable import CleanSpaceKit
import Foundation
import Testing

@Suite("Boot volume space reader")
struct BootVolumeSpaceReaderTests {
    /// 在可读取根卷资源值的环境下校验数值关系；沙箱或受限环境可能返回 nil，此时跳过断言。
    @Test("Snapshot invariants when root volume is readable")
    func snapshotInvariantsWhenReadable() {
        guard let snap = BootVolumeSpaceReader.snapshot() else { return }
        #expect(snap.total > 0)
        #expect(snap.used >= 0)
        #expect(snap.used <= snap.total)
        #expect(snap.percent >= 0)
        #expect(snap.percent <= 100)
    }
}
