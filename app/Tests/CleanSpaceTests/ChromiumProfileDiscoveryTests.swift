@testable import CleanSpaceKit
import Foundation
import Testing

@Suite("Chromium profile discovery")
struct ChromiumProfileDiscoveryTests {
    @Test("Discovers multiple profiles with correct shapes")
    func discoverMultipleProfiles() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        // Create Default profile
        let defaultDir = tempDir.appendingPathComponent("Default")
        try fm.createDirectory(at: defaultDir, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: defaultDir.appendingPathComponent("Preferences"))
        
        // Create Profile 1 profile
        let profile1Dir = tempDir.appendingPathComponent("Profile 1")
        try fm.createDirectory(at: profile1Dir, withIntermediateDirectories: true)
        try Data("cookies_db".utf8).write(to: profile1Dir.appendingPathComponent("Cookies"))
        
        // Create Profile 2 profile (using Guest Profile style)
        let guestDir = tempDir.appendingPathComponent("Guest Profile")
        try fm.createDirectory(at: guestDir, withIntermediateDirectories: true)
        // No files inside, but name is recognized Guest Profile
        
        // Create non-profile folder
        let randomDir = tempDir.appendingPathComponent("RandomFolder")
        try fm.createDirectory(at: randomDir, withIntermediateDirectories: true)
        
