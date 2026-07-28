#if os(macOS)
import AppKit

public enum DevelopmentAppIcon {
  @MainActor
  @discardableResult
  public static func install(
    _ icon: NSImage?,
    isAppBundle: Bool,
    devURL: String?,
    application: NSApplication = .shared
  ) -> Bool {
    guard !isAppBundle,
          let devURL,
          !devURL.isEmpty,
          let icon else {
      return false
    }

    application.applicationIconImage = icon
    return true
  }
}
#endif
