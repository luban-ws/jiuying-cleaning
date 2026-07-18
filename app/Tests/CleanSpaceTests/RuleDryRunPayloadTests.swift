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

    @Test("MCP rule dry-run payload does not shell out synchronously")
    func mcpRuleDryRunUsesPlaceholder() throws {
        let data = Data(
            #"{"id":"mcp-leaked-processes","category":"performance","name":"MCP","type":"command"}"#
                .utf8
        )
        let rule = try JSONDecoder().decode(CleaningRule.self, from: data)
        let payload = ruleDryRunPayload(for: rule)
        guard case .noCommand = payload else {
            Issue.record("Expected .noCommand placeholder for async MCP preview")
            return
        }
    }

    @Test("resolvePaths handles nested wildcard paths and scanRule handles file sizes")
    func wildcardAndFileSizeScanning() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        // Setup layout:
        // tempDir/profile1/cache2 (directory)
        // tempDir/profile1/cookies.sqlite (file, 10 bytes)
        // tempDir/profile2/cache2 (directory)
        // tempDir/profile2/cookies.sqlite (file, 20 bytes)
        // tempDir/some_other_folder (directory)
        
        let p1 = tempDir.appendingPathComponent("profile1")
        let p2 = tempDir.appendingPathComponent("profile2")
        let other = tempDir.appendingPathComponent("some_other_folder")
        
        try fm.createDirectory(at: p1.appendingPathComponent("cache2"), withIntermediateDirectories: true)
        try fm.createDirectory(at: p2.appendingPathComponent("cache2"), withIntermediateDirectories: true)
        try fm.createDirectory(at: other, withIntermediateDirectories: true)
        
        let cookie1 = p1.appendingPathComponent("cookies.sqlite")
        let cookie2 = p2.appendingPathComponent("cookies.sqlite")
        
        try Data(repeating: 0, count: 10).write(to: cookie1)
        try Data(repeating: 0, count: 20).write(to: cookie2)
        
        // Define a rule with wildcards
        let ruleJson = """
        {
          "id": "test-wildcard-rule",
          "category": "browser",
          "name": "Test Wildcard",
          "type": "dir",
          "paths": [
            { "base": "\(tempDir.path)", "dirs": ["*/cache2", "*/cookies.sqlite"] }
          ]
        }
        """
        let rule = try JSONDecoder().decode(CleaningRule.self, from: Data(ruleJson.utf8))
        
        let resolved = resolvePaths(for: rule)
        #expect(resolved.count == 6)
        
        let expectedPaths = [
            p1.appendingPathComponent("cache2").path,
            p1.appendingPathComponent("cookies.sqlite").path,
            p2.appendingPathComponent("cache2").path,
            p2.appendingPathComponent("cookies.sqlite").path
        ]
        
        for path in expectedPaths {
            #expect(resolved.contains(path))
        }
        
        // Test scanRule includes both directories and files size
        let scannedSize = scanRule(rule)
        #expect(scannedSize == 30) // 10 bytes + 20 bytes (cache2 folders are empty)
    }
}
