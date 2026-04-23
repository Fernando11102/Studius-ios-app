//  AppDataStore.swift
//  FP.Studius

import SwiftUI


// This class is the single source of truth for the whole app.
// Both Hub and STUDIUS read and write from here.
@Observable
class AppDataStore {

    enum MainTab: Hashable {
        case hub
        case schedule
        case social
        case map
        case profile
    }

    // MARK: - Deadline Types
    enum DeadlineType: String, CaseIterable, Identifiable {
        case assignment = "Assignment"
        case exam = "Exam"
        var id: String { rawValue }
    }

    struct DeadlineItem: Identifiable {
        let id = UUID()
        var type: DeadlineType
        var course: String
        var due: Date
        var isCompleted: Bool = false
        var completedAt: Date? = nil
    }

    // MARK: - Schedule Types
    enum Weekday: String, CaseIterable, Identifiable {
        case sunday, monday, tuesday, wednesday, thursday, friday, saturday
        var id: String { rawValue }
        var displayName: String { rawValue.capitalized }

        static func today() -> Weekday {
            let idx = Calendar.current.component(.weekday, from: Date())
            switch idx {
            case 1: return .sunday
            case 2: return .monday
            case 3: return .tuesday
            case 4: return .wednesday
            case 5: return .thursday
            case 6: return .friday
            default: return .saturday
            }
        }
    }

    struct ScheduleItem: Identifiable {
        let id = UUID()
        var course: String
        var start: Date
        var end: Date
        var day: Weekday
    }

    // MARK: - Stored Data
    // These arrays are kept here so Hub, Schedule and the assistant all see the same data.
    var deadlines: [DeadlineItem] = []
    var scheduleItems: [ScheduleItem] = []
    var selectedTab: MainTab = .hub
    var selectedMapSpotID = "cafeteria"

    // MARK: - Methods
    // The assistant and manual forms both call these methods, so there is one place that updates the app data.
    func addDeadline(course: String, type: DeadlineType, due: Date) {
        deadlines.append(DeadlineItem(type: type, course: course, due: due))
    }

    func addScheduleItem(course: String, day: Weekday, start: Date, end: Date) {
        scheduleItems.append(ScheduleItem(course: course, start: start, end: end, day: day))
    }

    func deleteDeadline(id: UUID) {
        deadlines.removeAll { $0.id == id }
    }

    func deleteScheduleItem(id: UUID) {
        scheduleItems.removeAll { $0.id == id }
    }

    // Marking a deadline complete also stores the date, which is used for the weekly progress chart.
    func toggleDeadline(id: UUID) {
        guard let index = deadlines.firstIndex(where: { $0.id == id }) else { return }
        let wasCompleted = deadlines[index].isCompleted
        deadlines[index].isCompleted = !wasCompleted
        deadlines[index].completedAt = wasCompleted ? nil : Date()
    }

    // MARK: - Computed Helpers
    var todaysScheduleItems: [ScheduleItem] {
        scheduleItems.filter { $0.day == Weekday.today() }.sorted { $0.start < $1.start }
    }

    var upcomingDeadlines: [DeadlineItem] {
        deadlines.sorted { $0.due < $1.due }
    }

    var completedDeadlineCount: Int {
        deadlines.filter { $0.isCompleted }.count
    }

    var progressFraction: Double {
        guard !deadlines.isEmpty else { return 0 }
        return Double(completedDeadlineCount) / Double(deadlines.count)
    }
}








































