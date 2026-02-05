//
//  Hub.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//
import SwiftUI



struct HubView: View {
    // MARK: - Personal Dashboard State
    @State private var stats = StudyStats(
        completedAssignments: 12,
        totalAssignments: 15,
        weeklyCompletion: [1, 2, 3, 2, 1, 2, 1]
    )

    private var completionRate: Double {
        guard stats.totalAssignments > 0 else { return 0 }
        return Double(stats.completedAssignments) / Double(stats.totalAssignments)
    }

    private var currentStreak: Int {
        var streak = 0
        for value in stats.weeklyCompletion.reversed() where value > 0 { streak += 1 }
        return streak
    }

    private func statCard(title: String, value: String, systemImage: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial, in: .rect(cornerRadius: 12))
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:   return "Good morning student"
        case 12..<17:  return "Good afternoon student"
        default:       return "Good evening student"
        }
    }
    
    private var formattedDate: String {
        Date.now.formatted(.dateTime.weekday(.wide).month(.wide).day())
    }
    
    // MARK: - Schedule Types
    struct ScheduleItem: Identifiable {
        let id = UUID()
        var course: String
        var start: Date
        var end: Date
        var day: Weekday
    }
    
    enum Weekday: String, CaseIterable, Identifiable {
        case sunday, monday, tuesday, wednesday, thursday, friday, saturday
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            }
        }
        static func today() -> Weekday {
            let idx = Calendar.current.component(.weekday, from: Date()) // 1 = Sunday ... 7 = Saturday
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
    
    // Deadline Types
    // Represents an upcoming deadline (e.g., an assignment or an exam) with a course and due date.
    struct DeadlineItem: Identifiable {
        let id = UUID() // Unique ID for SwiftUI lists
        var type: DeadlineType // Assignment or Exam
        var course: String // Course name the deadline belongs to
        var due: Date // Due date (and time, if relevant)
        var isCompleted: Bool = false // Whether the deadline has been completed
    }
    
    // The kind of deadline the user is adding.
    enum DeadlineType: String, CaseIterable, Identifiable {
        case assignment = "Assignment"
        case exam = "Exam"
        var id: String { rawValue }
    }
    
    // State
    @State private var scheduleItems: [ScheduleItem] = []
    @State private var showingAddSheet = false
    
    // All upcoming deadlines (not persisted yet).
    @State private var deadlines: [DeadlineItem] = []
    // Controls presentation of the add-deadline sheet.
    @State private var showingAddDeadlineSheet = false

    // Add-sheet form state
    @State private var courseName: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(60 * 60)
    @State private var selectedDay: Weekday = .monday

    // Add-deadline sheet form state
    @State private var deadlineType: DeadlineType = .assignment
    @State private var deadlineCourse: String = ""
    @State private var deadlineDueDate: Date = Date().addingTimeInterval(60 * 60 * 24)

    private var today: Weekday { Weekday.today() }
    private var todaysItems: [ScheduleItem] {
        scheduleItems
            .filter { $0.day == today }
            .sorted { $0.start < $1.start }
    }
    private var canSave: Bool {
        !courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && startTime < endTime
    }
    
    private var upcomingDeadlines: [DeadlineItem] {
        deadlines.sorted { $0.due < $1.due }
    }
    private var completedDeadlineCount: Int { deadlines.filter { $0.isCompleted }.count }
    private var totalDeadlineCount: Int { deadlines.count }
    
    private var canSaveDeadline: Bool {
        !deadlineCourse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private var progressFraction: Double {
        guard totalDeadlineCount > 0 else { return 0 }
        return Double(completedDeadlineCount) / Double(totalDeadlineCount)
    }
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Studius - Academic Hub")
                        .font(.title)
                        .bold()
                    Text("\(greeting) • \(formattedDate)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("\(greeting). \(formattedDate)")
                }
                Spacer()
                Image(systemName: "bell.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Notifications")
            }
            .padding()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Today's Schedule")
                        .font(.title3)
                        .bold()
                    Spacer()
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Add schedule item")
                }

                if todaysItems.isEmpty {
                    Text("No classes scheduled for today")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(todaysItems) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.course)
                                    .font(.headline)
                                Text("\(item.start.formatted(date: .omitted, time: .shortened)) - \(item.end.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .background(Color(red: 0.81, green: 0.76, blue: 0.67))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Upcoming Deadlines")
                        .font(.title3)
                        .bold()
                    Spacer()
                    Button {
                        showingAddDeadlineSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .accessibilityLabel("Add deadline")
                }

                if upcomingDeadlines.isEmpty {
                    Text("No upcoming deadlines")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(upcomingDeadlines.enumerated()), id: \.element.id) { index, item in
                        HStack(alignment: .top, spacing: 12) {
                            Button {
                                if let sourceIndex = deadlines.firstIndex(where: { $0.id == item.id }) {
                                    deadlines[sourceIndex].isCompleted.toggle()
                                }
                            } label: {
                                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isCompleted ? .green : .secondary)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(item.isCompleted ? "Mark as incomplete" : "Mark as complete")

                            Image(systemName: item.type == .assignment ? "doc.text.fill" : "graduationcap.fill")
                                .foregroundStyle(item.type == .assignment ? .blue : .orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(item.type.rawValue): \(item.course)")
                                    .font(.headline)
                                Text(item.due.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .opacity(item.isCompleted ? 0.5 : 1.0)
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
            .background(Color(red: 0.81, green: 0.76, blue: 0.67))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Courses & Progress")
                        .font(.title3)
                        .bold()
                    Spacer()
                    Text("\(completedDeadlineCount)/\(totalDeadlineCount)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: progressFraction)
                    .tint(.green)
                if totalDeadlineCount == 0 {
                    Text("Add deadlines to start tracking your progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text(String(format: "%.0f%% complete", progressFraction * 100))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(red: 0.81, green: 0.76, blue: 0.67))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            VStack(alignment: .leading, spacing: 12) {
                Text("Personal Dashboard")
                    .font(.title3)
                    .bold()

                HStack(spacing: 16) {
                    statCard(title: "Completed", value: "\(stats.completedAssignments)/\(stats.totalAssignments)", systemImage: "checkmark.circle.fill", color: .green)
                    statCard(title: "Completion", value: String(format: "%.0f%%", completionRate * 100), systemImage: "percent", color: .blue)
                    statCard(title: "Streak", value: "\(currentStreak)d", systemImage: "flame.fill", color: .orange)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last 7 days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    BarRow(values: stats.weeklyCompletion, maxValue: max(stats.weeklyCompletion.max() ?? 1, 1))
                        .frame(height: 80)
                        .padding(12)
                        .background(.gray.opacity(0.08), in: .rect(cornerRadius: 12))
                }
            }
            .padding()
            .background(Color(red: 0.81, green: 0.76, blue: 0.67))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        //.background(Color(red: 0.81, green: 0.76, blue: 0.67))
        //.ignoresSafeArea()
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Course")) {
                        TextField("Course name", text: $courseName)
                    }
                    Section(header: Text("Time")) {
                        DatePicker("Start", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("End", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                    Section(header: Text("Day")) {
                        Picker("Day", selection: $selectedDay) {
                            ForEach(Weekday.allCases) { day in
                                Text(day.displayName).tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .navigationTitle("Add Schedule")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newItem = ScheduleItem(course: courseName.trimmingCharacters(in: .whitespacesAndNewlines), start: startTime, end: endTime, day: selectedDay)
                            scheduleItems.append(newItem)
                            // Reset form
                            courseName = ""
                            startTime = Date()
                            endTime = Date().addingTimeInterval(60 * 60)
                            selectedDay = .monday
                            showingAddSheet = false
                        }
                        .disabled(!canSave)
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddDeadlineSheet) {
            NavigationStack {
                Form {
                    Section(header: Text("Type")) {
                        Picker("Type", selection: $deadlineType) {
                            ForEach(DeadlineType.allCases) { t in
                                Text(t.rawValue).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Section(header: Text("Course")) {
                        TextField("Course name", text: $deadlineCourse)
                    }
                    Section(header: Text("Due Date")) {
                        DatePicker("Due", selection: $deadlineDueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                .navigationTitle("Add Deadline")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingAddDeadlineSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            let newDeadline = DeadlineItem(type: deadlineType, course: deadlineCourse.trimmingCharacters(in: .whitespacesAndNewlines), due: deadlineDueDate)
                            deadlines.append(newDeadline)
                            // Reset form
                            deadlineType = .assignment
                            deadlineCourse = ""
                            deadlineDueDate = Date().addingTimeInterval(60 * 60 * 24)
                            showingAddDeadlineSheet = false
                        }
                        .disabled(!canSaveDeadline)
                    }
                }
            }
        }
    }
    
}

#Preview {
    HubView()
}

