import Foundation

/// RFC 009：用户规则校验失败原因（稳定 id，供测试与 UI 映射）。
enum UserRuleValidationReason: String, Sendable, Equatable {
    case fileReadFailed
    case fileDecodeFailed
    case pathOutsideAllowedSubtree
    case commandContainsShellSyntax
    case commandExecutableNotAllowed
    case commandSubcommandNotAllowed
    case missingPaths
    case missingCommand
}

/// 单条校验错误。
struct UserRuleValidationIssue: Sendable, Equatable {
    var ruleId: String
    var reason: UserRuleValidationReason
    var detail: String?
}

/// 单条规则校验结果。
struct UserRuleValidationResult: Sendable, Equatable {
    var errors: [UserRuleValidationIssue]

    var isValid: Bool { errors.isEmpty }
}

/// 批量用户规则校验报告：合法条进入系统，非法条留给 UI / 导入预览展示。
struct UserRulesValidationReport {
    var acceptedRules: [CleaningRule]
    var errors: [UserRuleValidationIssue]
}

/// 校验策略：可注入测试用主目录，便于夹具与 symlink 逃逸单测。
struct UserRuleValidationPolicy: Sendable {
    /// 用户主目录（生产为 `NSHomeDirectory()`，测试可注入临时目录）。
    var homeURL: URL

    /// 主目录下允许的顶层子树（相对路径首段）。
    var allowedHomeSubtrees: [String]

    /// 允许的 argv[0]：裸命令名或规范化绝对路径。
    var allowedCommandExecutables: Set<String>

    /// `docker` 允许的 token 前缀表：`[subcommand…]`（不含 argv[0]）。
    var allowedDockerTokenPrefixes: [[String]]

    /// `docker` 允许的后续 flag。
    var allowedDockerFlags: Set<String>

    init(
        homeURL: URL = URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true),
        allowedHomeSubtrees: [String] = UserRuleValidationPolicy.defaultAllowedHomeSubtrees,
        allowedCommandExecutables: Set<String> = UserRuleValidationPolicy.defaultAllowedExecutables,
        allowedDockerTokenPrefixes: [[String]] = UserRuleValidationPolicy.defaultDockerTokenPrefixes,
        allowedDockerFlags: Set<String> = UserRuleValidationPolicy.defaultDockerAllowedFlags
    ) {
        self.homeURL = homeURL
        self.allowedHomeSubtrees = allowedHomeSubtrees
        self.allowedCommandExecutables = allowedCommandExecutables
        self.allowedDockerTokenPrefixes = allowedDockerTokenPrefixes
        self.allowedDockerFlags = allowedDockerFlags
    }

    static let defaultAllowedHomeSubtrees = [
        "Library",
        "Downloads",
        "Documents",
        "Desktop",
        "Movies",
        "Music",
        "Pictures",
        "Public",
    ]

    static let defaultAllowedExecutables: Set<String> = [
        "docker",
        "/opt/homebrew/bin/docker",
        "/usr/local/bin/docker",
    ]

    /// 文档化：`docker system prune` + 常见安全 flag。
    static let defaultDockerTokenPrefixes: [[String]] = [
        ["system", "prune"],
    ]

    static let defaultDockerAllowedFlags: Set<String> = [
        "-a", "-f", "--all", "--force",
    ]
}

/// RFC 009 单一校验入口：加载 / 保存 / 导入共用。
enum UserRuleValidator {
    /// Shell 元字符：用户规则 command 禁止当作 shell 脚本拼接。
    private static let shellMetacharacters = CharacterSet(charactersIn: ";|&`$()<>\n\r")

    static func validate(_ rule: CleaningRule, policy: UserRuleValidationPolicy = .init()) -> UserRuleValidationResult {
        switch rule.type {
        case .dir:
            return validateDirRule(rule, policy: policy)
        case .command:
            return validateCommandRule(rule, policy: policy)
        }
    }

    static func validate(_ rules: [CleaningRule], policy: UserRuleValidationPolicy = .init()) -> UserRulesValidationReport {
        let pairs = rules.map { ($0, validate($0, policy: policy)) }
        return UserRulesValidationReport(
            acceptedRules: pairs.filter { $0.1.isValid }.map(\.0),
            errors: pairs.flatMap { $0.1.errors }
        )
    }

    // MARK: - Paths

    private static func validateDirRule(_ rule: CleaningRule, policy: UserRuleValidationPolicy) -> UserRuleValidationResult {
        guard let paths = rule.paths, !paths.isEmpty else {
            return UserRuleValidationResult(errors: [
                UserRuleValidationIssue(ruleId: rule.id, reason: .missingPaths, detail: rule.id),
            ])
        }
        var errors: [UserRuleValidationIssue] = []
        for entry in paths {
            let candidates = expandedTargetPaths(base: entry.base, dirs: entry.dirs, homeURL: policy.homeURL)
            for path in candidates {
                if !isPathAllowed(path, policy: policy) {
                    errors.append(
                        UserRuleValidationIssue(
                            ruleId: rule.id,
                            reason: .pathOutsideAllowedSubtree,
                            detail: path
                        )
                    )
                }
            }
        }
        return UserRuleValidationResult(errors: errors)
    }

