import SwiftUI
import KubebarCore

struct SettingsRootView: View {
    @Binding var state: SetupFlowState
    let isEditingExistingConfig: Bool
    let onPrepare: () -> Void
    let onComplete: () -> Void
    let onSelectContext: (String?) -> Void
    let onRetryTargets: () -> Void

    var body: some View {
        SetupView(
            state: $state,
            primaryActionTitle: state.primaryActionTitle(isEditingExistingConfig: isEditingExistingConfig),
            onComplete: onComplete,
            onSelectContext: onSelectContext,
            onRetryTargets: onRetryTargets
        )
        .frame(width: 560, height: 560, alignment: .topLeading)
        .onAppear(perform: onPrepare)
    }
}
