import SwiftUI

// Goal form, reused in Onboarding and LearningGoal via @Binding
struct GoalForm: View {
    @Binding var topic: String
    @Binding var duration: GoalDuration

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("I want to learn")
            TextField("Swift", text: $topic)
            Divider()
            Text("I want to learn it in a").padding(.top)
            HStack {
                ForEach(GoalDuration.allCases, id: \.self) { item in
                    Button(item.rawValue) { duration = item }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .tint(duration == item ? Color.learnOrange : Color.gray.opacity(0.3))
                }
            }
        }
    }
}

// Current week strip (S M T W T F S)
struct WeekStrip: View {
    @EnvironmentObject var vm: LearningViewModel

    var body: some View {
        HStack {
            ForEach(vm.currentWeek, id: \.self) { day in
                VStack(spacing: 6) {
                    Text(day.formatted(.dateTime.weekday(.narrow)))
                        .font(.caption).foregroundStyle(.secondary)
                    DayCircle(date: day)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// Logged day: shaded circle (shade depends on goal duration)
// Today: solid orange if not logged, or a ring if logged
// Empty day: plain number
struct DayCircle: View {
    @EnvironmentObject var vm: LearningViewModel
    @Environment(\.colorScheme) private var scheme
    let date: Date
    var size: CGFloat = 42

    var body: some View {
        let log = vm.logs(on: date).last
        let isToday = Calendar.current.isDateInToday(date)
        let isFrozen = log?.status == .frozen
        let base: Color = isFrozen ? .freezeBlue : .learnOrange
        let light: Color = isFrozen ? .freezeBlueLight : .learnOrangeLight
        let shade = log.flatMap { vm.goal(for: $0)?.duration.shade } ?? 0

        // Strong background -> black/white text; light background -> colored text
        let loggedText: Color = shade >= 0.3 ? .primary : (scheme == .dark ? light : base)

        Text(vm.dayNumber(date))
            .fontWeight(isToday ? .bold : .medium)
            .foregroundStyle(log != nil ? loggedText : (isToday ? Color.white : Color.primary))
            .frame(width: size, height: size)
            .background(Circle().fill(log != nil ? base.opacity(shade) : (isToday ? Color.learnOrange : Color.clear)))
            .overlay(Circle().stroke(base, lineWidth: 2).opacity(isToday && log != nil ? 1 : 0))
    }
}

// Streak / Freeze card
struct StatCard: View {
    let icon: String
    let color: Color
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).bold()
            Text(label).font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(RoundedRectangle(cornerRadius: 24).stroke(.gray.opacity(0.4)))
    }
}

// Custom alert that matches the design (system alerts can't change button colors)
struct UpdateGoalAlert: View {
    let onDismiss: () -> Void
    let onUpdate: () -> Void

    var body: some View {
        ZStack {
            // Dimmed background, tap outside to dismiss
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            VStack(alignment: .leading, spacing: 8) {
                Text("Update goal").font(.headline)
                Text("If you update now, your streak will start over.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.gray.opacity(0.3)))
                    }

                    Button(action: onUpdate) {
                        Text("Update")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Capsule().fill(Color.learnOrange))
                    }
                }
                .buttonStyle(.plain)
                .font(.body.weight(.medium))
                .padding(.top, 12)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 28).fill(.regularMaterial))
            .padding(.horizontal, 40)
        }
    }
}
