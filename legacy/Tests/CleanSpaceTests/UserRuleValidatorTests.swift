@testable import CleanSpaceKit
import Foundation
import Testing

@Suite("User rule validator")
struct UserRuleValidatorTests {
    @Test("Accepts paths inside allowed home Library subtree")
    func acceptsAllowedHomeLibraryPath() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: home.appendingPathComponent("Library/Caches"), withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: home) }

        let rule = dirRule(base: "~/Library/Caches", dirs: ["CleanSpaceTest"])
        let policy = UserRuleValidationPolicy(homeURL: home)
        let result = UserRuleValidator.validate(rule, policy: policy)

        #expect(result.isValid)
    }

    @Test("Rejects paths outside home")
    func rejectsOutsideHomePath() {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let rule = dirRule(base: "/System", dirs: ["Library"])
        let policy = UserRuleValidationPolicy(homeURL: home)
        let result = UserRuleValidator.validate(rule, policy: policy)

        #expect(!result.isValid)
        #expect(result.errors.contains { $0.reason == .pathOutsideAllowedSubtree })
    }

    @Test("Rejects symlink escaping allowed home subtree")
    func rejectsEscapingSymlink() throws {
        let fm = FileManager.default
        let home = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let target = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let linkParent = home.appendingPathComponent("Library/Caches")
        let link = linkParent.appendingPathComponent("Escapes")
        try fm.createDirectory(at: linkParent, withIntermediateDirectories: true)
        try fm.createDirectory(at: target, withIntermediateDirectories: true)
        try fm.createSymbolicLink(at: link, withDestinationURL: target)
        defer {
            try? fm.removeItem(at: home)
            try? fm.removeItem(at: target)
        }

        let rule = dirRule(base: "~/Library/Caches/Escapes", dirs: ["."])
        let policy = UserRuleValidationPolicy(homeURL: home)
        let result = UserRuleValidator.validate(rule, policy: policy)

        #expect(!result.isValid)
        #expect(result.errors.contains { $0.reason == .pathOutsideAllowedSubtree })
    }

    @Test("Rejects dangerous command")
    func rejectsDangerousCommand() {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let rule = commandRule(command: "docker system prune -f; rm -rf ~")
        let policy = UserRuleValidationPolicy(homeURL: home)
        let result = UserRuleValidator.validate(rule, policy: policy)

        #expect(!result.isValid)
        #expect(result.errors.contains { $0.reason == .commandContainsShellSyntax })
    }

    @Test("Accepts documented docker command")
    func acceptsDocumentedDockerCommand() {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let rule = commandRule(command: "docker system prune -a -f")
        let policy = UserRuleValidationPolicy(homeURL: home)
        let result = UserRuleValidator.validate(rule, policy: policy)

        #expect(result.isValid)
    }

    @Test("Rejects unapproved docker executable path")
    func rejectsUnapprovedDockerExecutablePath() {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let rule = commandRule(command: "/tmp/docker system prune -f")
        let policy = UserRuleValidationPolicy(homeURL: home)
        let result = UserRuleValidator.validate(rule, policy: policy)

        #expect(!result.isValid)
        #expect(result.errors.contains { $0.reason == .commandExecutableNotAllowed })
    }

    @Test("Loader accepts valid user rules and reports rejected rows")
    func loaderFiltersInvalidUserRules() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let home = tempDir.appendingPathComponent("home")
        let file = tempDir.appendingPathComponent("user-cleaning-rules.json")
        try fm.createDirectory(at: home.appendingPathComponent("Library/Caches"), withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: tempDir) }

        let json = """
        [
          {
            "id": "good",
            "category": "custom",
            "name": "Good",
            "type": "dir",
            "paths": [{ "base": "~/Library/Caches", "dirs": ["CleanSpaceTest"] }]
          },
          {
            "id": "bad",
            "category": "custom",
            "name": "Bad",
            "type": "dir",
            "paths": [{ "base": "/System", "dirs": ["Library"] }]
          }
        ]
        """
        try Data(json.utf8).write(to: file)

        let policy = UserRuleValidationPolicy(homeURL: home)
        let report = CleaningRulesLoader.loadUserRules(from: file, policy: policy)

        #expect(report.acceptedRules.map(\.id) == ["good"])
        #expect(report.errors.map(\.ruleId) == ["bad"])
    }

    private func dirRule(base: String, dirs: [String]) -> CleaningRule {
        CleaningRule(
            id: "custom-dir",
            category: CleaningRule.CategoryId.custom,
            name: "Custom Dir",
            type: .dir,
            risk: .low,
            warning: nil,
            paths: [CleaningRulePath(base: base, dirs: dirs)],
            command: nil,
            estimate: nil,
            hiddenFromRulesList: nil
        )
    }

    private func commandRule(command: String) -> CleaningRule {
        CleaningRule(
            id: "custom-command",
            category: CleaningRule.CategoryId.custom,
            name: "Custom Command",
            type: .command,
            risk: .medium,
            warning: nil,
            paths: nil,
            command: command,
            estimate: nil,
            hiddenFromRulesList: nil
        )
    }
}
