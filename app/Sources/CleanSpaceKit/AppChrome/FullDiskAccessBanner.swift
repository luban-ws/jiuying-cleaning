import SwiftUI

/// RFC 004：规则页与磁盘页共用的「完全磁盘访问」引导条。
struct FullDiskAccessBanner: View {
    var onOpenSettings: () -> Void
    var onLater: () -> Void
    var onDontAskAgain: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.FullDiskAccess.bannerTitle, systemImage: "lock.shield")
                .font(.headline)
                .symbolRenderingMode(.hierarchical)

            Text(L10n.FullDiskAccess.bannerBody)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(L10n.FullDiskAccess.honestNote)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Button(L10n.FullDiskAccess.openSettings, action: onOpenSettings)
                    .buttonStyle(.borderedProminent)
                    .help(L10n.FullDiskAccess.helpOpenSettings)

                Button(L10n.FullDiskAccess.later, action: onLater)
                    .buttonStyle(.bordered)

                Button(L10n.FullDiskAccess.dontAskAgain, action: onDontAskAgain)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help(L10n.FullDiskAccess.helpDontAskAgain)

                Spacer(minLength: 0)
            }
            .controlSize(.regular)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .fill(Material.regular)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.35), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.FullDiskAccess.bannerTitle)
        .accessibilityHint(L10n.FullDiskAccess.honestNote)
    }
}
