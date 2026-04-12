//
//  WorkspaceChrome.swift
//  CleanSpaceKit
//
//  各工作区「仪表盘」式组件：参考磁盘/清理类工具常见的首屏大数字 + 快捷操作 + 卡片化预设，
//  仍使用系统 Material 与圆角，避免脱离 macOS HIG。
//

import SwiftUI

// MARK: - 卷：首屏摘要（大数字 + 用量条）
/// 当前所选卷的可用/已用/总容量，突出「还能用多少」。
struct CSVolumeHeroPanel: View {
    let volumeName: String
    let freeText: String
    let usedText: String
    let totalText: String
    /// 已用占比 0...1；无数据时为 nil，不显示进度条。
    let usageRatio: Double?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Image(systemName: "internaldrive.fill")
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.secondary)
                Text(volumeName)
                    .font(.title2.weight(.semibold))
                    .lineLimit(2)
            }

            HStack(alignment: .top, spacing: 0) {
                heroMetric(title: L10n.Disk.heroAvailable, value: freeText, emphasized: true)
                Spacer(minLength: 16)
                heroMetric(title: L10n.Disk.heroUsed, value: usedText, emphasized: false)
                Spacer(minLength: 16)
                heroMetric(title: L10n.Disk.heroCapacity, value: totalText, emphasized: false)
            }

            if let ratio = usageRatio {
                ProgressView(value: ratio)
                    .progressViewStyle(.linear)
                    .tint(Color.accentColor)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .fill(Material.regular)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.primary.opacity(0.12),
                            Color.primary.opacity(0.04),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }

    private func heroMetric(title: String, value: String, emphasized: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(emphasized ? .title.weight(.semibold) : .title3.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(emphasized ? Color.accentColor : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 规则：概览卡（选中 / 已扫描 一目了然）
struct CSRulesOverviewPanel: View {
    let totalRules: Int
    let selectedCount: Int
    let scannedWithSizeCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "checklist.checked")
                .font(.largeTitle)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .center)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Rules.overviewTitle)
                    .font(.headline)
                Text(L10n.Rules.overviewBlurb)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    overviewChip(text: L10n.Rules.overviewChipTotal(totalRules), prominent: false)
                    overviewChip(text: L10n.Rules.overviewChipSelected(selectedCount), prominent: selectedCount > 0)
                    overviewChip(text: L10n.Rules.overviewChipScanned(scannedWithSizeCount), prominent: scannedWithSizeCount > 0)
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .fill(Material.regular)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        }
    }

    private func overviewChip(text: String, prominent: Bool) -> some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background {
                Capsule(style: .continuous)
                    .fill(prominent ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
            }
            .foregroundStyle(prominent ? Color.accentColor : .secondary)
    }
}

// MARK: - 规则：主清理流程（参考常见清理工具：勾选 → 分析 → 预览 → 运行）
/// 大字号可回收体积 + 横向主按钮，避免操作只藏在工具栏里。
struct CSRulesCleanWorkflowCard: View {
    let recoverableBytes: Int64
    let selectedCount: Int
    let selectedPathRuleCount: Int
    let selectedCommandRuleCount: Int
    let sizedSelectedPathCount: Int
    let rulesNonEmpty: Bool
    let isScanning: Bool
    let isCleaning: Bool
    let onAnalyze: () -> Void
    let onPreview: () -> Void
    let onRunClean: () -> Void
    let onSelectAll: () -> Void
    let onSelectNone: () -> Void

    private var needsAnalyze: Bool {
        selectedPathRuleCount > 0 && sizedSelectedPathCount < selectedPathRuleCount
    }

    private var metricText: String {
        if selectedCount == 0 {
            return L10n.Rules.actionMetricPlaceholder
        }
        if needsAnalyze {
            return L10n.Rules.actionMetricTapAnalyze
        }
        return SpaceFormat.bytes(recoverableBytes)
    }

    private var metricAccent: Bool {
        selectedCount > 0 && !needsAnalyze && recoverableBytes > 0
    }

    private var captionText: String {
        if selectedCount == 0 {
            return L10n.Rules.actionCaptionNone
        }
        return L10n.Rules.actionCaptionCounts(
            selected: selectedCount,
            pathRules: selectedPathRuleCount,
            commandRules: selectedCommandRuleCount
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Rules.actionTitle)
                    .font(.headline)
                Text(L10n.Rules.actionBlurb)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Rules.actionRecoverableLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(metricText)
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(metricAccent ? Color.accentColor : Color.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.55)
                Text(captionText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            // 进度放在主操作区：避免在 unified 工具栏再堆三个与下方重复的图标按钮（HIG：标题栏保持轻量）。
            if isScanning || isCleaning {
                HStack(spacing: 10) {
                    ProgressView()
                        .controlSize(.small)
                    Text(isScanning ? L10n.Rules.scanning : L10n.Rules.cleaning)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            }

            HStack(spacing: 10) {
                Button(action: onAnalyze) {
                    Label(L10n.Rules.scan, systemImage: "gauge.with.dots.needle.bottom.50percent")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .help(L10n.Rules.helpScan)
                .disabled(!rulesNonEmpty || isScanning)

                Button(action: onPreview) {
                    Label(L10n.Rules.dryRun, systemImage: "eye")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .help(L10n.Rules.helpDryRun)
                .disabled(selectedCount == 0 || isCleaning)

                Button(action: onRunClean) {
                    Label(L10n.Rules.clean, systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .help(L10n.Rules.helpClean)
                .disabled(selectedCount == 0 || isCleaning)
            }

            HStack(spacing: 18) {
                Button(L10n.Rules.actionSelectAll, action: onSelectAll)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .disabled(!rulesNonEmpty)
                Button(L10n.Rules.actionSelectNone, action: onSelectNone)
                    .buttonStyle(.plain)
                    .foregroundStyle(Color.accentColor)
                    .disabled(selectedCount == 0)
            }
            .font(.subheadline.weight(.medium))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .fill(Material.regular)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerHero, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

// MARK: - Docker：预设卡片（宫格）
struct CSDockerPresetCard: View {
    let symbolName: String
    let title: String
    let subtitle: String
    let actionTitle: String
    let isDestructive: Bool
    let disabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Image(systemName: symbolName)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isDestructive ? Color.red.opacity(0.9) : Color.accentColor)
                Spacer(minLength: 0)
            }
            Text(title)
                .font(.headline)
                .lineLimit(2)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(4)
            Spacer(minLength: 4)
            Button(actionTitle, action: action)
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                .tint(isDestructive ? .red : Color.accentColor)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(subtitle)
                .disabled(disabled)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .fill(Material.thin)
        }
        .overlay {
            RoundedRectangle(cornerRadius: CS.cornerPanel, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.07), lineWidth: 1)
        }
    }
}
