import SwiftUI

// Task 1: Start learning
struct OnboardingView: View {
    @EnvironmentObject var vm: LearningViewModel
    @State private var topic = ""
    @State private var duration = GoalDuration.week

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: "flame.fill")
                .font(.system(size: 40))
                .foregroundStyle(Color.learnOrange)
                .frame(maxWidth: .infinity)
                .padding(.top, 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("Hello Learner").font(.largeTitle.bold())
                Text("This app will help you learn everyday!").foregroundStyle(.secondary)
            }

            GoalForm(topic: $topic, duration: $duration) // Passed as Binding

            Spacer()

            VStack(spacing: 8) {
                Button("Start Learning") { vm.setGoal(topic: topic, duration: duration) }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(topic.isEmpty)
                Text("You can edit your desire later").font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
    }
}

#Preview {
    OnboardingView().environmentObject(LearningViewModel())
}
