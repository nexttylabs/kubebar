import Foundation

public struct WarningEventDiagnosticTarget: Equatable, Sendable, Identifiable {
    public let contextName: String
    public let namespace: String?
    public let objectKind: String
    public let objectName: String
    public let reason: String

    public var id: String {
        [contextName, namespace ?? "-", objectKind, objectName, reason]
            .joined(separator: "|")
    }

    public init(
        contextName: String,
        namespace: String?,
        objectKind: String,
        objectName: String,
        reason: String
    ) {
        self.contextName = contextName
        self.namespace = namespace
        self.objectKind = objectKind
        self.objectName = objectName
        self.reason = reason
    }

    public static func make(
        contextName: String,
        namespace: String?,
        objectKind: String?,
        objectName: String?,
        reason: String
    ) -> WarningEventDiagnosticTarget? {
        guard let objectKind = normalized(objectKind), let objectName = normalized(objectName) else {
            return nil
        }

        let reason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !reason.isEmpty else {
            return nil
        }

        return WarningEventDiagnosticTarget(
            contextName: contextName,
            namespace: normalized(namespace),
            objectKind: objectKind,
            objectName: objectName,
            reason: reason
        )
    }

    public func matches(_ event: WarningEventRecord) -> Bool {
        event.reason == reason &&
            normalized(event.namespace) == namespace &&
            normalized(event.objectKind) == objectKind &&
            normalized(event.objectName) == objectName
    }

    private static func normalized(_ value: String?) -> String? {
        let text = value?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let text, !text.isEmpty else {
            return nil
        }
        return text
    }

    private func normalized(_ value: String?) -> String? {
        Self.normalized(value)
    }
}

public struct AIEventDiagnosticEvent: Equatable, Sendable {
    public let reason: String
    public let namespace: String?
    public let objectKind: String?
    public let objectName: String?
    public let message: String?
    public let observedAt: String?
    public let count: Int

    public init(
        reason: String,
        namespace: String?,
        objectKind: String?,
        objectName: String?,
        message: String?,
        observedAt: String?,
        count: Int
    ) {
        self.reason = reason
        self.namespace = namespace
        self.objectKind = objectKind
        self.objectName = objectName
        self.message = message
        self.observedAt = observedAt
        self.count = count
    }

    public init(record: WarningEventRecord) {
        self.init(
            reason: record.reason,
            namespace: record.namespace,
            objectKind: record.objectKind,
            objectName: record.objectName,
            message: record.message,
            observedAt: record.observedAt.map(Self.isoString),
            count: max(1, record.count)
        )
    }

    private static func isoString(from date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }
}

public struct AIEventDiagnosticContext: Equatable, Sendable {
    public let target: WarningEventDiagnosticTarget
    public let events: [AIEventDiagnosticEvent]
    public let isStale: Bool

    public init(target: WarningEventDiagnosticTarget, events: [AIEventDiagnosticEvent], isStale: Bool = false) {
        self.target = target
        self.events = events
        self.isStale = isStale
    }
}

public typealias AIEventDiagnosticResult = AIPodDiagnosticResult
public typealias AIEventDiagnosisState = AIPodDiagnosisState
