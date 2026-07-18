//
//  CleaningRulesLoader.swift
//  CleanSpace
//
//  从应用 Bundle 与（可选）用户目录加载清理规则 JSON。
//

import Foundation

enum CleaningRulesLoaderError: Error {
    case resourceNotFound
    case decodeFailed(Error)
}

final class CleaningRulesLoader {
    private static let builtinFileName = "cleaning-rules"
    private static let builtinExtension = "json"
    private static let userRulesFileName = "user-cleaning-rules.json"
    private static let appSupportSubdirectory = "CleanSpace"

    /// 从主 Bundle 加载内置规则
    static func loadBuiltinRules() throws -> [CleaningRule] {
        // SwiftPM 资源随 CleanSpaceKit 打入资源包，使用模块 Bundle（非可执行体 Bundle.main）
        guard let url = Bundle.module.url(forResource: Self.builtinFileName, withExtension: Self.builtinExtension) else {
            throw CleaningRulesLoaderError.resourceNotFound
        }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode([CleaningRule].self, from: data)
    }

    /// 用户规则路径：~/Library/Application Support/CleanSpace/user-cleaning-rules.json
    static var userRulesURL: URL? {
        guard let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = support.appendingPathComponent(Self.appSupportSubdirectory, isDirectory: true)
        return dir.appendingPathComponent(Self.userRulesFileName, isDirectory: false)
    }

    /// 若存在则加载用户规则，否则返回空数组
    static func loadUserRules() -> [CleaningRule] {
        guard let url = userRulesURL, FileManager.default.fileExists(atPath: url.path) else { return [] }
        return loadUserRules(from: url).acceptedRules
    }

    /// 从指定文件加载并校验用户规则；非法条按条拒绝，解析失败拒绝整文件。
    static func loadUserRules(
        from url: URL,
        policy: UserRuleValidationPolicy = .init()
    ) -> UserRulesValidationReport {
        do {
            let data = try Data(contentsOf: url)
            let rules = try JSONDecoder().decode([CleaningRule].self, from: data)
            return UserRuleValidator.validate(rules, policy: policy)
        } catch let error as DecodingError {
            return UserRulesValidationReport(
                acceptedRules: [],
                errors: [
                    UserRuleValidationIssue(ruleId: "", reason: .fileDecodeFailed, detail: String(describing: error)),
                ]
            )
        } catch {
            return UserRulesValidationReport(
                acceptedRules: [],
                errors: [
                    UserRuleValidationIssue(ruleId: "", reason: .fileReadFailed, detail: error.localizedDescription),
                ]
            )
        }
    }

    /// 合并内置 + 用户规则（用户规则 id 若与内置重复则覆盖）
    static func loadMergedRules() -> [CleaningRule] {
        let builtin = (try? loadBuiltinRules()) ?? []
        let user = loadUserRules()
        var byId: [String: CleaningRule] = builtin.reduce(into: [:]) { $0[$1.id] = $1 }
        for rule in user {
            byId[rule.id] = rule
        }
        return Array(byId.values)
    }
}
