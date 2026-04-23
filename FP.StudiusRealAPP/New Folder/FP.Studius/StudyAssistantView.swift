//
//  StudyAssistantView.swift
//  FP.Studius
//

import SwiftUI
import Foundation

private enum AssistantUI {
    static let title = "Assistant"
    static let placeholder = "Message"
    static let background = Color(red: 0.81, green: 0.76, blue: 0.67)
    static let card = Color(red: 0.94, green: 0.88, blue: 0.80)
    static let darkCard = Color(red: 0.36, green: 0.28, blue: 0.20)
}

private struct AssistantMessage: Identifiable {
    enum Sender: Equatable {
        case user
        case assistant

        var geminiRole: String {
            switch self {
            case .user: return "user"
            case .assistant: return "model"
            }
        }
    }

    let id = UUID()
    let sender: Sender
    let text: String
}

struct StudyAssistantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppDataStore.self) private var store
    @FocusState private var isInputFocused: Bool

    @State private var messages: [AssistantMessage] = []
    @State private var inputText = ""
    @State private var isSending = false

    private let quickPrompts = [
        "Add database assignment due tomorrow",
        "Add iOS lab on Monday from 10 to 12",
        "What deadlines do I have?",
        "Where is the library?"
    ]

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isSending
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            messageList
            quickPromptBar
            inputBar
        }
        .background(AssistantUI.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack(spacing: 12) {
            BlueBotGraduationLogoView()
                .frame(width: 44, height: 44)
                .padding(6)
                .background(Color.white.opacity(0.16), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(AssistantUI.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.14), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close assistant")
        }
        .padding()
        .background(AssistantUI.darkCard)
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(messages) { message in
                        messageBubble(message)
                            .id(message.id)
                    }

                    if isSending {
                        typingBubble
                            .id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                scrollToBottom(proxy)
            }
            .onChange(of: isSending) { _, sending in
                if sending {
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField(AssistantUI.placeholder, text: $inputText, axis: .vertical)
                .focused($isInputFocused)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Color.white.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .onSubmit(sendMessage)

            Button {
                sendMessage()
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(canSend ? AssistantUI.darkCard : Color.gray.opacity(0.42), in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(16)
        .background(AssistantUI.card)
    }

    private var quickPromptBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(quickPrompts, id: \.self) { prompt in
                    Button {
                        inputText = prompt
                        isInputFocused = true
                    } label: {
                        Text(prompt)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AssistantUI.darkCard)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(Color.white.opacity(0.58), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(AssistantUI.background)
    }

    private func messageBubble(_ message: AssistantMessage) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.sender == .user {
                Spacer(minLength: 42)
            } else {
                assistantAvatar
            }

            Text(message.text)
                .font(.body)
                .foregroundStyle(message.sender == .user ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(message.sender == .user ? AssistantUI.darkCard : Color.white.opacity(0.74))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .fixedSize(horizontal: false, vertical: true)

            if message.sender == .assistant {
                Spacer(minLength: 42)
            }
        }
    }

    private var typingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            assistantAvatar

            HStack(spacing: 8) {
                ProgressView()
                    .controlSize(.small)
                Text("Thinking")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.white.opacity(0.74))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Spacer(minLength: 42)
        }
    }

    private var assistantAvatar: some View {
        Image(systemName: "sparkles")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(AssistantUI.darkCard, in: Circle())
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else {
            return
        }

        messages.append(AssistantMessage(sender: .user, text: text))
        inputText = ""
        isSending = true

        Task { @MainActor in
            let reply = await makeReply(to: text)
            messages.append(AssistantMessage(sender: .assistant, text: reply))
            isSending = false
        }
    }

    private func makeReply(to text: String) async -> String {
        // App actions are checked before Gemini so commands like adding classes work even without internet.
        if let appReply = handleAppAction(text) {
            return appReply
        }

        let chat = messages.suffix(10).map {
            GeminiChatTurn(role: $0.sender.geminiRole, text: $0.text)
        }

        do {
            return try await GeminiAssistantClient().reply(for: Array(chat), appContext: appContext)
        } catch {
            return "I could not reach the online assistant right now."
        }
    }

    private func handleAppAction(_ text: String) -> String? {
        let lower = text.lowercased()

        // The assistant can control simple app navigation as well as answering questions.
        if lower.contains("library") {
            store.selectedMapSpotID = "library"
            store.selectedTab = AppDataStore.MainTab.map
            return "I selected the Library in the Map tab. It is on the 3rd floor in Cavendish Campus."
        }

        if isDeadlineSummaryRequest(lower) {
            return deadlineSummary()
        }

        if isScheduleSummaryRequest(lower) {
            return scheduleSummary()
        }

        if isAddDeadlineRequest(lower) {
            return addDeadline(from: text)
        }

        if isAddScheduleRequest(lower) {
            return addScheduleItem(from: text)
        }

        return nil
    }

    private func isDeadlineSummaryRequest(_ lower: String) -> Bool {
        (lower.contains("deadline") || lower.contains("due")) &&
        (lower.contains("what") || lower.contains("show") || lower.contains("list") || lower.contains("have"))
    }

    private func isScheduleSummaryRequest(_ lower: String) -> Bool {
        (lower.contains("schedule") || lower.contains("class") || lower.contains("lecture") || lower.contains("lab")) &&
        (lower.contains("today") || lower.contains("what") || lower.contains("show") || lower.contains("list"))
    }

    private func isAddDeadlineRequest(_ lower: String) -> Bool {
        let hasDeadlineWord = lower.contains("deadline") ||
            lower.contains("assignment") ||
            lower.contains("exam") ||
            lower.contains("coursework") ||
            lower.contains("due")
        let hasActionWord = lower.contains("add") ||
            lower.contains("create") ||
            lower.contains("set") ||
            lower.contains("remind")
        let hasDateWord = lower.contains("today") ||
            lower.contains("tomorrow") ||
            lower.contains("next week") ||
            weekday(from: lower) != nil
        
        return hasDeadlineWord && (hasActionWord || hasDateWord)
    }

    private func isAddScheduleRequest(_ lower: String) -> Bool {
        let hasClassWord = lower.contains("class") ||
            lower.contains("lecture") ||
            lower.contains("lab") ||
            lower.contains("seminar")
        let hasActionWord = lower.contains("add") ||
            lower.contains("create") ||
            lower.contains("schedule") ||
            lower.contains("set")
        let hasDayAndTime = weekday(from: lower) != nil && hourRange(from: lower) != nil
        
        return hasClassWord && (hasActionWord || hasDayAndTime)
    }

    private func addDeadline(from text: String) -> String {
        guard let course = courseName(from: text) else {
            return "Tell me the module and due date, like: add database assignment due tomorrow."
        }

        guard let dueDate = dueDate(from: text) else {
            return "I can add \(course), but I need the due date."
        }

        let type: AppDataStore.DeadlineType = text.lowercased().contains("exam") ? .exam : .assignment
        // Saves into AppDataStore so the new deadline appears in Hub and Schedule straight away.
        store.addDeadline(course: course, type: type, due: dueDate)

        return "Done - I added \(type.rawValue.lowercased()) for \(course), due \(dueDate.formatted(date: .abbreviated, time: .shortened))."
    }

    private func addScheduleItem(from text: String) -> String {
        guard let course = courseName(from: text) else {
            return "Tell me the class name, day and time, like: add iOS lab on Monday from 10 to 12."
        }

        guard let day = weekday(from: text) else {
            return "I can add \(course), but I need the day."
        }

        guard let hours = hourRange(from: text) else {
            return "I can add \(course) on \(day.displayName), but I need the time."
        }

        let dates = scheduleDates(startHour: hours.start, endHour: hours.end)
        // The day is stored separately because the Schedule tab filters by weekday.
        store.addScheduleItem(course: course, day: day, start: dates.start, end: dates.end)

        return "Done - I added \(course) on \(day.displayName) from \(hours.start):00 to \(hours.end):00."
    }

    private func deadlineSummary() -> String {
        guard !store.upcomingDeadlines.isEmpty else {
            return "You do not have any deadlines yet."
        }

        let lines = store.upcomingDeadlines.prefix(5).map { item in
            "\(item.type.rawValue): \(item.course) - \(item.due.formatted(date: .abbreviated, time: .shortened))"
        }

        return "Your next deadlines:\n" + lines.joined(separator: "\n")
    }

    private func scheduleSummary() -> String {
        guard !store.todaysScheduleItems.isEmpty else {
            return "You do not have classes scheduled for today."
        }

        let lines = store.todaysScheduleItems.map { item in
            "\(item.course) - \(item.start.formatted(date: .omitted, time: .shortened)) to \(item.end.formatted(date: .omitted, time: .shortened))"
        }

        return "Today you have:\n" + lines.joined(separator: "\n")
    }

    private var appContext: String {
        let deadlineText = store.upcomingDeadlines.prefix(5).map { item in
            "\(item.type.rawValue): \(item.course), due \(item.due.formatted(date: .abbreviated, time: .shortened))"
        }.joined(separator: "; ")

        let scheduleText = store.todaysScheduleItems.map { item in
            "\(item.course) from \(item.start.formatted(date: .omitted, time: .shortened)) to \(item.end.formatted(date: .omitted, time: .shortened))"
        }.joined(separator: "; ")

        return """
        App name: Studius.
        Current deadlines: \(deadlineText.isEmpty ? "none" : deadlineText).
        Today's classes: \(scheduleText.isEmpty ? "none" : scheduleText).
        The campus map has the Library on the 3rd floor in Cavendish Campus.
        Keep replies short and clear.
        """
    }

    private func courseName(from text: String) -> String? {
        let lower = text.lowercased()

        // A few common module names are cleaned manually to make the demo feel more natural.
        if lower.contains("database") { return "Database Systems" }
        if lower.contains("ios") { return "iOS Lab" }
        if lower.contains("web") { return "Web Development" }
        if lower.contains("math") { return "Math" }
        if lower.contains("biology") { return "Biology" }

        var cleaned = text
        let removeWords = [
            "add", "create", "deadline", "assignment", "exam", "coursework",
            "class", "lecture", "lab", "seminar", "due", "tomorrow", "today",
            "next week", "schedule", "set", "remind", "please", "my", "for",
            "on", "from", "to", "at", "by"
        ]

        for word in removeWords {
            cleaned = cleaned.replacingOccurrences(of: word, with: "", options: .caseInsensitive)
        }

        AppDataStore.Weekday.allCases.forEach {
            cleaned = cleaned.replacingOccurrences(of: $0.rawValue, with: "", options: .caseInsensitive)
        }

        cleaned = cleaned.replacingOccurrences(of: #"\d{1,2}(:\d{2})?\s*(am|pm)?"#, with: "", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))

        return cleaned.isEmpty ? nil : cleaned.capitalized
    }

    private func dueDate(from text: String) -> Date? {
        let lower = text.lowercased()
        // This is a small parser, not a full calendar engine, but it covers the phrases used in the app demo.
        if lower.contains("tomorrow") {
            return dateByAdding(days: 1)
        }
        if lower.contains("next week") {
            return dateByAdding(days: 7)
        }
        if lower.contains("today") {
            return Date().addingTimeInterval(60 * 60)
        }
        if let day = weekday(from: text) {
            let hour = singleHour(from: text) ?? 9
            return nextDate(for: day, hour: hour)
        }
        return nil
    }

    private func weekday(from text: String) -> AppDataStore.Weekday? {
        let lower = text.lowercased()
        return AppDataStore.Weekday.allCases.first { lower.contains($0.rawValue) }
    }

    private func hourRange(from text: String) -> (start: Int, end: Int)? {
        let pattern = #"(?i)(?:from\s*)?(\d{1,2})\s*(am|pm)?\s*(?:to|-)\s*(\d{1,2})\s*(am|pm)?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let startRange = Range(match.range(at: 1), in: text),
              let endRange = Range(match.range(at: 3), in: text),
              var start = Int(text[startRange]),
              var end = Int(text[endRange]) else {
            if let start = singleHour(from: text) {
                return (start, min(start + 1, 23))
            }
            return nil
        }

        let startSuffix = capturedText(in: text, match: match, index: 2)
        let endSuffix = capturedText(in: text, match: match, index: 4)
        start = normalHour(start, suffix: startSuffix ?? endSuffix)
        end = normalHour(end, suffix: endSuffix ?? startSuffix)

        if end <= start {
            end += 12
        }

        return (start, min(end, 23))
    }
    
    private func singleHour(from text: String) -> Int? {
        if let hour = firstHourMatch(in: text, pattern: #"(?i)\b(?:at|by)\s*(\d{1,2})(?::\d{2})?\s*(am|pm)?\b"#) {
            return hour
        }
        
        return firstHourMatch(in: text, pattern: #"(?i)\b(\d{1,2})(?::\d{2})?\s*(am|pm)\b"#)
    }
    
    private func firstHourMatch(in text: String, pattern: String) -> Int? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let hourRange = Range(match.range(at: 1), in: text),
              let hour = Int(text[hourRange]) else {
            return nil
        }
        
        let suffix = capturedText(in: text, match: match, index: 2)
        return normalHour(hour, suffix: suffix)
    }

    private func normalHour(_ hour: Int, suffix: String?) -> Int {
        if suffix?.lowercased() == "pm", hour < 12 {
            return hour + 12
        }
        if suffix?.lowercased() == "am", hour == 12 {
            return 0
        }
        return hour
    }

    private func scheduleDates(startHour: Int, endHour: Int) -> (start: Date, end: Date) {
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = startHour
        components.minute = 0
        let start = Calendar.current.date(from: components) ?? Date()
        components.hour = endHour
        let end = Calendar.current.date(from: components) ?? start.addingTimeInterval(60 * 60)
        return (start, end)
    }

    private func dateByAdding(days: Int) -> Date {
        let date = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    }
    
    private func nextDate(for weekday: AppDataStore.Weekday, hour: Int) -> Date {
        var components = DateComponents()
        components.weekday = calendarWeekdayNumber(for: weekday)
        
        let calendar = Calendar.current
        let nextDay = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) ?? Date()
        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: nextDay) ?? nextDay
    }
    
    private func calendarWeekdayNumber(for weekday: AppDataStore.Weekday) -> Int {
        switch weekday {
        case .sunday: return 1
        case .monday: return 2
        case .tuesday: return 3
        case .wednesday: return 4
        case .thursday: return 5
        case .friday: return 6
        case .saturday: return 7
        }
    }

    private func capturedText(in text: String, match: NSTextCheckingResult, index: Int) -> String? {
        guard match.range(at: index).location != NSNotFound,
              let range = Range(match.range(at: index), in: text) else {
            return nil
        }

        return String(text[range])
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let lastID = messages.last?.id else {
            return
        }

        withAnimation(.easeOut(duration: 0.2)) {
            proxy.scrollTo(lastID, anchor: .bottom)
        }
    }
}

#Preview {
    StudyAssistantView()
        .environment(AppDataStore())
}
