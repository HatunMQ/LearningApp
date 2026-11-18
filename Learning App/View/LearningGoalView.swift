import SwiftUI

// Task 4: Change learning goal
struct LearningGoalView: View {
    @EnvironmentObject var vm: LearningViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var topic = ""
    @State private var duration = GoalDuration.week
    @State private var showAlert = false

    var body: some View {
        GoalForm(topic: $topic, duration: $duration)
            .padding()
            .frame(maxHeight: .infinity, alignment: .top)
            .navigationTitle("Learning Goal")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(showAlert) // Hide back while the alert is open
            .toolbar {
                Button { showAlert = true } label: { Image(systemName: "checkmark") }
                    .tint(.learnOrange)
                    .disabled(topic.isEmpty || showAlert)
            }
            .overlay {
                if showAlert {
                    UpdateGoalAlert(
                        onDismiss: { showAlert = false },
                        onUpdate: {
                            showAlert = false
                            vm.setGoal(topic: topic, duration: duration)
                            dismiss()
                        }
                    )
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showAlert)
            .onAppear {
                // Pre-fill with the current goal
                topic = vm.goal?.topic ?? ""
                duration = vm.goal?.duration ?? .week
            }
    }
}

#Preview {
    NavigationStack { LearningGoalView() }
        .environmentObject(LearningViewModel())
}
