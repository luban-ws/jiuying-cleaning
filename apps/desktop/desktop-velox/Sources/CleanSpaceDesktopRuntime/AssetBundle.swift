//
//  AssetBundle.swift
//  CleanSpaceDesktopRuntime
//

import Foundation

public struct AssetBundle: Sendable {
    public let assetRoots: [URL]

    public init(resourceModulePath: String = "CleanSpaceDesktop") {
        let fileManager = FileManager.default
        var candidates: [URL] = []

        if let bundleURL = Bundle.main.resourceURL?.appendingPathComponent("assets") {
            candidates.append(bundleURL)
        }

        let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let executableDir = executableURL.deletingLastPathComponent()
        candidates.append(executableDir.appendingPathComponent("assets"))

        let cwd = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        candidates.append(
            cwd
                .appendingPathComponent("Sources")
                .appendingPathComponent(resourceModulePath)
                .appendingPathComponent("Resources")
                .appendingPathComponent("assets")
        )

        let existing = candidates.filter { candidate in
            fileManager.fileExists(atPath: candidate.appendingPathComponent("index.html").path)
        }
        assetRoots = existing.isEmpty ? candidates : existing
    }

    public func mimeType(for path: String) -> String {
        let ext = (path as NSString).pathExtension.lowercased()
        switch ext {
        case "html", "htm": return "text/html"
        case "css": return "text/css"
        case "js": return "application/javascript"
        case "json": return "application/json"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "svg": return "image/svg+xml"
        case "woff", "woff2": return "font/woff2"
        default: return "application/octet-stream"
        }
    }

    public func loadAsset(path: String) -> (data: Data, mimeType: String)? {
        var normalizedPath = path
        if normalizedPath.hasPrefix("/") {
            normalizedPath = String(normalizedPath.dropFirst())
        }
        if normalizedPath.isEmpty {
            normalizedPath = "index.html"
        }
        for root in assetRoots {
            let fullPath = root.appendingPathComponent(normalizedPath)
            if let data = try? Data(contentsOf: fullPath) {
                return (data, mimeType(for: normalizedPath))
            }
        }
        return nil
    }
}
