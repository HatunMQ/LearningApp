import SwiftUI
import Combine

// Task 2 + Task 3
struct ActivityView: View {
    @EnvironmentObject var vm: LearningViewModel
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                header
                WeekStrip()
                HStack {
                    StatCard(icon: "flame.fill", color: .learnOrange, value: vm.dayText(vm.streak), label: "Learned")
                    StatCard(icon: "snowflake", color: .freezeBlueLight, value: vm.dayText(vm.frozenCount), label: "Freezed")
                }
                if vm.isGoalFinished { GoalFinishedView() } else { logButtons }
                Spacer()
            }
            .padding()
            .toolbar(.hidden, for: .navigationBar)
            .onReceive(timer) { _ in vm.refresh() }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Activity").font(.largeTitle.bold())
                Text(vm.todayTitle)
                    .font(.subheadline).foregroundStyle(.secondary)
                if let goal = vm.goal {
                    Text("Learning \(goal.topic) · \(goal.duration.rawValue)")
                        .font(.caption).foregroundStyle(Color.learnOrange)
                }
            }
            Spacer()
            // .plain keeps the icons in the text color instead of the accent color
            NavigationLink { CalendarView() } label: { icon("calendar") }
                .buttonStyle(.plain)
            NavigationLink { LearningGoalView() } label: { icon("pencil.and.outline") }
                .buttonStyle(.plain)
        }
    }

    // MARK: - Log buttons
    // Only the button that was used turns gray; the other keeps its color.
    // allowsHitTesting blocks taps without changing the colors (unlike .disabled).
    private var logButtons: some View {
        VStack(spacing: 24) {
            Button { vm.log(.learned) } label: {
                Text(isLearnedToday ? "Logged as Learned" : "Log as Learned")
                    .font(.title2.bold())
                    .foregroundStyle(isLearnedToday ? Color.secondary : Color.white)
                    .frame(width: 260, height: 260)
                    .background(Circle().fill(isLearnedToday ? Color.gray.opacity(0.2) : Color.learnOrange))
            }
            .buttonStyle(.plain)
            .allowsHitTesting(!vm.isLoggedToday)

            VStack(spacing: 8) {
                Button { vm.log(.frozen) } label: {
                    Text(isFreezeActive ? "Freeze for a day" : "Freezed for a day")
                        .font(.body.weight(.medium))
                        .foregroundStyle(isFreezeActive ? Color.white : Color.secondary)
                        .frame(width: 260)
                        .padding(.vertical, 14)
                        .background(Capsule().fill(isFreezeActive ? Color.freezeBlue : Color.gray.opacity(0.2)))
                }
                .buttonStyle(.plain)
                .allowsHitTesting(vm.canFreeze)

                Text("\(vm.frozenCount) out of \(vm.freezeLimit) Freezes used")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.top)
    }

    // Today was logged as learned
    private var isLearnedToday: Bool { vm.todayStatus == .learned }

    // Freeze keeps its blue color unless today was freezed or no freezes are left
    private var isFreezeActive: Bool { vm.todayStatus != .frozen && vm.freezesLeft > 0 }

    private func icon(_ name: String) -> some View {
        Image(systemName: name)
            .foregroundStyle(.primary)
            .padding(10)
            .background(Circle().fill(.gray.opacity(0.25)))
    }
}

// Shown when the goal duration ends, including which goal was finished
struct GoalFinishedView: View {
    @EnvironmentObject var vm: LearningViewModel

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: vm.isGoalMet ? "hands.clap.fill" : "xmark.seal")
                .font(.system(size: 44)).foregroundStyle(Color.learnOrange)
            if let goal = vm.goal {
                Text("\(goal.topic) · \(goal.duration.rawValue)")
                    .font(.headline).foregroundStyle(Color.learnOrange)
            }
            Text(vm.isGoalMet ? "Well done!" : "You didn't reach your goal this time.").bold()
            Text(vm.isGoalMet ? "Ready for your next goal?" : "Want to set another goal?")
                .font(.subheadline).foregroundStyle(.secondary)
            NavigationLink { LearningGoalView() } label: {
                Label("Set a goal", systemImage: "pencil.and.outline")
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.learnOrange)
            .padding(.top)
        }
        .padding(.top, 60)
    }
}

// Sample data for previews
extension LearningData {
    // A week goal that started today
    static var newWeek: LearningData {
        let goal = Goal(topic: "Swift", duration: .week, startDate: Calendar.current.startOfDay(for: Date()))
        return LearningData(goals: [goal], logs: [])
    }

    // A week goal that started today and today is already logged
    static func loggedToday(_ status: DayStatus) -> LearningData {
        var data = newWeek
        let today = Calendar.current.startOfDay(for: Date())
        data.logs.append(DayLog(date: today, status: status, goalID: data.goals[0].id, loggedAt: Date()))
        return data
    }

    // A week goal that already ended
    static func finishedWeek(completed: Bool) -> LearningData {
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -7, to: cal.startOfDay(for: Date()))!
        let goal = Goal(topic: "Swift", duration: .week, startDate: start)
        var data = LearningData(goals: [goal], logs: [])

        // Completed: all 7 days logged. Not completed: only 4 days logged
        let loggedDays = completed ? 7 : 4
        for i in 0..<loggedDays {
            let day = cal.date(byAdding: .day, value: i, to: start)!
            let status: DayStatus = i >= loggedDays - 2 ? .frozen : .learned
            data.logs.append(DayLog(date: day, status: status, goalID: goal.id))
        }
        return data
    }
}

#Preview("Activity") {
    ActivityView()
        .environmentObject(LearningViewModel(previewData: .newWeek))
}

#Preview("Learned today") {
    ActivityView()
        .environmentObject(LearningViewModel(previewData: .loggedToday(.learned)))
}

#Preview("Freezed today") {
    ActivityView()
        .environmentObject(LearningViewModel(previewData: .loggedToday(.frozen)))
}

#Preview("Goal completed") {
    ActivityView()
        .environmentObject(LearningViewModel(previewData: .finishedWeek(completed: true)))
}

#Preview("Goal not met") {
    ActivityView()
        .environmentObject(LearningViewModel(previewData: .finishedWeek(completed: false)))
}
