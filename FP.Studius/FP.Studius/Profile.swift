//
//  Profile.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI

// MARK: - Models & Sample Data
struct Course: Identifiable, Hashable {
    let id = UUID()
    let name: String
}

enum AssistantMode: String, CaseIterable, Identifiable {
    case staticQA = "Static"
    case gpt = "GPT"
    var id: String { rawValue }
}

struct StudyStats {
    var completedAssignments: Int
    var totalAssignments: Int
    var weeklyCompletion: [Int] // last 7 days
}

// MARK: - Profile View
struct ProfileView: View {
    // Profile
    @State private var userName: String = "Student Name"

    // Courses & Tips
    @State private var courses: [Course] = [
        Course(name: "Programming"),
        Course(name: "Formal methods"),
        Course(name: "Database system"),
        Course(name: "Computer Science")
    ]
    @State private var selectedCourse: Course? = nil

    private let courseTips: [String: [String]] = [
        "Programming": [
            "Practice daily with short problem sets.",
            "Focus on understanding proofs and derivations.",
            "Review errors and categorize common mistakes."
        ],
        "Formal methods": [
            "Use diagrams and flashcards for memorization.",
            "Relate concepts to real-world examples.",
            "Quiz yourself on terminology each session."
        ],
        "Database system": [
            "Create timelines to connect events.",
            "Compare primary sources for different perspectives.",
            "Summarize chapters in your own words."
        ],
        "Computer Science": [
            "Break problems into smaller functions.",
            "Write tests for tricky edge cases.",
            "Read others' code and refactor your own."
        ]
    ]

    // AI Assistant
    @State private var assistantMode: AssistantMode = .staticQA
    @State private var questionText: String = ""
    @State private var chat: [ProfileChatMessage] = []
    @State private var isThinking: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileSection
                    Divider()
                    aiAssistantSection
                }
                .padding()
            }
            .navigationTitle("Profile")
        }
        .onAppear {
            if selectedCourse == nil { selectedCourse = courses.first }
        }
    }

    // MARK: Sections
    private var profileSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.15))
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.blue)
                    .padding(8)
            }
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(userName)
                    .font(.title2).bold()
                Text("Lifelong learner")
                    .foregroundStyle(.secondary)
                if let selectedCourse {
                    Text("Focused on: \(selectedCourse.name)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Profile for \(userName)")
    }

    private var aiAssistantSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Study Assistant")
                .font(.title3).bold()

            // Course Picker
            HStack {
                Text("Course")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Course", selection: $selectedCourse) {
                    ForEach(courses) { course in
                        Text(course.name).tag(Optional(course))
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 220)
            }

            // Tips
            if let selectedCourse, let tips = courseTips[selectedCourse.name] {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips for \(selectedCourse.name)")
                        .font(.headline)
                    ForEach(tips, id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb")
                                .foregroundStyle(.yellow)
                            Text(tip)
                        }
                    }
                }
                .padding(12)
                .background(.yellow.opacity(0.1), in: .rect(cornerRadius: 12))
            }

            // Mode selector
            Picker("Mode", selection: $assistantMode) {
                ForEach(AssistantMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            // Q&A Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Ask a question")
                    .font(.headline)
                HStack(alignment: .bottom, spacing: 8) {
                    TextField("Type your question...", text: $questionText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...3)
                    Button(action: askQuestion) {
                        if isThinking {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isThinking)
                }
            }

            // Chat Transcript
            VStack(alignment: .leading, spacing: 12) {
                ForEach(chat) { message in
                    ProfileChatBubble(message: message)
                }
            }
        }
    }

    // MARK: - Actions
    @MainActor
    private func askQuestion() {
        let trimmed = questionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let userMsg = ProfileChatMessage(role: .user, text: trimmed)
        chat.append(userMsg)
        questionText = ""

        isThinking = true
        Task {
            let replyText: String
            switch assistantMode {
            case .staticQA:
                replyText = staticAnswer(for: trimmed)
            case .gpt:
                // Placeholder GPT integration. Replace `gptAnswer` with a real network call.
                replyText = await gptAnswerPlaceholder(for: trimmed)
            }
            let reply = ProfileChatMessage(role: .assistant, text: replyText)
            chat.append(reply)
            isThinking = false
        }
    }

    private func staticAnswer(for question: String) -> String {
        let lower = question.lowercased()
        if lower.contains("study plan") || lower.contains("how should i study") {
            return "Start with a 25/5 focus cycle: 25 minutes focused, 5 minutes rest. Review notes, then practice 3 problems."
        }
        if lower.contains("math") || lower.contains("algebra") || lower.contains("calculus") {
            return "For math, write out steps explicitly and check units. Practice similar problems with small variations."
        }
        if lower.contains("biology") || lower.contains("memorize") {
            return "Use spaced repetition and draw labeled diagrams to reinforce memory."
        }
        if lower.contains("history") || lower.contains("dates") {
            return "Build a timeline and connect causes to effects. Teach a friend the story in 3 minutes."
        }
        if lower.contains("computer") || lower.contains("code") || lower.contains("bug") {
            return "Rubber-duck your code: explain each line. Add print statements or use a debugger to isolate the issue."
        }
        return "Try to be specific about your goal. For example: 'How can I review Chapter 3 in 30 minutes?'"
    }

    private func gptAnswerPlaceholder(for question: String) async -> String {
        // Simulate latency and provide a placeholder response.
        try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s
        return "[GPT Placeholder] I'd approach: \(question). Consider breaking it down, outlining key steps, and reviewing fundamentals."
    }
}

// MARK: - Chat Models & Bubbles
struct ProfileChatMessage: Identifiable {
    enum Role { case user, assistant }
    let id = UUID()
    let role: Role
    let text: String
}

struct ProfileChatBubble: View {
    let message: ProfileChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant { Spacer(minLength: 24) }
            VStack(alignment: .leading, spacing: 6) {
                Text(message.text)
                    .padding(10)
                    .background(bubbleBackground, in: .rect(cornerRadius: 12))
            }
            if message.role == .user { Spacer(minLength: 24) }
        }
    }

    private var bubbleBackground: some ShapeStyle {
        message.role == .user ? AnyShapeStyle(.blue.opacity(0.15)) : AnyShapeStyle(.gray.opacity(0.12))
    }
}

// MARK: - Simple Bar Row
struct BarRow: View {
    let values: [Int]
    let maxValue: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(values.indices, id: \.self) { idx in
                let v = values[idx]
                RoundedRectangle(cornerRadius: 4)
                    .fill(v == 0 ? .gray.opacity(0.2) : .blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: max(CGFloat(v) / CGFloat(maxValue) * 70, 6))
                    .overlay(
                        Text(v > 0 ? "\(v)" : "")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(2), alignment: .bottom
                    )
                    .accessibilityLabel("Day \(idx + 1) completed \(v) assignments")
            }
        }
    }
}

#Preview {
    ProfileView()
}
