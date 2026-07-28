//
//  VolumeScannerService.swift
//  CleanSpace
//
//  枚举已挂载卷并按「每盘」展示空间与顶层目录占用。
//

import Foundation

struct MountedVolume: Identifiable, Hashable {
    var id: String { url.path }
    let url: URL
    let name: String
    let totalBytes: Int64?
    let freeBytes: Int64?
}

struct TopLevelFolderSize: Identifiable {
    var id: String { path }
    let name: String
    let path: String
    let bytes: Int64
}

/// 卷「已用」与顶层扫描合计的差额（纯函数，便于单测）
enum VolumeDiskAccounting {
    /// 系统报告的已用字节（总容量 − 可用）；任一缺失则返回 nil
    static func volumeUsedBytes(total: Int64?, free: Int64?) -> Int64? {
        guard let t = total, let f = free, t > 0 else { return nil }
        return max(0, t - f)
    }

    /// 顶层扫描结果之和
    static func topLevelFoldersSum(_ rows: [TopLevelFolderSize]) -> Int64 {
        rows.reduce(0) { $0 + $1.bytes }
    }

    /// 已用 − 顶层合计，不为负；表示快照、无权目录、APFS 特性等未体现在逐文件累加中的部分
    static func unaccountedUsedBytes(volumeUsed: Int64, topLevelSum: Int64) -> Int64 {
        max(0, volumeUsed - topLevelSum)
    }

    /// 根目录下多条目若解析到同一规范路径（如 `/var` → `/private/var`），只保留一条以免重复累加
    static func filterCanonicalRootDuplicates(candidates: [(url: URL, name: String)]) -> [(url: URL, name: String)] {
        struct Item {
            let url: URL
            let name: String
            let canonical: String
        }
        let items: [Item] = candidates.map { Item(url: $0.url, name: $0.name, canonical: $0.url.resolvingSymlinksInPath().path) }
        let sorted = items.sorted {
            if $0.canonical.count != $1.canonical.count { return $0.canonical.count < $1.canonical.count }
            return $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
        var kept: [Item] = []
        for cand in sorted {
            if kept.contains(where: { $0.canonical == cand.canonical }) { continue }
            if kept.contains(where: { cand.canonical.hasPrefix($0.canonical + "/") }) { continue }
            kept.append(cand)
        }
        return kept
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map { ($0.url, $0.name) }
    }
}

enum VolumeScannerService {
    /// 启动卷 + /Volumes 下外置卷
    static func listMountedVolumes() -> [MountedVolume] {
        let keys: Set<URLResourceKey> = [
            .volumeNameKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]
        var seen = Set<String>()
        var result: [MountedVolume] = []

        let appendVolume: (URL) -> Void = { root in
            let path = root.path
            guard !seen.contains(path) else { return }
            seen.insert(path)
            guard let vals = try? root.resourceValues(forKeys: keys) else { return }
            let name = vals.volumeName ?? root.lastPathComponent
            let total = vals.volumeTotalCapacity.map { Int64($0) }
            let free = vals.volumeAvailableCapacityForImportantUsage.map { Int64($0) }
            result.append(MountedVolume(url: root, name: name, totalBytes: total, freeBytes: free))
        }

        appendVolume(URL(fileURLWithPath: "/"))

        let volRoot = URL(fileURLWithPath: "/Volumes")
        if let kids = try? FileManager.default.contentsOfDirectory(
            at: volRoot,
            includingPropertiesForKeys: [.isVolumeKey],
            options: [.skipsHiddenFiles]
        ) {
            for u in kids {
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: u.path, isDirectory: &isDir), isDir.boolValue else { continue }
                appendVolume(u)
            }
        }

        return result
    }

    /// 扫描某卷根目录下一层文件夹占用，并收集权限拒绝（RFC 004）。
    static func scanTopLevelFoldersWithAccessReport(on volume: URL) async -> (folders: [TopLevelFolderSize], accessDenial: AccessDenialReport) {
        await Task.detached {
            let fm = FileManager.default
            let skipPrefixes = ["com.apple", ".Spotlight", ".fseventsd", ".TemporaryItems"]
            var report = AccessDenialReport.empty
            let entries: [URL]
            do {
                entries = try fm.contentsOfDirectory(
                    at: volume,
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles]
                )
            } catch {
                report.recordDenial(at: volume.path, error: error)
                return ([], report)
            }

            var candidates: [(url: URL, name: String)] = []
            for entry in entries {
                let path = entry.path
                let name = entry.lastPathComponent
                if skipPrefixes.contains(where: { name.hasPrefix($0) }) { continue }
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { continue }
                candidates.append((entry, name))
            }

            let deduped = VolumeDiskAccounting.filterCanonicalRootDuplicates(candidates: candidates)
            var rows: [TopLevelFolderSize] = []
            for (entry, name) in deduped {
                let sized = directorySizeBytesWithAccessReport(url: entry, enumeratorOptions: [])
                report.merge(sized.accessDenial)
                rows.append(TopLevelFolderSize(name: name, path: entry.path, bytes: sized.bytes))
            }
            return (rows.sorted { $0.bytes > $1.bytes }, report)
        }.value
    }

    /// 扫描某卷根目录下一层文件夹占用（跳过快照等常见系统项以减轻耗时）。
    static func scanTopLevelFolders(on volume: URL) async -> [TopLevelFolderSize] {
        await scanTopLevelFoldersWithAccessReport(on: volume).folders
    }

    /// 同步扫描顶层目录（供 Velox IPC 等非 async 宿主调用）。
    static func scanTopLevelFoldersSynchronously(on volume: URL) -> (folders: [TopLevelFolderSize], accessDenial: AccessDenialReport) {
        let holder = SyncScanResultHolder()
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            holder.store(await scanTopLevelFoldersWithAccessReport(on: volume))
            semaphore.signal()
        }
        semaphore.wait()
        return holder.value ?? ([], .empty)
    }
}

/// 跨 Task 边界暂存扫描结果（Swift 6 并发安全）。
private final class SyncScanResultHolder: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: (folders: [TopLevelFolderSize], accessDenial: AccessDenialReport)?

    func store(_ value: (folders: [TopLevelFolderSize], accessDenial: AccessDenialReport)) {
        lock.lock()
        defer { lock.unlock() }
        stored = value
    }

    var value: (folders: [TopLevelFolderSize], accessDenial: AccessDenialReport)? {
        lock.lock()
        defer { lock.unlock() }
        return stored
    }
}
