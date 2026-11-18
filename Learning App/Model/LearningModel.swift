import Foundation

// Goal duration and its rules
enum GoalDuration: String, Codable, CaseIterable {
    case week = "Week", month = "Month", year = "Year"

    // Number of days in the goal
    var days: Int {
        switch self { case .week: 7; case .month: 30; case .year: 365 }
    }

    // Max freezes allowed for this duration
    var freezeLimit: Int {
        switch self { case .week: 2; case .month: 8; case .year: 96 }
    }

    // Background shade in the calendar: Week = light, Month = medium, Year = deep
    var shade: Double {
        switch self { case .week: 0.15; case .month: 0.35; case .year: 0.6 }
    }
}

// Status of a logged day
enum DayStatus: String, Codable {
    case learned, frozen
}

// A learning goal (all goals are kept)
struct Goal: Identifiable, Codable {
    var id = UUID()
    var topic: String
    var duration: GoalDuration
    var startDate: Date
}

// A logged day linked to its goal
struct DayLog: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var status: DayStatus
    var goalID: UUID
    var loggedAt: Date? = nil // Exact time of logging (used for the 32-hour rule)
}

// All app data
struct LearningData: Codable {
    var goals: [Goal] = []   // Last one is the current goal
    var logs: [DayLog] = []  // Every logged day (used by the calendar)
}
