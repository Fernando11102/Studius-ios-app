//
//  Schedule.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI

struct ScheduleView: View {
    // MARK: - Calendar State
    @State private var selectedDate: Date = Date()

    // MARK: - Deadline Types (kept local to avoid cross-file dependencies)
    struct DeadlineItem: Identifiable {
        let id = UUID()
        var type: DeadlineType
        var course: String
        var due: Date
        var isCompleted: Bool = false
    }

    enum DeadlineType: String, CaseIterable, Identifiable {
        case assignment = "Assignment"
        case exam = "Exam"
        var id: String { rawValue }
        var symbol: String { self == .assignment ? "doc.text.fill" : "graduationcap.fill" }
        var color: Color { self == .assignment ? .blue : .orange }
    }

    // MARK: - Deadlines State
    @State private var deadlines: [DeadlineItem] = []
    @State private var showingAddDeadlineSheet = false

    // Add-deadline sheet form state
    @State private var deadlineType: DeadlineType = .assignment
    @State private var deadlineCourse: String = ""
    @State private var deadlineDueDate: Date = Date().addingTimeInterval(60 * 60 * 24)

    // MARK: - Derived Collections
    private var upcomingDeadlines: [DeadlineItem] {
        deadlines
            .filter { $0.due >= Date() }
            .sorted { $0.due < $1.due }
    }

    private var formattedSelectedHeader: String {
        selectedDate.formatted(.dateTime.weekday(.wide).month(.wide).day().year())
    }

    private var canSaveDeadline: Bool {
        !deadlineCourse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Selected date header
                    Text(formattedSelectedHeader)
                        .font(.title2).bold()
                        .padding(.top, 8)
                        .accessibilityLabel(formattedSelectedHeader)

                    // Centered Calendar
                    HStack { Spacer() }
                    DatePicker(
                        "",
                        selection: $selectedDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    HStack { Spacer() }

                    // Upcoming deadlines (next ones regardless of selected day)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Upcoming Deadlines")
                                .font(.title3).bold()
                            Spacer()
                            Button {
                                showingAddDeadlineSheet = true
                            } label: {
                                Image(systemName: "plus.circle.fill").font(.title3)
                            }
                            .accessibilityLabel("Add deadline")
                        }

                        if upcomingDeadlines.isEmpty {
                            Text("No upcoming deadlines")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(upcomingDeadlines) { item in
                                deadlineRow(item)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding()
            }
            .navigationTitle("Schedule")
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
                                ForEach(DeadlineType.allCases) { t in
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
                    .navigationTitle("Add Deadline")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") { showingAddDeadlineSheet = false }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                let new = DeadlineItem(
                                    type: deadlineType,
                                    course: deadlineCourse.trimmingCharacters(in: .whitespacesAndNewlines),
                                    due: deadlineDueDate
                                )
                                deadlines.append(new)
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

    // MARK: - Row View
    @ViewBuilder
    private func deadlineRow(_ item: DeadlineItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                if let idx = deadlines.firstIndex(where: { $0.id == item.id }) {
                    deadlines[idx].isCompleted.toggle()
                }
            } label: {
                Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "Mark as incomplete" : "Mark as complete")

            Image(systemName: item.type.symbol)
                .foregroundStyle(item.type.color)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(item.type.rawValue): \(item.course)")
                    .font(.headline)
                Text(item.due.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .opacity(item.isCompleted ? 0.5 : 1)
        .padding(.vertical, 4)
    }
}

#Preview {
    ScheduleView()
}
