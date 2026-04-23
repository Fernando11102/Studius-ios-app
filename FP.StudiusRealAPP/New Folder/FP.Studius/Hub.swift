//
//  Hub.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//
import SwiftUI


// The hub dashboard view
struct HubView: View {
    @Environment(AppDataStore.self) private var store

    private var weeklyDeadlineCompletion: [Int] {
        let calendar = Calendar.current
        let completedDays = store.deadlines
            .filter { $0.isCompleted }
            .compactMap { $0.completedAt }

        return (0..<7).map { index in
            let dayOffset = index - 6
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else {
                return 0
            }
            return completedDays.filter {
                calendar.isDate($0, inSameDayAs: day)
            }.count
        }
    }
        //streak validation
    private var currentDeadlineStreak: Int {
        let calendar = Calendar.current
        let completedDays = Set(
            store.deadlines
                .filter { $0.isCompleted }
                .compactMap { $0.completedAt }
                .map { calendar.startOfDay(for: $0)}
            )
        var streak = 0
        var day = calendar.startOfDay(for: Date())
        while completedDays.contains(day) {
            streak += 1
            day = calendar.date(byAdding:.day, value: -1, to: day )!
        }
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
    
    //State
    @State private var showingAddSheet = false
    @State private var showingAddDeadlineSheet = false
    // This controls the logo assistant sheet that opens from the Hub page.
    @State private var showingAssistant = false

    // Dynamic container expansion state
    @State private var isScheduleExpanded: Bool = true
    @State private var isDeadlinesExpanded: Bool = true
    @State private var isProgressExpanded: Bool = true

    // Schedule form
    @State private var courseName: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date().addingTimeInterval(60 * 60)
    @State private var selectedDay: AppDataStore.Weekday = .monday

    // Deadline form
    @State private var deadlineType: AppDataStore.DeadlineType = .assignment
    @State private var deadlineCourse: String = ""
    @State private var deadlineDueDate: Date = Date().addingTimeInterval(60 * 60 * 24)

    private var canSave: Bool {
        !courseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && startTime < endTime
    }
    private var canSaveDeadline: Bool {
        !deadlineCourse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    
    var body: some View {
        ScrollView {
        VStack(spacing: 12) {
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
                Button {
                    // Tapping the logo opens the assistant, which can add classes, deadlines and map requests.
                    showingAssistant = true
                } label: {
                    VStack(spacing: 8) {
                        HStack {
                            Spacer()
                            WavingLogoView()
                            Spacer()
                        }
                        DynamicLogoMessageView()
                    }
                    .padding()
                    .background(Color(red: 0.81, green: 0.76, blue: 0.67))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            .background(Color(red: 0.81, green: 0.76, blue: 0.67))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            
            HubCard(title: "Today's Schedule", systemImage: "calendar", isExpanded: $isScheduleExpanded) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Add schedule item")
            } content: {
                if store.todaysScheduleItems.isEmpty {
                    Text("No classes scheduled for today")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(store.todaysScheduleItems) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.course)
                                    .font(.headline)
                                Text("\(item.start.formatted(date: .omitted, time: .shortened)) - \(item.end.formatted(date: .omitted, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                            Spacer()

                            Button(role: .destructive) {
                                store.deleteScheduleItem(id: item.id)
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete \(item.course)")
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            HubCard(title: "Upcoming Deadlines", systemImage: "clock.badge.checkmark", isExpanded: $isDeadlinesExpanded) {
                Button {
                    showingAddDeadlineSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                }
                .accessibilityLabel("Add deadline")
            } content: {
                if store.upcomingDeadlines.isEmpty {
                    Text("No upcoming deadlines")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(Array(store.upcomingDeadlines.enumerated()), id: \.element.id) { index, item in
                        HStack(alignment: .top, spacing: 12) {
                            Button {
                                store.toggleDeadline(id: item.id)
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
                                    .foregroundStyle(.white)
                            }
                            Spacer()

                            Button(role: .destructive) {
                                store.deleteDeadline(id: item.id)
                            } label: {
                                Image(systemName: "trash.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Delete \(item.course) deadline")
                        }
                        .opacity(item.isCompleted ? 0.5 : 1.0)
                        .padding(.vertical, 4)
                    }
                }
            }
            
            HubCard(title: "Courses & Progress", systemImage: "chart.bar.fill", isExpanded: $isProgressExpanded) {
                EmptyView()
            } content: {
                HStack {
                    Text("Courses & Progress")
                        .font(.title3)
                        .bold()
                    Spacer()
                    Text("\(store.completedDeadlineCount)/\(store.deadlines.count)")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                ProgressView(value: store.progressFraction)
                    .tint(.green)
                if store.deadlines.isEmpty {
                    Text("Add deadlines to start tracking your progress")
                        .font(.caption)
                        .foregroundStyle(.white)
                } else {
                    Text(String(format: "%.0f%% complete", store.progressFraction * 100))
                        .font(.caption)
                        .foregroundStyle(.white)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Personal Dashboard")
                    .font(.title3)
                    .bold()

                HStack(spacing: 16) {
                    statCard(title: "Completed", value: "\(store.completedDeadlineCount)/\(store.deadlines.count)", systemImage: "checkmark.circle.fill", color: .green)
                    statCard(title: "Completion", value: String(format: "%.0f%%", store.progressFraction * 100), systemImage: "percent", color: .blue)
                    statCard(title: "Streak", value: "\(currentDeadlineStreak)d", systemImage: "flame.fill", color: .orange)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last 7 days")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    BarRow(values: weeklyDeadlineCompletion, maxValue: max(weeklyDeadlineCompletion.max() ?? 1, 1))
                        .frame(height: 80)
                        .padding(12)
                        .background(.gray.opacity(0.08), in: .rect(cornerRadius: 12))
                }
            }
            .padding()
            .background(Color(red: 0.81, green: 0.76, blue: 0.67))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.81, green: 0.76, blue: 0.67).ignoresSafeArea())
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
                            ForEach(AppDataStore.Weekday.allCases) { day in
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
                            store.addScheduleItem(course: courseName.trimmingCharacters(in: .whitespacesAndNewlines), day: selectedDay, start: startTime, end: endTime)
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
                            ForEach(AppDataStore.DeadlineType.allCases) { t in
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
                            store.addDeadline(course: deadlineCourse.trimmingCharacters(in: .whitespacesAndNewlines), type: deadlineType, due: deadlineDueDate)
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
        .sheet(isPresented: $showingAssistant) {
            StudyAssistantView()
                .environment(store)
                .presentationDetents([.height(700), .large])
                .presentationDragIndicator(.visible)
        }
       
    }
    
}

private struct HubCard<HeaderTrailing: View, Content: View>: View {
    let title: String
    let systemImage: String
    @Binding var isExpanded: Bool
    @ViewBuilder var trailing: () -> HeaderTrailing
    @ViewBuilder var content: () -> Content

    private let cardBackground = Color(red: 0.36, green: 0.28, blue: 0.20)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: systemImage)
                        .foregroundStyle(.white)
                    Text(title)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(.white)
                }
                Spacer()
                trailing()
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.9)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .foregroundStyle(.white)
                }
                .accessibilityLabel(isExpanded ? "Collapse" : "Expand")
            }
            .tint(.white)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
                .foregroundStyle(.white)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
    }
}

#Preview {
    HubView()
        .environment(AppDataStore())
}
