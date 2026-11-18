import SwiftUI

// Decides which screen to show: Onboarding or Activity
struct ContentView: View {
    @EnvironmentObject var vm: LearningViewModel

    var body: some View {
        if vm.hasGoal { ActivityView() } else { OnboardingView() }
    }
}

#Preview {
    ContentView().environmentObject(LearningViewModel())
}
