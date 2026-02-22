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

// MARK: - 分类显示名

extension CleaningRule {
    /// 分类的本地化显示名
    static func categoryDisplayName(_ category: String) -> String {
        switch category {
        case "system": return "系统"
        case "browser": return "浏览器"
        case "docker": return "Docker"
        case "ai-tools": return "AI 工具"
        case "custom": return "自定义"
        default: return category
        }
    }

    var riskLevel: CleaningRuleRisk {
        risk ?? .low
    }
}
