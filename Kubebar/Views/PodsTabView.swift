import SwiftUI
import KubebarCore

struct PodsTabView: View {
    let display: MenuDisplayModel
    let itemsMaxHeight: CGFloat
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: (OverviewK9sHandoff) -> Void
    let onOpenPodLogs: (PodLogTarget) -> Void
    @State private var podItemsContentHeight: CGFloat = 0

    init(
        display: MenuDisplayModel,
        itemsMaxHeight: CGFloat = Layout.defaultItemsMaxHeight,
        k9sHandoffState: K9sHandoffLaunchState,
        onOpenK9sHandoff: @escaping (OverviewK9sHandoff) -> Void,
        onOpenPodLogs: @escaping (PodLogTarget) -> Void = { _ in }
    ) {
        self.display = display
        self.itemsMaxHeight = itemsMaxHeight
        self.k9sHandoffState = k9sHandoffState
        self.onOpenK9sHandoff = onOpenK9sHandoff
        self.onOpenPodLogs = onOpenPodLogs
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            StaleBannerView(banner: display.staleBanner)
            podSummary
            podRows
        }
    }

    private var podSummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Pod readiness")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let unavailableMessage = display.podTab.unavailableMessage {
                readableText(unavailableMessage)
            } else {
                readableText(display.podTab.summary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(display.podTab.unavailableMessage ?? display.podTab.summary)
        .focusable()
    }

    @ViewBuilder
    private var podRows: some View {
        if display.podTab.unavailableMessage == nil {
            if display.podTab.sections.isEmpty {
                readableText(display.podTab.emptyMessage)
            } else {
                podItemsContainer
            }
        }
    }

    @ViewBuilder
    private var podItemsContainer: some View {
        let maxHeight = max(Layout.minimumItemsHeight, itemsMaxHeight)

        if podItemsContentHeight > maxHeight {
            ScrollView(.vertical) {
                podItemsContent
            }
            .scrollIndicators(.visible, axes: .vertical)
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .frame(height: maxHeight, alignment: .top)
        } else {
            podItemsContent
        }
    }

    private var podItemsContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(display.podTab.sections) { section in
                PodNamespaceSectionView(
                    section: section,
                    k9sHandoffState: k9sHandoffState,
                    onOpenK9sHandoff: onOpenK9sHandoff,
                    onOpenPodLogs: onOpenPodLogs
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .onPodItemsMeasuredHeight { height in
            guard height > 0, abs(podItemsContentHeight - height) > Layout.heightTolerance else {
                return
            }

            podItemsContentHeight = height
        }
    }

    private func readableText(_ value: String) -> some View {
        Text(value)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .truncationMode(.middle)
            .help(Text(value))
            .accessibilityLabel(value)
    }

    private enum Layout {
        static let defaultItemsMaxHeight: CGFloat = 450
        static let minimumItemsHeight: CGFloat = 160
        static let heightTolerance: CGFloat = 1
    }
}

private struct PodNamespaceSectionView: View {
    let section: PodNamespaceDisplay
    let k9sHandoffState: K9sHandoffLaunchState
    let onOpenK9sHandoff: (OverviewK9sHandoff) -> Void
    let onOpenPodLogs: (PodLogTarget) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Label(section.namespace, systemImage: "folder.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(section.namespace))
                    .accessibilityLabel(section.namespace)

                Spacer(minLength: 8)

                if let handoff = section.k9sHandoff {
                    openK9sButton(for: handoff)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 6)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))

            if let feedbackMessage {
                Text(feedbackMessage)
                    .font(.caption)
                    .foregroundStyle(feedbackColor)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(Text(feedbackMessage))
            }

            VStack(alignment: .leading, spacing: 6) {
                ForEach(section.rows) { row in
                    PodRowView(row: row, onOpenPodLogs: onOpenPodLogs)
                }
            }
        }
    }

    private func openK9sButton(for handoff: OverviewK9sHandoff) -> some View {
        Button {
            onOpenK9sHandoff(handoff)
        } label: {
            Image(systemName: "arrow.right")
                .font(.caption)
        }
        .buttonStyle(.borderless)
        .controlSize(.small)
        .help(Text(handoff.helpText))
        .accessibilityLabel(handoff.accessibilityLabel)
        .accessibilityHint(Text(handoff.buttonLabel(for: k9sHandoffState)))
        .disabled(k9sHandoffState.blocksNewHandoff(for: handoff))
    }

    private var feedbackMessage: String? {
        section.k9sHandoff.flatMap(k9sHandoffState.feedbackMessage)
    }

    private var feedbackColor: Color {
        if case .failed = k9sHandoffState {
            return .red
        }

        return .secondary
    }
}

