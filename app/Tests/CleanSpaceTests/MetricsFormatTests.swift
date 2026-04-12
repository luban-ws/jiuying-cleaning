import Testing

@testable import CleanSpaceKit

@Suite("Metrics formatting")
struct MetricsFormatTests {
    @Test("percent0 clamps and rounds")
    func percent0() {
        #expect(MetricsFormat.percent0(42.7) == "43%")
        #expect(MetricsFormat.percent0(-1) == "0%")
        #expect(MetricsFormat.percent0(150) == "100%")
    }

    @Test("bytesPerSecond appends per second")
    func bps() {
        let s = MetricsFormat.bytesPerSecond(1024)
        #expect(s.contains("/s"))
    }
}
