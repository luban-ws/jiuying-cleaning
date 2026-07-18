import Foundation

struct ChromiumProfileDiscoverer {
    /// 找出应用根目录下的所有 profile 文件夹名称。
    static func discoverProfiles(in appRootPath: String) -> [String] {
        let fm = FileManager.default
        let appRootURL = URL(fileURLWithPath: appRootPath).standardized
        guard let contents = try? fm.contentsOfDirectory(at: appRootURL, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey], options: [.skipsSubdirectoryDescendants]) else {
            return []
        }
        
        var profiles: [String] = []
        let appRootComponents = appRootURL.pathComponents
        
        for url in contents {
            let name = url.lastPathComponent
            
            // 2. 目录名不以句点开头
            guard !name.hasPrefix(".") else { continue }
            
            // 获取资源属性
            guard let resourceValues = try? url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey]) else { continue }
            
            let isDirectory = resourceValues.isDirectory ?? false
            let isSymlink = resourceValues.isSymbolicLink ?? false
            
            // 1. 必须是目录或指向目录的符号链接。如果是符号链接，其解析后的真实路径必须仍在应用根下。
            if isSymlink {
                let realURL = url.resolvingSymlinksInPath().standardized
                var isRealDir: ObjCBool = false
                guard fm.fileExists(atPath: realURL.path, isDirectory: &isRealDir), isRealDir.boolValue else { continue }
                
                // 确保真实路径仍在应用根下
                let realComponents = realURL.pathComponents
                guard realComponents.count >= appRootComponents.count,
                      Array(realComponents.prefix(appRootComponents.count)) == appRootComponents else {
                    continue
                }
            } else {
                guard isDirectory else { continue }
            }
            
            // 3. 启发式判断是否为 profile 文件夹
            if isProfileFolder(name: name, profileURL: url) {
                profiles.append(name)
            }
        }
        
        return profiles.sorted()
    }
    
    private static func isProfileFolder(name: String, profileURL: URL) -> Bool {
        let fm = FileManager.default
        
        // - 存在文件 Preferences 或 Secure Preferences
        if fm.fileExists(atPath: profileURL.appendingPathComponent("Preferences").path) ||
           fm.fileExists(atPath: profileURL.appendingPathComponent("Secure Preferences").path) {
            return true
        }
        
        // - 存在 Network/Cookies 或文件 Cookies
        if fm.fileExists(atPath: profileURL.appendingPathComponent("Network/Cookies").path) ||
           fm.fileExists(atPath: profileURL.appendingPathComponent("Cookies").path) {
            return true
        }
        
        // - 目录名为已知 profile 名：Default、Guest Profile、System Profile
        if name == "Default" || name == "Guest Profile" || name == "System Profile" {
            return true
        }
        
        // - 前缀为 Profile 且后缀为十进制数字
        if name.hasPrefix("Profile ") {
            let numberPart = name.dropFirst("Profile ".count)
            if Int(numberPart) != nil {
                return true
            }
        }
        
        return false
    }
}