private struct PodRowView: View {
    let row: PodItemDisplay
    let onOpenPodLogs: (PodLogTarget) -> Void
    @State private var isPulsing = false

    private var shouldPulse: Bool {
        row.state == .watch
    }

    private var statusColor: Color {
        switch row.state {
        case .ready:
            return .green
        case .watch:
            return .yellow
        case .bad:
            return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 7, height: 7)
                    .opacity(shouldPulse && isPulsing ? 0.4 : 1.0)
                    .animation(shouldPulse ? Animation.easeInOut(duration: 0.8).repeatForever() : .default, value: isPulsing)
                    .onAppear {
                        updatePulse()
                    }
                    .onChange(of: shouldPulse) { _, _ in
                        updatePulse()
                    }
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(row.name)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(Text(row.name))

                        Spacer(minLength: 8)

                        Text(row.readyLabel)
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.primary.opacity(0.7))
                            .lineLimit(1)

                        if let logTarget = row.logTarget {
                            Button {
                                onOpenPodLogs(logTarget)
                            } label: {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.caption)
                            }
                            .buttonStyle(.borderless)
                            .controlSize(.small)
                            .help(Text("Open recent logs for \(row.name)"))
                            .accessibilityLabel("Open recent logs for \(row.name)")
                        }
                    }

                    if let issueText = row.issueText {
                        Text(issueText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .help(Text(issueText))
                    }

                    if !row.resourceLabel.isEmpty {
                        HStack(spacing: 4) {
                            Text(row.resourceLabel)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                                .help(Text(row.resourceLabel))

                            ResourceProgressPair(
                                cpuProgress: row.cpuProgress,
                                memoryProgress: row.memoryProgress
                            )
                            .padding(.leading, 2)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.accessibilityLabel)
                .focusable()

            }
        }
        .help(Text(row.helpText))
        .accessibilityElement(children: .contain)
    }

    private func updatePulse() {
        isPulsing = shouldPulse
    }

}

private struct ResourceProgressPair: View {
    let cpuProgress: Double?
    let memoryProgress: Double?

    var body: some View {
        HStack(spacing: 3) {
            if let cpuProgress {
                resourceProgress(systemImage: "cpu", progress: cpuProgress)
            }

            if let memoryProgress {
                resourceProgress(systemImage: "memorychip", progress: memoryProgress)
            }
        }
        .accessibilityHidden(true)
    }

    private func resourceProgress(systemImage: String, progress: Double) -> some View {
        HStack(spacing: 2) {
            Image(systemName: systemImage)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(width: 9)

            InlineProgressBar(progress: progress)
                .frame(width: 24)
        }
    }
}

private struct PodItemsHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let nextHeight = nextValue()
        if nextHeight > 0 {
            value = nextHeight
        }
    }
}

private extension View {
    func onPodItemsMeasuredHeight(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        background {
            GeometryReader { proxy in
                Color.clear.preference(
                    key: PodItemsHeightPreferenceKey.self,
                    value: ceil(proxy.size.height)
                )
            }
        }
        .onPreferenceChange(PodItemsHeightPreferenceKey.self, perform: onChange)
    }
}
