@testable import CleanSpaceKit
import Foundation
import Testing

@Suite("Rule dry-run payload")
struct RuleDryRunPayloadTests {
    @Test("Command rule without command yields noCommand")
    func commandMissingYieldsNoCommand() throws {
        let data = Data(#"{"id":"t1","category":"system","name":"Test","type":"command"}"#.utf8)
        let rule = try JSONDecoder().decode(CleaningRule.self, from: data)
        let payload = ruleDryRunPayload(for: rule)
        guard case .noCommand = payload else {
            Issue.record("Expected .noCommand")
            return
        }
    }

    @Test("Dir rule with tilde base resolves to directory payload")
    func dirRuleResolvesPaths() throws {
        let data = Data(
            #"{"id":"t2","category":"system","name":"Lib","type":"dir","paths":[{"base":"~","dirs":["Library"]}]}"#
                .utf8
        )
        let rule = try JSONDecoder().decode(CleaningRule.self, from: data)
        let payload = ruleDryRunPayload(for: rule)
        guard case .directory(let targets) = payload else {
            Issue.record("Expected .directory")
            return
        }
        #expect(!targets.isEmpty)
        #expect(targets.allSatisfy { $0.path.contains("Library") })
    }
}
