import SwiftUI
import KubebarCore

struct PodsTabView: View {
    let display: MenuDisplayModel
    let itemsMaxHeight: CGFloat
    @State private var podItemsContentHeight: CGFloat = 0

    init(display: MenuDisplayModel, itemsMaxHeight: CGFloat = Layout.defaultItemsMaxHeight) {
        self.display = display
        self.itemsMaxHeight = itemsMaxHeight
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
                PodNamespaceSectionView(section: section)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(section.namespace)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .help(Text(section.namespace))
                .accessibilityLabel(section.namespace)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(section.rows) { row in
                    PodRowView(row: row)
                }
            }
        }
    }
}

private struct PodRowView: View {
    let row: PodItemDisplay

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
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 7, height: 7)
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
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let issueText = row.issueText {
                    Text(issueText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help(Text(issueText))
                }
            }
        }
        .help(Text(row.helpText))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(row.accessibilityLabel)
        .focusable()
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
