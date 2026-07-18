//
//  CleaningRule.swift
//  CleanSpace
//
//  清理规则数据模型，与 RFC 001 中「如何定义清理规则」一致。
//

import Foundation

/// 风险等级
enum CleaningRuleRisk: String, Codable, CaseIterable {
    case low
    case medium
    case high
}

/// 清理方式：按路径删目录 / 执行命令
enum CleaningRuleType: String, Codable {
    case dir
    case command
}

/// 单条路径配置：base + 子目录列表
struct CleaningRulePath: Codable {
    let base: String
    let dirs: [String]
}

/// 单条清理规则（与配置文件 JSON 结构一致）
struct CleaningRule: Codable, Identifiable {
    let id: String
    let category: String
    let name: String
    let type: CleaningRuleType
    var risk: CleaningRuleRisk?
    var warning: String?
    /// type == .dir 时使用
    var paths: [CleaningRulePath]?
    /// type == .command 时使用
    var command: String?
    var estimate: String?
    var hiddenFromRulesList: Bool?
}

// MARK: - 分类键（与 cleaning-rules.json 中 `category` 一致，避免魔法字符串）

extension CleaningRule {
    enum CategoryId {
        static let system = "system"
        static let browser = "browser"
        static let docker = "docker"
        /// AI 编辑器/工具 **磁盘** 缓存（归 Space 工作区，与 performance 分离）。
        static let aiTools = "ai-tools"
        /// 进程与负载类优化（归 Performance 工作区）。
        static let performance = "performance"
        static let custom = "custom"

        /// 规则表单内分组顺序（不含侧栏专用工作区）。
        static var ordered: [String] {
            [system, browser, docker, aiTools, performance, custom]
        }

        /// Space 侧栏「规则清理」页展示的分类（不含 AI 工具磁盘项与性能项）。
        static let storageRuleCategories: Set<String> = [system, browser, docker]

        static let performanceCategories: Set<String> = [performance]
        static let aiToolsSpaceCategories: Set<String> = [aiTools]
    }

    /// 分类的本地化显示名（键在 Localizable.strings）
    static func categoryDisplayName(_ category: String) -> String {
        switch category {
        case CategoryId.system: return L10n.Category.system
        case CategoryId.browser: return L10n.Category.browser
        case CategoryId.docker: return L10n.Category.docker
        case CategoryId.aiTools: return L10n.Category.aiToolsSpace
        case CategoryId.performance: return L10n.Category.performance
        case CategoryId.custom: return L10n.Category.custom
        default: return category
        }
    }

    var riskLevel: CleaningRuleRisk {
        risk ?? .low
    }

    /// 扫描后在 Space 工作区「大小」列展示字节数（仅路径类规则）。
    var displaysScannedByteSize: Bool {
        type == .dir
    }

    /// 扫描后在 Performance 工作区展示进程数（如 MCP 泄漏）。
    var displaysScannedProcessCount: Bool {
        id == McpLeakedProcessCleaner.ruleId
    }
}
