import Foundation

public enum WorkloadKind: String, Codable, CaseIterable, Equatable, Hashable, Sendable {
    case deployment
    case statefulSet
    case daemonSet
    case cronJob

    public var displayName: String {
        switch self {
        case .deployment:
            "Deployment"
        case .statefulSet:
            "StatefulSet"
        case .daemonSet:
            "DaemonSet"
        case .cronJob:
            "CronJob"
        }
    }

    public var kubectlResource: String {
        switch self {
        case .deployment:
            "deployments"
        case .statefulSet:
            "statefulsets"
        case .daemonSet:
            "daemonsets"
        case .cronJob:
            "cronjobs"
        }
    }
}
