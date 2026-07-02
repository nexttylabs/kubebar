import Foundation

/// Cleans raw AI provider responses before they reach the UI.
///
/// Some OpenAI-compatible reasoning models (DeepSeek-R1, Qwen-QwQ, GLM-Zero,
/// and similar) emit an intermediate reasoning trace wrapped in `<think>…</think>`
/// blocks before the final answer. Other models leave trailing prose before the
/// first Markdown heading. This formatter strips both so the diagnosis panel
/// shows only the structured answer, never the model's internal monologue.
public enum AIDiagnosticResponseFormatter {
    /// Returns a compact Markdown string with reasoning blocks and leading
    /// chatter removed. Empty input yields an empty string.
    public static func cleanedMarkdown(from raw: String) -> String {
        let withoutThink = stripThinkBlocks(from: raw)
        let trimmedPreamble = stripLeadingPreamble(from: withoutThink)
        return collapseBlankLines(trimmedPreamble)
    }

    /// Removes every complete `<think>…</think>` block and, if a block is never
    /// closed, drops everything from the opening tag to the end of the response.
    static func stripThinkBlocks(from raw: String) -> String {
        var remaining = raw
        var output = ""

        while let openRange = remaining.range(of: "<think>", options: [.caseInsensitive]) {
            output += remaining[remaining.startIndex..<openRange.lowerBound]

            let afterOpen = openRange.upperBound
            if let closeRange = remaining.range(of: "</think>", options: [.caseInsensitive], range: afterOpen..<remaining.endIndex) {
                remaining = String(remaining[closeRange.upperBound...])
            } else {
                // Unmatched opening tag: drop the rest of the response.
                remaining = ""
            }
        }

        output += remaining
        return output
    }

    /// Drops any non-heading lines that appear before the first Markdown heading
    /// (a line starting with `#`). If no heading exists, the text is kept as-is
    /// so short freeform answers still render.
    static func stripLeadingPreamble(from raw: String) -> String {
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: false)
        var firstHeading = lines.count

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                firstHeading = index
                break
            }
        }

        guard firstHeading < lines.count else {
            return raw
        }

        return lines[firstHeading...].joined(separator: "\n")
    }

    /// Collapses runs of two or more blank lines into a single blank line and
    /// trims leading/trailing whitespace from the whole string.
    static func collapseBlankLines(_ raw: String) -> String {
        let lines = raw.split(separator: "\n", omittingEmptySubsequences: false)
        var result: [String] = []
        var previousBlank = false

        for line in lines {
            let isBlank = line.trimmingCharacters(in: .whitespaces).isEmpty

            if isBlank {
                if previousBlank {
                    continue
                }
                previousBlank = true
            } else {
                previousBlank = false
            }

            result.append(String(line))
        }

        while result.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            result.removeLast()
        }

        while result.first?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            result.removeFirst()
        }

        return result.joined(separator: "\n")
    }
}
