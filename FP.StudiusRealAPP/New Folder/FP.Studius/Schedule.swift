//
//  Schedule.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI

// Local helpers for display — extends AppDataStore.DeadlineType with icon and color
private extension AppDataStore.DeadlineType {
    var symbol: String { self == .assignment ? "doc.text.fill" : "graduationcap.fill" }
    var color: Color { self == .assignment ? .blue : .orange }
}

struct ScheduleView: View {
    @Environment(AppDataStore.self) private var store
    private let background = Color(red: 0.81, green: 0.76, blue: 0.67)
    private let cardBackground = Color(red: 0.94, green: 0.88, blue: 0.80)
    private let darkCard = Color(red: 0.36, green: 0.28, blue: 0.20)

    // Calendar State
    @State private var selectedDate: Date = Date()
    @State private var showingAddDeadlineSheet = false

    // Add-deadline form state
    @State private var deadlineType: AppDataStore.DeadlineType = .assignment
    @State private var deadlineCourse: String = ""
    @State private var deadlineDueDate: Date = Date().addingTimeInterval(60 * 60 * 24)

    //  Derived
    private var upcomingDeadlines: [AppDataStore.DeadlineItem] {
        store.deadlines
            .filter { $0.due >= Date() }
            .sorted { $0.due < $1.due }
    }

    private var formattedSelectedHeader: String {
        selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }
    
    private var selectedWeekday: AppDataStore.Weekday {
        let weekdayNumber = Calendar.current.component(.weekday, from: selectedDate)
        
        switch weekdayNumber {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        default: return .saturday
        }
    }
    
    private var selectedDayScheduleItems: [AppDataStore.ScheduleItem] {
        store.scheduleItems
            .filter { $0.day == selectedWeekday }
            .sorted { $0.start < $1.start }
    }
    
    private var completedDeadlines: Int {
        store.deadlines.filter { $0.isCompleted }.count
    }
    
    private var openDeadlines: Int {
        upcomingDeadlines.filter { !$0.isCompleted }.count
    }

    private var canSaveDeadline: Bool {
        !deadlineCourse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    headerCard

                    // Calendar
                    DatePicker("", selection: $selectedDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .padding(12)
                        .background(cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)

                    selectedDayCard

                    // Upcoming deadlines — shared from AppDataStore
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label("Upcoming Deadlines", systemImage: "clock.badge.exclamationmark.fill")
                                .font(.title3).bold()
                                .foregroundStyle(.white)
                            Spacer()
                            Button {
                                showingAddDeadlineSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.white)
                            }
                            .accessibilityLabel("Add deadline")
                        }

                        if upcomingDeadlines.isEmpty {
                            emptyState(
                                title: "No upcoming deadlines",
                                subtitle: "Add your next assignment or exam so Studius can keep it visible."
                            )
                        } else {
                            ForEach(upcomingDeadlines.prefix(6)) { item in
                                deadlineRow(item)
                            }
                        }
                    }
                    .padding()
                    .background(darkCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                }
                .padding()
            }
            .background(background.ignoresSafeArea())
            .navigationTitle("Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .tint(darkCard)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddDeadlineSheet = true
                    } label: {
                        Label("Add Deadline", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDeadlineSheet) {
                NavigationStack {
                    Form {
                        Section(header: Text("Type")) {
                            Picker("Type", selection: $deadlineType) {
                                ForEach(AppDataStore.DeadlineType.allCases) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        Section(header: Text("Course")) {
                            TextField("Course name", text: $deadlineCourse)
                        }
                        Section(header: Text("Due")) {
                            DatePicker("Due Date & Time", selection: $deadlineDueDate, displayedComponents: [.date, .hourAndMinute])
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(background.ignoresSafeArea())
                    .navigationTitle("Add Deadline")
                    .tint(darkCard)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddDeadlineSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                store.addDeadline(
                                    course: deadlineCourse.trimmingCharacters(in: .whitespacesAndNewlines),
                                    type: deadlineType,
                                    due: deadlineDueDate
                                )
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
    
    //  Header
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Plan Your Week")
                        .font(.title)
                        .bold()
                        .foregroundStyle(.white)
                    Text(formattedSelectedHeader)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.78))
                        .accessibilityLabel(formattedSelectedHeader)
                }
                Spacer()
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 42))
                    .foregroundStyle(.white)
            }
            
            HStack(spacing: 10) {
                scheduleStat(title: "Classes", value: "\(selectedDayScheduleItems.count)", systemImage: "book.closed.fill", color: .blue)
                scheduleStat(title: "Open", value: "\(openDeadlines)", systemImage: "exclamationmark.circle.fill", color: .orange)
                scheduleStat(title: "Done", value: "\(completedDeadlines)", systemImage: "checkmark.circle.fill", color: .green)
            }
        }
        .padding()
        .background(darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
    }
    
    private var selectedDayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(selectedWeekday.displayName)'s Classes", systemImage: "backpack.fill")
                    .font(.title3)
                    .bold()
                Spacer()
                Text("\(selectedDayScheduleItems.count)")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(darkCard, in: Capsule())
            }
            
            if selectedDayScheduleItems.isEmpty {
                emptyState(
                    title: "No classes saved for this day",
                    subtitle: "Add classes from the Hub and they will appear here."
                )
            } else {
                ForEach(selectedDayScheduleItems) { item in
                    classRow(item)
                }
            }
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }

    // Row View
    @ViewBuilder
    private func deadlineRow(_ item: AppDataStore.DeadlineItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                store.toggleDeadline(id: item.id)
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isCompleted ? .green : .white.opacity(0.75))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "Mark as incomplete" : "Mark as complete")

            ZStack {
                Circle()
                    .fill(item.type.color.opacity(0.22))
                    .frame(width: 38, height: 38)
                Image(systemName: item.type.symbol)
                    .foregroundStyle(item.type.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.course)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(item.due.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.72))
            }
            Spacer()
            
            Text(dueBadgeText(for: item.due))
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.white.opacity(0.14), in: Capsule())
        }
        .opacity(item.isCompleted ? 0.5 : 1)
        .padding(10)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func classRow(_ item: AppDataStore.ScheduleItem) -> some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(darkCard)
                .frame(width: 5)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.course)
                    .font(.headline)
                Text("\(item.start.formatted(date: .omitted, time: .shortened)) - \(item.end.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func scheduleStat(title: String, value: String, systemImage: String, color: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.72))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func emptyState(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    private func dueBadgeText(for date: Date) -> String {
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let startOfDueDate = Calendar.current.startOfDay(for: date)
        let dayCount = Calendar.current.dateComponents([.day], from: startOfToday, to: startOfDueDate).day ?? 0
        
        if dayCount == 0 {
            return "Today"
        } else if dayCount == 1 {
            return "Tomorrow"
        } else {
            return "\(dayCount)d"
        }
    }
}

#Preview {
    ScheduleView()
        .environment(AppDataStore())
}
