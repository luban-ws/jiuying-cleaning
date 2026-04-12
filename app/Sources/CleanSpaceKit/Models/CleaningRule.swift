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
}

// MARK: - 分类键（与 cleaning-rules.json 中 `category` 一致，避免魔法字符串）

extension CleaningRule {
    enum CategoryId {
        static let system = "system"
        static let browser = "browser"
        static let docker = "docker"
        static let aiTools = "ai-tools"
        static let custom = "custom"

        /// 侧栏/表单中分类分组的稳定顺序
        static var ordered: [String] {
            [system, browser, docker, aiTools, custom]
        }
    }

    /// 分类的本地化显示名（键在 Localizable.strings）
    static func categoryDisplayName(_ category: String) -> String {
        switch category {
        case CategoryId.system: return L10n.Category.system
        case CategoryId.browser: return L10n.Category.browser
        case CategoryId.docker: return L10n.Category.docker
        case CategoryId.aiTools: return L10n.Category.aiTools
        case CategoryId.custom: return L10n.Category.custom
        default: return category
        }
    }

    var riskLevel: CleaningRuleRisk {
        risk ?? .low
    }
}
