import AppKit
import Foundation

/// RFC 004：完全磁盘访问引导的触发判定、已知受限前缀与系统设置跳转。
/// 主触发必须有 errno/API 权限拒绝证据；禁止仅因扫描体积为 0。
enum FullDiskAccessGuidance {
    /// UserDefaults：用户选择「不再提示」后全局抑制引导。
    static let suppressGuidanceDefaultsKey = "fullDiskAccess.suppressGuidance"

    /// 未授权时常见不可枚举路径前缀（`~` 已展开后的绝对路径匹配）。
    /// 与权限拒绝错误组合使用，用于强化文案上下文；单独匹配不触发引导。
    static let knownRestrictedPathPrefixes: [String] = {
        let home = NSHomeDirectory()
        return [
            home + "/Library/Mail",
            home + "/Library/Safari",
            home + "/Library/Messages",
            home + "/Library/Cookies",
            home + "/Library/PersonalizationPortrait",
            home + "/Library/Containers",
            home + "/Library/Group Containers",
            home + "/Library/Application Support/AddressBook",
            home + "/Library/Application Support/CallHistoryDB",
            home + "/Library/Application Support/com.apple.TCC",
            home + "/Library/Calendars",
            home + "/Library/Reminders",
            home + "/Library/IdentityServices",
            home + "/Library/Metadata/CoreSpotlight",
            home + "/Library/Suggestions",
            home + "/Library/IntelligencePlatform",
            "/Library/Application Support",
            "/private/var/db",
        ]
    }()

    /// 系统设置 → 隐私与安全性 → 完全磁盘访问（Ventura+ 与旧 pane 回退）。
    private static let settingsURLCandidates = [
        "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
        "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
    ]

    // MARK: - 触发判定（纯函数）

    /// 是否为明确的权限拒绝（POSIX `EPERM`/`EACCES` 或 Cocoa 权限相关域）。
    static func isPermissionDenied(_ error: Error) -> Bool {
        let ns = error as NSError
        if ns.domain == NSPOSIXErrorDomain {
            return ns.code == Int(EPERM) || ns.code == Int(EACCES)
        }
        if ns.domain == NSCocoaErrorDomain {
            // NSFileReadNoPermissionError = 257；NSFileWriteNoPermissionError = 513
            return ns.code == NSFileReadNoPermissionError || ns.code == NSFileWriteNoPermissionError
        }
        return false
    }

    /// 路径是否落在已知受限前缀下（标准化后前缀匹配）。
    static func pathMatchesKnownRestrictedPrefix(_ path: String) -> Bool {
        let standardized = (path as NSString).standardizingPath
        return knownRestrictedPathPrefixes.contains { prefix in
            let p = (prefix as NSString).standardizingPath
            return standardized == p || standardized.hasPrefix(p + "/")
        }
    }

    /// RFC 004 主触发：必须有权限拒绝错误；可选路径用于已知前缀上下文。
    /// - Parameters:
    ///   - hadPermissionDenial: 本次操作是否捕获到权限拒绝
    ///   - deniedPath: 被拒绝的路径（可空；有则参与已知前缀判断）
    ///   - scannedBytesZero: 仅用于回归断言——**不得**单独触发
    static func shouldOfferGuidance(
        hadPermissionDenial: Bool,
        deniedPath: String? = nil,
        scannedBytesZero: Bool = false
    ) -> Bool {
        // 禁止：仅因体积为 0
        if scannedBytesZero && !hadPermissionDenial {
            return false
        }
        guard hadPermissionDenial else { return false }
        // 主触发：任意明确权限拒绝即可
        // 辅：若带路径且命中已知前缀，仍为 true（与 RFC「任一」一致）
        if let deniedPath, pathMatchesKnownRestrictedPrefix(deniedPath) {
            return true
        }
        return true
    }

    /// 批量：任一拒绝路径满足主触发则应展示引导。
    static func shouldOfferGuidance(deniedPaths: [String]) -> Bool {
        guard !deniedPaths.isEmpty else { return false }
        return deniedPaths.contains { path in
            shouldOfferGuidance(hadPermissionDenial: true, deniedPath: path)
        }
    }

    // MARK: - 用户偏好

    static var isGuidanceSuppressed: Bool {
        UserDefaults.standard.bool(forKey: suppressGuidanceDefaultsKey)
    }

    static func suppressGuidancePermanently() {
        UserDefaults.standard.set(true, forKey: suppressGuidanceDefaultsKey)
    }

    static func resetGuidanceSuppressionForTests() {
        UserDefaults.standard.removeObject(forKey: suppressGuidanceDefaultsKey)
    }

    /// 在未永久抑制时，根据拒绝路径决定是否展示。
    static func shouldPresentBanner(deniedPaths: [String]) -> Bool {
        guard !isGuidanceSuppressed else { return false }
        return shouldOfferGuidance(deniedPaths: deniedPaths)
    }

    // MARK: - 系统设置

    @discardableResult
    static func openFullDiskAccessSettings() -> Bool {
        for raw in settingsURLCandidates {
            guard let url = URL(string: raw) else { continue }
            if NSWorkspace.shared.open(url) {
                return true
            }
        }
        return false
    }
}

/// 扫描过程中收集到的权限拒绝路径（可跨规则合并）。
struct AccessDenialReport: Sendable, Equatable {
    var deniedPaths: [String]

    static let empty = AccessDenialReport(deniedPaths: [])

    var isEmpty: Bool { deniedPaths.isEmpty }

    mutating func recordDenial(at path: String, error: Error) {
        guard FullDiskAccessGuidance.isPermissionDenied(error) else { return }
        if !deniedPaths.contains(path) {
            deniedPaths.append(path)
        }
    }

    mutating func merge(_ other: AccessDenialReport) {
        for path in other.deniedPaths where !deniedPaths.contains(path) {
            deniedPaths.append(path)
        }
    }
}
