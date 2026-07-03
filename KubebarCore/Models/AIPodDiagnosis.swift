import Foundation

public struct AIPodStatusContext: Equatable, Sendable {
    public let state: String
    public let ready: String
    public let reason: String?
    public let detail: String?

    public init(state: String, ready: String, reason: String? = nil, detail: String? = nil) {
        self.state = state
        self.ready = ready
        self.reason = reason
        self.detail = detail
    }
}

public struct AIPodWarningContext: Equatable, Sendable {
    public let reason: String
    public let location: String
    public let age: String
    public let message: String?

    public init(reason: String, location: String, age: String, message: String? = nil) {
        self.reason = reason
        self.location = location
        self.age = age
        self.message = message
    }
}

public struct AIPodDiagnosticContext: Equatable, Sendable {
    public let target: PodLogTarget
    public let podStatus: AIPodStatusContext
    public let warnings: [AIPodWarningContext]
    public let logLines: [String]
    public let isStale: Bool

    public init(
        target: PodLogTarget,
        podStatus: AIPodStatusContext,
        warnings: [AIPodWarningContext] = [],
        logLines: [String] = [],
        isStale: Bool = false
    ) {
        self.target = target
        self.podStatus = podStatus
        self.warnings = warnings
        self.logLines = logLines
        self.isStale = isStale
    }
}

public enum AIPodDiagnosticResult: Equatable, Sendable {
    case success(markdown: String)
    case failed(String)
}

public enum AIPodDiagnosisState: Equatable, Sendable {
    case idle
    case loading
    case success(markdown: String)
    case failed(String)

    public var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }
}
