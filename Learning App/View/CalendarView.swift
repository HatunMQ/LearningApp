import SwiftUI

// Task 5: All previous days grouped by year, tap a day to see its goal
struct CalendarView: View {
    @EnvironmentObject var vm: LearningViewModel
    @State private var selected: Date?
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    legend

                    // Year header stays pinned at the top while scrolling
                    LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                        ForEach(vm.years, id: \.self) { year in
                            Section {
                                ForEach(vm.months(in: year), id: \.self) { month in
                                    monthView(month)
                                        .id(month) // Used to scroll to this month
                                }
                            } header: {
                                yearHeader(year)
                            }
                        }
                    }
                }
                .padding()
            }
            .onAppear {
                // Jump to the current month when the calendar opens
                proxy.scrollTo(vm.currentMonth, anchor: .center)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let selected { DayDetail(date: selected) }
        }
        .navigationTitle("Activities")
        .navigationBarTitleDisplayMode(.inline)
    }

    // Big year title (e.g. 2026)
    private func yearHeader(_ year: Int) -> some View {
        Text(String(year))
            .font(.largeTitle.bold())
            .foregroundStyle(Color.learnOrange)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .background(.background)
    }

    // One month: title + weekday names + days grid
    private func monthView(_ month: Date) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(vm.monthTitle(month)).font(.title3.bold())
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(weekdays, id: \.self) {
                    Text($0).font(.caption2).foregroundStyle(.secondary)
                }
                ForEach(Array(vm.days(in: month).enumerated()), id: \.offset) { _, day in
                    if let day {
                        Button { selected = day } label: {
                            DayCircle(date: day, size: 36)
                                .overlay(Circle().stroke(Color.primary, lineWidth: 2)
                                    .opacity(isSelected(day) ? 1 : 0))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Color.clear
                    }
                }
            }
            Divider()
        }
    }

    private func isSelected(_ day: Date) -> Bool {
        guard let selected else { return false }
        return Calendar.current.isDate(selected, inSameDayAs: day)
    }

    // Color legend: each duration has its own shade of the same color
    private var legend: some View {
        HStack(spacing: 16) {
            ForEach(GoalDuration.allCases, id: \.self) { item in
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.learnOrange.opacity(item.shade))
                        .frame(width: 14, height: 14)
                    Text(item.rawValue).font(.caption)
                }
            }
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.freezeBlue.opacity(0.35))
                    .frame(width: 14, height: 14)
                Text("Freezed").font(.caption)
            }
        }
    }
}

// Card shown at the bottom when a day is tapped
struct DayDetail: View {
    @EnvironmentObject var vm: LearningViewModel
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(vm.fullDate(date)).bold()
            let logs = vm.logs(on: date)
            if logs.isEmpty {
                Text("Nothing logged this day").foregroundStyle(.secondary)
            }
            ForEach(logs) { log in
                if let goal = vm.goal(for: log) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(goal.topic) · \(goal.duration.rawValue) goal")
                        Text("\(log.status == .learned ? "Learned" : "Freezed") · \(vm.result(of: goal))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        .padding()
    }
}

#Preview {
    NavigationStack { CalendarView() }
        .environmentObject(LearningViewModel())
}
