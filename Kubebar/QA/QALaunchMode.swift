import Foundation
import KubebarCore

#if DEBUG
enum QALaunchMode {
    static func fixture(
        arguments: [String] = ProcessInfo.processInfo.arguments,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) -> MenuStateFixture? {
        if let argumentValue = qaStateArgumentValue(in: arguments) {
            return MenuStateFixtureCatalog.fixture(named: argumentValue)
        }

        guard let environmentValue = environment["KUBEBAR_QA_STATE"] else {
            return nil
        }

        return MenuStateFixtureCatalog.fixture(named: environmentValue)
    }

    private static func qaStateArgumentValue(in arguments: [String]) -> String? {
        guard let optionIndex = arguments.firstIndex(of: "--kubebar-qa-state") else {
            return nil
        }

        let valueIndex = arguments.index(after: optionIndex)
        guard valueIndex < arguments.endIndex else {
            return nil
        }

        return arguments[valueIndex]
    }
}
#endif
