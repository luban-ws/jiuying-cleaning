import Foundation
import Testing
@testable import CleanSpaceKit

/// RFC 004：触发条件与回归——禁止仅靠体积为 0。
@Suite("Full Disk Access guidance")
struct FullDiskAccessGuidanceTests {
    @Test("EPERM and EACCES are permission denials")
    func posixPermissionDenials() {
        let eperm = NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil)
        let eacces = NSError(domain: NSPOSIXErrorDomain, code: Int(EACCES), userInfo: nil)
        #expect(FullDiskAccessGuidance.isPermissionDenied(eperm))
        #expect(FullDiskAccessGuidance.isPermissionDenied(eacces))
    }

    @Test("Cocoa no-permission codes are permission denials")
    func cocoaPermissionDenials() {
        let readDenied = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoPermissionError, userInfo: nil)
        let writeDenied = NSError(domain: NSCocoaErrorDomain, code: NSFileWriteNoPermissionError, userInfo: nil)
        #expect(FullDiskAccessGuidance.isPermissionDenied(readDenied))
        #expect(FullDiskAccessGuidance.isPermissionDenied(writeDenied))
    }

    @Test("Unrelated errors are not permission denials")
    func unrelatedErrors() {
        let missing = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT), userInfo: nil)
        let cocoaMissing = NSError(domain: NSCocoaErrorDomain, code: NSFileNoSuchFileError, userInfo: nil)
        #expect(!FullDiskAccessGuidance.isPermissionDenied(missing))
        #expect(!FullDiskAccessGuidance.isPermissionDenied(cocoaMissing))
    }

    @Test("Zero bytes alone must not trigger guidance")
    func zeroBytesAloneDoesNotTrigger() {
        #expect(
            !FullDiskAccessGuidance.shouldOfferGuidance(
                hadPermissionDenial: false,
                deniedPath: nil,
                scannedBytesZero: true
            )
        )
        #expect(!FullDiskAccessGuidance.shouldOfferGuidance(deniedPaths: []))
    }

    @Test("Permission denial triggers guidance even when bytes are zero")
    func denialTriggersEvenIfZero() {
        #expect(
            FullDiskAccessGuidance.shouldOfferGuidance(
                hadPermissionDenial: true,
                deniedPath: "/tmp/example",
                scannedBytesZero: true
            )
        )
    }

    @Test("Known restricted prefixes match home Library paths")
    func knownPrefixes() {
        let mail = NSHomeDirectory() + "/Library/Mail/V10"
        let safari = NSHomeDirectory() + "/Library/Safari"
        let tmp = "/tmp/clean-space-test"
        #expect(FullDiskAccessGuidance.pathMatchesKnownRestrictedPrefix(mail))
        #expect(FullDiskAccessGuidance.pathMatchesKnownRestrictedPrefix(safari))
        #expect(!FullDiskAccessGuidance.pathMatchesKnownRestrictedPrefix(tmp))
    }

    @Test("AccessDenialReport only records permission denials")
    func denialReportFilters() {
        var report = AccessDenialReport.empty
        let eperm = NSError(domain: NSPOSIXErrorDomain, code: Int(EPERM), userInfo: nil)
        let enoent = NSError(domain: NSPOSIXErrorDomain, code: Int(ENOENT), userInfo: nil)
        report.recordDenial(at: "/a", error: eperm)
        report.recordDenial(at: "/b", error: enoent)
        #expect(report.deniedPaths == ["/a"])
        #expect(FullDiskAccessGuidance.shouldOfferGuidance(deniedPaths: report.deniedPaths))
    }

    @Test("shouldPresentBanner respects permanent suppression")
    func suppressionGate() {
        FullDiskAccessGuidance.resetGuidanceSuppressionForTests()
        defer { FullDiskAccessGuidance.resetGuidanceSuppressionForTests() }

        let paths = [NSHomeDirectory() + "/Library/Mail"]
        #expect(FullDiskAccessGuidance.shouldPresentBanner(deniedPaths: paths))
        FullDiskAccessGuidance.suppressGuidancePermanently()
        #expect(!FullDiskAccessGuidance.shouldPresentBanner(deniedPaths: paths))
    }
}
