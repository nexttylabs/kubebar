import Testing
@testable import KubebarCore

@Suite("AI diagnostic response formatter")
struct AIDiagnosticResponseFormatterTests {
    @Test("strips a complete think block and keeps the answer")
    func stripsCompleteThinkBlock() {
        let raw = """
        <think>
        I should analyze the pod state. CrashLoopBackOff means the container keeps restarting.
        </think>

        ## 🔍 **Possible causes**
        - OOMKilled: exit code 137 hints at memory limits.
        """
        let cleaned = AIDiagnosticResponseFormatter.cleanedMarkdown(from: raw)

        #expect(!cleaned.contains("<think>"))
        #expect(!cleaned.contains("I should analyze"))
        #expect(!cleaned.contains("CrashLoopBackOff means"))
        #expect(cleaned.contains("## 🔍 **Possible causes**"))
        #expect(cleaned.contains("- OOMKilled"))
    }

    @Test("strips an unclosed think block, dropping the trailing content")
    func stripsUnclosedThinkBlock() {
        let raw = "<think> reasoning that never closes, plus an unfinished answer"
        let cleaned = AIDiagnosticResponseFormatter.cleanedMarkdown(from: raw)

        #expect(cleaned.isEmpty)
    }

    @Test("strips multiple think blocks between sections")
    func stripsMultipleThinkBlocks() {
        let raw = """
        <think>step one</think>
        ## 🔍 **Possible causes**
        - image pull backoff
        <think>step two</think>
        ## 🛠️ **Actionable fixes**
        ```bash
        kubectl describe pod checkout-7f9d -n api
        ```
        """
        let cleaned = AIDiagnosticResponseFormatter.cleanedMarkdown(from: raw)

        #expect(!cleaned.contains("step one"))
        #expect(!cleaned.contains("step two"))
        #expect(cleaned.contains("## 🔍 **Possible causes**"))
        #expect(cleaned.contains("## 🛠️ **Actionable fixes**"))
        #expect(cleaned.contains("kubectl describe pod checkout-7f9d -n api"))
    }

    @Test("strips leading chatter before the first heading")
    func stripsLeadingPreamble() {
        let raw = """
        Sure, here is a diagnosis.

        ## 🔍 **Possible causes**
        - cause
        """
        let cleaned = AIDiagnosticResponseFormatter.cleanedMarkdown(from: raw)

        #expect(!cleaned.contains("Sure, here is a diagnosis"))
        #expect(cleaned.hasPrefix("## 🔍"))
    }

    @Test("keeps a short freeform answer that has no heading")
    func keepsFreeformAnswerWithoutHeading() {
        let raw = "The pod is crashing because of an OOMKilled event."
        let cleaned = AIDiagnosticResponseFormatter.cleanedMarkdown(from: raw)

        #expect(cleaned == raw)
    }

    @Test("collapses runs of repeated blank lines")
    func collapsesRepeatedBlankLines() {
        let raw = "## 🔍 **Possible causes**\n\n\n\n- cause\n\n\n## 🛠️ **Actionable fixes**\n- fix"
        let cleaned = AIDiagnosticResponseFormatter.cleanedMarkdown(from: raw)

        #expect(!cleaned.contains("\n\n\n"))
        #expect(cleaned.contains("## 🔍 **Possible causes**"))
        #expect(cleaned.contains("## 🛠️ **Actionable fixes**"))
    }

    @Test("empty input returns empty")
    func emptyInputReturnsEmpty() {
        #expect(AIDiagnosticResponseFormatter.cleanedMarkdown(from: "").isEmpty)
        #expect(AIDiagnosticResponseFormatter.cleanedMarkdown(from: "   \n  \n").isEmpty)
    }
}
