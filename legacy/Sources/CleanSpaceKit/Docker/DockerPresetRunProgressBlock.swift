//
//  DockerPresetRunProgressBlock.swift
//  CleanSpaceKit
//
//  预设多步 docker 执行时的线性进度与当前命令提示。
//

import SwiftUI

struct DockerPresetRunProgressBlock: View {
    /// 已完成的命令条数（0 … totalSteps）
    let completedSteps: Int
    let totalSteps: Int
    /// 当前正在执行（或即将执行）的 shell 一行
    let activeCommand: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if totalSteps > 0 {
                ProgressView(value: Double(completedSteps), total: Double(totalSteps))
                    .progressViewStyle(.linear)
            } else {
                ProgressView()
                    .progressViewStyle(.linear)
            }

            Text(L10n.Docker.progressCompleted(completedSteps, totalSteps))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !activeCommand.isEmpty {
                Text(activeCommand)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if totalSteps > 0, completedSteps < totalSteps {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text(L10n.Docker.progressWorking)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
