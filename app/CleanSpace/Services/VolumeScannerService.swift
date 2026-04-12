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

    /// 扫描某卷根目录下一层文件夹占用（跳过快照等常见系统项以减轻耗时）
    static func scanTopLevelFolders(on volume: URL) async -> [TopLevelFolderSize] {
        await Task.detached {
            let fm = FileManager.default
            let skipPrefixes = ["com.apple", ".Spotlight", ".fseventsd", ".TemporaryItems"]
            guard let entries = try? fm.contentsOfDirectory(
                at: volume,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else { return [] }

            var rows: [TopLevelFolderSize] = []
            for entry in entries {
                let path = entry.path
                let name = entry.lastPathComponent
                if skipPrefixes.contains(where: { name.hasPrefix($0) }) { continue }
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else { continue }
                let bytes = directorySizeBytes(url: entry)
                rows.append(TopLevelFolderSize(name: name, path: path, bytes: bytes))
            }
            return rows.sorted { $0.bytes > $1.bytes }
        }.value
    }
}
