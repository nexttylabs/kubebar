import AppKit
import SwiftUI

struct ReadOnlyLogTextView: NSViewRepresentable {
    let text: String
    let placeholder: String
    let isPlaceholder: Bool

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true
        scrollView.backgroundColor = .textBackgroundColor
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = false
        textView.usesFindPanel = true
        textView.textContainerInset = NSSize(width: 10, height: 10)
        textView.font = .monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        textView.textColor = .textColor
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.heightTracksTextView = false
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.minSize = .zero
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.autoresizingMask = [.height]

        scrollView.documentView = textView
        context.coordinator.textView = textView
        context.coordinator.apply(text: displayedText, isPlaceholder: isPlaceholder)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.apply(text: displayedText, isPlaceholder: isPlaceholder)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    private var displayedText: String {
        text.isEmpty ? placeholder : text
    }
}

extension ReadOnlyLogTextView {
    final class Coordinator {
        weak var textView: NSTextView?
        private var lastText: String?
        private var lastIsPlaceholder: Bool?
        private let bottomFollowThreshold: CGFloat = 24

        @MainActor
        func apply(text: String, isPlaceholder: Bool) {
            guard lastText != text || lastIsPlaceholder != isPlaceholder else {
                return
            }

            let isInitialUpdate = lastText == nil
            lastText = text
            lastIsPlaceholder = isPlaceholder

            guard let textView else {
                return
            }

            let updateState = UpdateState(textView: textView, bottomFollowThreshold: bottomFollowThreshold)

            textView.string = text
            textView.textColor = isPlaceholder ? .secondaryLabelColor : .textColor
            restoreViewState(updateState, in: textView, isInitialUpdate: isInitialUpdate)
        }

        @MainActor
        private func restoreViewState(_ state: UpdateState, in textView: NSTextView, isInitialUpdate: Bool) {
            let clampedRanges = state.selectedRanges.compactMap { range -> NSValue? in
                guard range.location <= textView.string.utf16.count else {
                    return nil
                }

                let maxLength = textView.string.utf16.count - range.location
                return NSValue(range: NSRange(location: range.location, length: min(range.length, maxLength)))
            }

            if !clampedRanges.isEmpty {
                textView.selectedRanges = clampedRanges
            }

            guard let scrollView = textView.enclosingScrollView else {
                return
            }

            if isInitialUpdate || !state.shouldFollowTail {
                scrollView.contentView.scroll(to: state.visibleOrigin)
                scrollView.reflectScrolledClipView(scrollView.contentView)
                return
            }

            textView.scrollRangeToVisible(NSRange(location: textView.string.utf16.count, length: 0))
        }
    }

    private struct UpdateState {
        let selectedRanges: [NSRange]
        let visibleOrigin: NSPoint
        let shouldFollowTail: Bool

        @MainActor
        init(textView: NSTextView, bottomFollowThreshold: CGFloat) {
            selectedRanges = textView.selectedRanges.map(\.rangeValue)

            guard let scrollView = textView.enclosingScrollView else {
                visibleOrigin = .zero
                shouldFollowTail = false
                return
            }

            let visibleRect = scrollView.contentView.documentVisibleRect
            visibleOrigin = visibleRect.origin

            let documentHeight = max(textView.bounds.height, visibleRect.height)
            let isNearBottom = visibleRect.maxY >= documentHeight - bottomFollowThreshold
            let hasNonEmptySelection = selectedRanges.contains { $0.length > 0 }
            shouldFollowTail = isNearBottom && !hasNonEmptySelection
        }
    }
}