        let discovered = ChromiumProfileDiscoverer.discoverProfiles(in: tempDir.path)
        #expect(discovered.count == 3)
        #expect(discovered.contains("Default"))
        #expect(discovered.contains("Profile 1"))
        #expect(discovered.contains("Guest Profile"))
        #expect(!discovered.contains("RandomFolder"))
    }
    
    @Test("Handles zero profiles gracefully")
    func discoverZeroProfiles() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        let discovered = ChromiumProfileDiscoverer.discoverProfiles(in: tempDir.path)
        #expect(discovered.isEmpty)
    }
    
    @Test("Skips non-directory items")
    func discoverNonDirectoryItems() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        // Create a regular file named 'Default' (which matches profile name check, but is not a dir)
        let defaultFile = tempDir.appendingPathComponent("Default")
        try Data().write(to: defaultFile)
        
        let discovered = ChromiumProfileDiscoverer.discoverProfiles(in: tempDir.path)
        #expect(discovered.isEmpty)
    }
    
    @Test("Skips symlinks escaping app root")
    func discoverEscapingSymlinks() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        // Create a external folder representing a directory outside the app root
        let externalDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: externalDir, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: externalDir.appendingPathComponent("Preferences"))
        defer {
            try? fm.removeItem(at: externalDir)
        }
        
        // Create a symlink named Default pointing to externalDir
        let symlinkURL = tempDir.appendingPathComponent("Default")
        try fm.createSymbolicLink(at: symlinkURL, withDestinationURL: externalDir)
        
        let discovered = ChromiumProfileDiscoverer.discoverProfiles(in: tempDir.path)
        #expect(discovered.isEmpty) // Should skip because it escapes
    }
    
    @Test("Includes valid symlinks inside app root")
    func discoverValidSymlinks() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        // Create a folder inside app root
        let targetDir = tempDir.appendingPathComponent("TargetProfile")
        try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: targetDir.appendingPathComponent("Preferences"))
        
        // Create a valid symlink inside app root pointing to TargetProfile
        let symlinkURL = tempDir.appendingPathComponent("Default")
        try fm.createSymbolicLink(at: symlinkURL, withDestinationURL: targetDir)
        
        let discovered = ChromiumProfileDiscoverer.discoverProfiles(in: tempDir.path)
        #expect(discovered.count == 2)
        #expect(discovered.contains("Default"))
        #expect(discovered.contains("TargetProfile"))
    }
    
    @Test("resolvePaths expands Chromium default base path to discovered profiles")
    func resolvePathsWithProfiles() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        // Setup multiple profiles inside tempDir
        let p1 = tempDir.appendingPathComponent("Default")
        let p2 = tempDir.appendingPathComponent("Profile 1")
        try fm.createDirectory(at: p1, withIntermediateDirectories: true)
        try fm.createDirectory(at: p2, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: p1.appendingPathComponent("Preferences"))
        try Data("{}".utf8).write(to: p2.appendingPathComponent("Preferences"))
        
        // Create mock rules with base path ending in Default
        let ruleJson = """
        {
          "id": "mock-chrome-cookies",
          "category": "browser",
          "name": "Mock Chrome Cookies",
          "type": "dir",
          "paths": [
            { "base": "\(tempDir.path)/Default", "dirs": ["Cookies", "History"] }
          ]
        }
        """
        let rule = try JSONDecoder().decode(CleaningRule.self, from: Data(ruleJson.utf8))
        
        let resolved = resolvePaths(for: rule)
        #expect(resolved.count == 4) // (Default/Cookies, Default/History) + (Profile 1/Cookies, Profile 1/History)
        
        let expected = [
            tempDir.path + "/Default/Cookies",
            tempDir.path + "/Default/History",
            tempDir.path + "/Profile 1/Cookies",
            tempDir.path + "/Profile 1/History"
        ]
        for path in expected {
            #expect(resolved.contains(path))
        }
    }

    @Test("discoverProfiles returns empty for non-existent path")
    func discoverNonExistentDirectory() {
        let discovered = ChromiumProfileDiscoverer.discoverProfiles(in: "/nonexistent/path/for/google/chrome")
        #expect(discovered.isEmpty)
    }

    @Test("discoverProfiles ignores directories starting with dot")
    func discoverIgnoredDotPrefix() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        let dotDir = tempDir.appendingPathComponent(".Default")
        try fm.createDirectory(at: dotDir, withIntermediateDirectories: true)
        try Data("{}".utf8).write(to: dotDir.appendingPathComponent("Preferences"))
        
        let discovered = ChromiumProfileDiscoverer.discoverProfiles(in: tempDir.path)
        #expect(discovered.isEmpty)
    }

    @Test("discoverProfiles skips symlinks pointing to files")
    func discoverSymlinkPointingToFile() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        let targetFile = tempDir.appendingPathComponent("target_file.txt")
        try Data("test".utf8).write(to: targetFile)
        
        let symlinkURL = tempDir.appendingPathComponent("Default")
        try fm.createSymbolicLink(at: symlinkURL, withDestinationURL: targetFile)
        
        let discovered = ChromiumProfileDiscoverer.discoverProfiles(in: tempDir.path)
        #expect(discovered.isEmpty)
    }

    @Test("Heuristics detect diverse profile indicators")
    func discoverHeuristics() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        // 1. Secure Preferences
        let p1 = tempDir.appendingPathComponent("P1")
        try fm.createDirectory(at: p1, withIntermediateDirectories: true)
        try Data().write(to: p1.appendingPathComponent("Secure Preferences"))
        
        // 2. Network/Cookies
        let p2 = tempDir.appendingPathComponent("P2")
        let netDir = p2.appendingPathComponent("Network")
        try fm.createDirectory(at: netDir, withIntermediateDirectories: true)
        try Data().write(to: netDir.appendingPathComponent("Cookies"))
        
        // 3. System Profile name
        let systemDir = tempDir.appendingPathComponent("System Profile")
        try fm.createDirectory(at: systemDir, withIntermediateDirectories: true)
        
        // 4. Invalid Profile prefix (Profile ABC - non-number)
        let invalidProfileDir = tempDir.appendingPathComponent("Profile ABC")
        try fm.createDirectory(at: invalidProfileDir, withIntermediateDirectories: true)
        
        let discovered = ChromiumProfileDiscoverer.discoverProfiles(in: tempDir.path)
        #expect(discovered.count == 3)
        #expect(discovered.contains("P1"))
        #expect(discovered.contains("P2"))
        #expect(discovered.contains("System Profile"))
        #expect(!discovered.contains("Profile ABC"))
    }

    @Test("resolvePaths handles non-profile bases and fallback when profile list is empty")
    func resolvePathsFallback() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer {
            try? fm.removeItem(at: tempDir)
        }
        
        // Case 1: Base is not a profile shape (e.g. NotProfile)
        let ruleJson1 = """
        {
          "id": "mock-non-profile",
          "category": "browser",
          "name": "Non Profile Base",
          "type": "dir",
          "paths": [
            { "base": "\(tempDir.path)/NotProfile", "dirs": ["Cookies"] }
          ]
        }
        """
        let rule1 = try JSONDecoder().decode(CleaningRule.self, from: Data(ruleJson1.utf8))
        let resolved1 = resolvePaths(for: rule1)
        #expect(resolved1 == [tempDir.path + "/NotProfile/Cookies"])
        
        // Case 2: Base is profile shape (Default), but app root directory has no profiles (empty folder)
        let ruleJson2 = """
        {
          "id": "mock-fallback",
          "category": "browser",
          "name": "Empty Profiles Fallback",
          "type": "dir",
          "paths": [
            { "base": "\(tempDir.path)/Default", "dirs": ["Cookies"] }
          ]
        }
        """
        let rule2 = try JSONDecoder().decode(CleaningRule.self, from: Data(ruleJson2.utf8))
        let resolved2 = resolvePaths(for: rule2)
        #expect(resolved2 == [tempDir.path + "/Default/Cookies"]) // Falls back to default base
    }
}
