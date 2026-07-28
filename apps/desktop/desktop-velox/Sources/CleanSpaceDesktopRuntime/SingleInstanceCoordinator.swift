import Darwin
import Foundation

enum SingleInstanceIdentifier {
    static let production = "me.systembug.cleaning"
    static let environmentKey = "CLEANING_BUNDLE_IDENTIFIER"

    static func resolve(
        bundleIdentifier: String?,
        environment: [String: String]
    ) -> String {
        if let bundleIdentifier, !bundleIdentifier.isEmpty {
            return bundleIdentifier
        }
        if let environmentIdentifier = environment[environmentKey],
           !environmentIdentifier.isEmpty {
            return environmentIdentifier
        }
        return production
    }
}

enum SingleInstanceRole: Equatable {
    case primary
    case secondary
}

protocol SingleInstanceWakeChannel: AnyObject {
    func startObserving(_ handler: @escaping () -> Void)
    func sendWakeRequest()
    func stopObserving()
}

final class DistributedSingleInstanceWakeChannel: NSObject, SingleInstanceWakeChannel, @unchecked Sendable {
    private let notificationCenter: DistributedNotificationCenter
    private let notificationName: Notification.Name
    private var handler: (() -> Void)?

    init(
        notificationName: Notification.Name,
        notificationCenter: DistributedNotificationCenter = .default()
    ) {
        self.notificationName = notificationName
        self.notificationCenter = notificationCenter
    }

    deinit {
        stopObserving()
    }

    func startObserving(_ handler: @escaping () -> Void) {
        stopObserving()
        self.handler = handler
        notificationCenter.addObserver(
            self,
            selector: #selector(receiveWakeRequest),
            name: notificationName,
            object: nil
        )
    }

    func sendWakeRequest() {
        notificationCenter.postNotificationName(
            notificationName,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    func stopObserving() {
        notificationCenter.removeObserver(
            self,
            name: notificationName,
            object: nil
        )
        handler = nil
    }

    @objc private func receiveWakeRequest(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.handler?()
        }
    }
}

final class SingleInstanceCoordinator {
    private let lockURL: URL
    private let wakeChannel: SingleInstanceWakeChannel
    private var lockDescriptor: Int32?

    init(lockURL: URL, wakeChannel: SingleInstanceWakeChannel) {
        self.lockURL = lockURL
        self.wakeChannel = wakeChannel
    }

    deinit {
        stop()
    }

    func start(onWake: @escaping () -> Void) throws -> SingleInstanceRole {
        try FileManager.default.createDirectory(
            at: lockURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let descriptor = open(
            lockURL.path,
            O_RDWR | O_CREAT,
            mode_t(S_IRUSR | S_IWUSR)
        )
        guard descriptor >= 0 else {
            throw posixError(path: lockURL.path)
        }

        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            let errorCode = errno
            close(descriptor)
            guard errorCode == EWOULDBLOCK else {
                throw posixError(code: errorCode, path: lockURL.path)
            }
            wakeChannel.sendWakeRequest()
            return .secondary
        }

        lockDescriptor = descriptor
        wakeChannel.startObserving(onWake)
        return .primary
    }

    func stop() {
        wakeChannel.stopObserving()
        guard let lockDescriptor else {
            return
        }
        flock(lockDescriptor, LOCK_UN)
        close(lockDescriptor)
        self.lockDescriptor = nil
    }

    private func posixError(code: Int32 = errno, path: String) -> NSError {
        NSError(
            domain: NSPOSIXErrorDomain,
            code: Int(code),
            userInfo: [NSFilePathErrorKey: path]
        )
    }
}

extension SingleInstanceCoordinator {
    static func live() -> SingleInstanceCoordinator {
        let identifier = SingleInstanceIdentifier.resolve(
            bundleIdentifier: Bundle.main.bundleIdentifier,
            environment: ProcessInfo.processInfo.environment
        )
        let lockURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches", isDirectory: true)
            .appendingPathComponent(identifier, isDirectory: true)
            .appendingPathComponent("instance.lock")
        let wakeChannel = DistributedSingleInstanceWakeChannel(
            notificationName: Notification.Name("\(identifier).activate-primary")
        )
        return SingleInstanceCoordinator(lockURL: lockURL, wakeChannel: wakeChannel)
    }
}