    /// 展开 `~` 到策略主目录，并组合 dirs。
    static func expandedTargetPaths(base: String, dirs: [String], homeURL: URL) -> [String] {
        let expandedBase = expandTilde(base, homeURL: homeURL)
        if dirs.isEmpty {
            return [expandedBase]
        }
        return dirs.map { dir in
            if dir == "." || dir.isEmpty {
                return expandedBase
            }
            return (expandedBase as NSString).appendingPathComponent(dir)
        }
    }

    static func expandTilde(_ path: String, homeURL: URL) -> String {
        if path == "~" {
            return homeURL.path
        }
        if path.hasPrefix("~/") {
            let rest = String(path.dropFirst(2))
            return homeURL.appendingPathComponent(rest).path
        }
        return path
    }

    /// 解析符号链接后须落在主目录允许子树内。
    static func isPathAllowed(_ path: String, policy: UserRuleValidationPolicy) -> Bool {
        let homeResolved = policy.homeURL.resolvingSymlinksInPath().standardizedFileURL.path
        let resolved = URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL.path
        guard resolved == homeResolved || resolved.hasPrefix(homeResolved + "/") else {
            return false
        }
        if resolved == homeResolved {
            return false
        }
        let relative = String(resolved.dropFirst(homeResolved.count + 1))
        return policy.allowedHomeSubtrees.contains { subtree in
            relative == subtree || relative.hasPrefix(subtree + "/")
        }
    }

    // MARK: - Commands

    /// argv[0] 必须整段命中白名单（裸 `docker` 或绝对路径）；禁止任意路径仅凭 basename 冒充。
    private static func isAllowedExecutable(_ argv0: String, policy: UserRuleValidationPolicy) -> Bool {
        if policy.allowedCommandExecutables.contains(argv0) {
            return true
        }
        guard argv0.contains("/") else {
            return false
        }
        let normalized = URL(fileURLWithPath: argv0).resolvingSymlinksInPath().standardizedFileURL.path
        return policy.allowedCommandExecutables.contains(normalized)
    }

    private static func validateCommandRule(_ rule: CleaningRule, policy: UserRuleValidationPolicy) -> UserRuleValidationResult {
        guard let command = rule.command?.trimmingCharacters(in: .whitespacesAndNewlines), !command.isEmpty else {
            return UserRuleValidationResult(errors: [
                UserRuleValidationIssue(ruleId: rule.id, reason: .missingCommand, detail: rule.id),
            ])
        }

        if command.rangeOfCharacter(from: shellMetacharacters) != nil {
            return UserRuleValidationResult(errors: [
                UserRuleValidationIssue(ruleId: rule.id, reason: .commandContainsShellSyntax, detail: command),
            ])
        }

        let tokens = command.split(whereSeparator: \.isWhitespace).map(String.init)
        guard let argv0 = tokens.first else {
            return UserRuleValidationResult(errors: [
                UserRuleValidationIssue(ruleId: rule.id, reason: .missingCommand, detail: rule.id),
            ])
        }

        guard isAllowedExecutable(argv0, policy: policy) else {
            return UserRuleValidationResult(errors: [
                UserRuleValidationIssue(ruleId: rule.id, reason: .commandExecutableNotAllowed, detail: argv0),
            ])
        }

        let executableName = (argv0 as NSString).lastPathComponent
        if executableName == "docker" {
            return validateDockerTokens(Array(tokens.dropFirst()), policy: policy, rule: rule, fullCommand: command)
        }

        return UserRuleValidationResult(errors: [
            UserRuleValidationIssue(ruleId: rule.id, reason: .commandSubcommandNotAllowed, detail: command),
        ])
    }

    private static func validateDockerTokens(
        _ tokens: [String],
        policy: UserRuleValidationPolicy,
        rule: CleaningRule,
        fullCommand: String
    ) -> UserRuleValidationResult {
        for prefix in policy.allowedDockerTokenPrefixes {
            guard tokens.count >= prefix.count else { continue }
            let head = Array(tokens.prefix(prefix.count))
            guard head == prefix else { continue }
            let flags = Set(tokens.dropFirst(prefix.count))
            guard flags.isSubset(of: policy.allowedDockerFlags) else {
                return UserRuleValidationResult(errors: [
                    UserRuleValidationIssue(ruleId: rule.id, reason: .commandSubcommandNotAllowed, detail: fullCommand),
                ])
            }
            return UserRuleValidationResult(errors: [])
        }
        return UserRuleValidationResult(errors: [
            UserRuleValidationIssue(ruleId: rule.id, reason: .commandSubcommandNotAllowed, detail: fullCommand),
        ])
    }
}
