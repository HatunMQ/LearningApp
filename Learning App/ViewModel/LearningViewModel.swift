import Foundation
import Combine

// ObservableObject: any change in `data` refreshes the views
class LearningViewModel: ObservableObject {
    @Published var data: LearningData { didSet { save() } }

    private static let key = "learningData_v2"
    private let notifications = NotificationManager.shared
    private let reminderIDs = ["streak-reminder-1", "streak-reminder-2"]
    private var canSave = true // Turned off for previews so sample data isn't saved
    private let cal: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 1 // Week starts on Sunday
        return c
    }()

    init() {
        if let saved = UserDefaults.standard.data(forKey: Self.key),
           let decoded = try? JSONDecoder().decode(LearningData.self, from: saved) {
            data = decoded
        } else {
            data = LearningData()
        }
        notifications.requestPermission()
    }

    // Used by previews only: shows sample data without saving it
    init(previewData: LearningData) {
        data = previewData
        canSave = false
    }

    // MARK: - Current goal
    var goal: Goal? { data.goals.last }
    var hasGoal: Bool { goal != nil }

    // Logs that belong to the current goal only
    var goalLogs: [DayLog] { data.logs.filter { $0.goalID == goal?.id } }

    var todayStatus: DayStatus? {
        goalLogs.first { cal.isDateInToday($0.date) }?.status
    }
    var isLoggedToday: Bool { todayStatus != nil }

    var frozenCount: Int { goalLogs.filter { $0.status == .frozen }.count }
    var freezeLimit: Int { goal?.duration.freezeLimit ?? 0 }
    var freezesLeft: Int { max(freezeLimit - frozenCount, 0) }
    var canFreeze: Bool { !isLoggedToday && !isGoalFinished && freezesLeft > 0 }

    var isGoalFinished: Bool {
        guard let goal else { return false }
        return Date() >= endDate(of: goal)
    }

    var isGoalMet: Bool {
        guard let goal else { return false }
        return isMet(goal)
    }

    func endDate(of goal: Goal) -> Date {
        cal.date(byAdding: .day, value: goal.duration.days, to: goal.startDate)!
    }

    // A goal is met when every day of it is logged (learned or frozen)
    func isMet(_ goal: Goal) -> Bool {
        data.logs.filter { $0.goalID == goal.id }.count >= goal.duration.days
    }

    // MARK: - Streak

    // The moment the streak is lost if nothing is logged:
    // 32 hours after the last log, or a full missed day — whichever comes first
    var streakDeadline: Date? {
        guard let goal, let last = goalLogs.max(by: { $0.date < $1.date }) else { return nil }
        let byHours = (last.loggedAt ?? last.date).addingTimeInterval(32 * 3600)
        let byDay = cal.date(byAdding: .day, value: 2, to: last.date)!
        let deadline = min(byHours, byDay)
        return deadline < endDate(of: goal) ? deadline : nil
    }

    // True when the deadline has passed without logging or freezing
    var isStreakLost: Bool {
        guard !isLoggedToday, !isGoalFinished, let deadline = streakDeadline else { return false }
        return Date() > deadline
    }

    // Walk back day by day counting learned days; stop at the first empty day
    var streak: Int {
        guard let goal else { return 0 }
        if isStreakLost { return 0 } // 32-hour rule

        let lastDay = cal.date(byAdding: .day, value: -1, to: endDate(of: goal))!
        var day = cal.startOfDay(for: min(Date(), lastDay))

        // Today isn't over yet, so if it's not logged start counting from yesterday
        if !isGoalFinished && !isLoggedToday {
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }

        var count = 0
        for _ in 0..<goal.duration.days {
            guard let log = goalLogs.first(where: { cal.isDate($0.date, inSameDayAs: day) }) else { break }
            if log.status == .learned { count += 1 } // A freeze keeps the streak but doesn't increase it
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    // MARK: - Actions
    func log(_ status: DayStatus) {
        guard let goal, !isLoggedToday, !isGoalFinished else { return }
        if status == .frozen && !canFreeze { return }

        data.logs.append(DayLog(date: cal.startOfDay(for: Date()), status: status,
                                goalID: goal.id, loggedAt: Date()))

        if status == .frozen { notifyFreezesLeft() }
        scheduleStreakReminders()
    }

    func setGoal(topic: String, duration: GoalDuration) {
        let today = cal.startOfDay(for: Date())
        notifications.cancel(ids: reminderIDs)

        // Same-day update: just edit the current goal
        if let index = data.goals.indices.last,
           cal.isDate(data.goals[index].startDate, inSameDayAs: today) {
            data.goals[index].topic = topic
            data.goals[index].duration = duration
            return
        }

        // Different day: start a new goal, old days stay in the calendar
        let oldID = goal?.id
        let newGoal = Goal(topic: topic, duration: duration, startDate: today)
        data.goals.append(newGoal)

        // Move today's log (if any) to the new goal so today isn't logged twice
        for i in data.logs.indices where data.logs[i].goalID == oldID && cal.isDateInToday(data.logs[i].date) {
            data.logs[i].goalID = newGoal.id
        }
    }

    // Refresh the UI (re-enables buttons after midnight, updates the streak)
    func refresh() { objectWillChange.send() }

    // MARK: - Notifications
    private func notifyFreezesLeft() {
        if freezesLeft == 0 {
            notifications.send(title: "No freezes left",
                               body: "You've used all \(freezeLimit) freezes. Keep learning every day!")
        } else {
            notifications.send(title: "Day freezed",
                               body: "You have \(freezesLeft) \(freezesLeft == 1 ? "freeze" : "freezes") left.")
        }
    }

    // Two reminders before the streak is lost: 8 hours and 2 hours before
    private func scheduleStreakReminders() {
        notifications.cancel(ids: reminderIDs)
        guard let deadline = streakDeadline else { return }

        notifications.send(title: "Keep your streak",
                           body: "Log a learning day or use a freeze before your streak is lost.",
                           id: reminderIDs[0], at: deadline.addingTimeInterval(-8 * 3600))
        notifications.send(title: "Last chance!",
                           body: "Your streak ends in 2 hours.",
                           id: reminderIDs[1], at: deadline.addingTimeInterval(-2 * 3600))
    }

    // MARK: - Calendar data
    func logs(on date: Date) -> [DayLog] {
        data.logs.filter { cal.isDate($0.date, inSameDayAs: date) }
    }

    func goal(for log: DayLog) -> Goal? {
        data.goals.first { $0.id == log.goalID }
    }

    func result(of goal: Goal) -> String {
        if goal.id == self.goal?.id && !isGoalFinished { return "In progress" }
        return isMet(goal) ? "Completed" : "Not completed"
    }

    // The 7 days of the current week
    var currentWeek: [Date] {
        let start = cal.dateInterval(of: .weekOfYear, for: Date())!.start
        var week: [Date] = []
        for i in 0..<7 {
            week.append(cal.date(byAdding: .day, value: i, to: start)!)
        }
        return week
    }

    // MARK: - Calendar years and months

    // All years from the first goal's year until this year
    var years: [Int] {
        let first = cal.component(.year, from: data.goals.first?.startDate ?? Date())
        let now = cal.component(.year, from: Date())
        return Array(first...now)
    }

    // The 12 months of a year
    func months(in year: Int) -> [Date] {
        let start = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        var result: [Date] = []
        for i in 0..<12 {
            result.append(cal.date(byAdding: .month, value: i, to: start)!)
        }
        return result
    }

    // First day of the current month (used to scroll the calendar to it)
    var currentMonth: Date {
        cal.dateInterval(of: .month, for: Date())!.start
    }

    // Days of a month, with empty slots so day 1 sits under the right weekday
    func days(in month: Date) -> [Date?] {
        var result: [Date?] = []
        let blanks = cal.component(.weekday, from: month) - 1
        for _ in 0..<blanks { result.append(nil) }

        let count = cal.range(of: .day, in: .month, for: month)!.count
        for i in 0..<count {
            result.append(cal.date(byAdding: .day, value: i, to: month))
        }
        return result
    }

    // MARK: - Formatting (always Gregorian, even if the device uses another calendar)
    private func format(_ date: Date, _ pattern: String) -> String {
        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    func monthTitle(_ month: Date) -> String { format(month, "MMMM") }
    func fullDate(_ date: Date) -> String { format(date, "EEEE, d MMMM yyyy") }
    var todayTitle: String { format(Date(), "EEEE, d MMMM") }
    func dayNumber(_ date: Date) -> String { String(cal.component(.day, from: date)) }

    // "1 day" instead of "1 days"
    func dayText(_ n: Int) -> String { n == 1 ? "1 day" : "\(n) days" }

    // MARK: - Persistence
    private func save() {
        guard canSave else { return }
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: Self.key)
        }
    }
}
