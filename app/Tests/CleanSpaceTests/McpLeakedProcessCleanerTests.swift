//
//  McpLeakedProcessCleanerTests.swift
//  CleanSpaceTests
//

@testable import CleanSpaceKit
import Testing

@Suite("MCP leaked process cleaner")
struct McpLeakedProcessCleanerTests {
  @Test("parsePgrepLine extracts pid and command")
  func parsePgrepLine() {
    let parsed = McpLeakedProcessCleaner.parsePgrepLine(
      "5621 npm exec obsidian-mcp-server APPLICATION_INSIGHTS=1"
    )
    #expect(parsed?.pid == 5621)
    #expect(parsed?.commandLine.contains("obsidian-mcp-server") == true)
  }

  @Test("isLeakedMcpCommandLine matches npm exec MCP patterns")
  func matchesLeakPatterns() {
    #expect(
      McpLeakedProcessCleaner.isLeakedMcpCommandLine(
        "npm exec chrome-devtools-mcp@latest"
      )
    )
    #expect(
      McpLeakedProcessCleaner.isLeakedMcpCommandLine(
        "npm exec @playwright/mcp@latest"
      )
    )
    #expect(
      !McpLeakedProcessCleaner.isLeakedMcpCommandLine(
        "npm exec typescript-language-server --stdio"
      )
    )
    #expect(
      !McpLeakedProcessCleaner.isLeakedMcpCommandLine(
        "node /path/to/server.js"
      )
    )
  }

  @Test("leakedProcesses filters pgrep output")
  func filterPgrepOutput() {
    let sample = """
    28018 npm exec typescript-language-server --stdio
    5621 npm exec obsidian-mcp-server
    5876 npm exec chrome-devtools-mcp@latest
    """
    let leaked = McpLeakedProcessCleaner.leakedProcesses(fromPgrepOutput: sample)
    #expect(leaked.count == 2)
    #expect(leaked.contains { $0.pid == 5621 })
    #expect(leaked.contains { $0.pid == 5876 })
    #expect(!leaked.contains { $0.pid == 28018 })
  }

  @Test("rssBytes sums ps rss column in kilobytes")
  func rssBytesFromPs() {
    let total = McpLeakedProcessCleaner.rssBytes(fromPsRssOutput: "1024\n2048\n")
    #expect(total == (1024 + 2048) * 1024)
  }

  @Test("MCP rule id is wired in builtin rules")
  func builtinRulePresent() throws {
    let rules = try CleaningRulesLoader.loadBuiltinRules()
    let mcpRule = rules.first { $0.id == McpLeakedProcessCleaner.ruleId }
    #expect(mcpRule != nil)
    #expect(mcpRule?.category == CleaningRule.CategoryId.performance)
    #expect(mcpRule?.displaysScannedProcessCount == true)
  }
}
