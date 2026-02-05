//
//  Profile.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//


import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

// MARK: - Models
struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let sender: String
    let text: String
    let date: Date
    let isMe: Bool
}

struct ForumComment: Identifiable, Hashable {
    let id = UUID()
    let author: String
    let content: String
    let date: Date
}

struct ForumPost: Identifiable, Hashable {
    let id = UUID()
    let course: String
    let author: String
    let content: String
    let date: Date
    var comments: [ForumComment] = []
}

enum SharedKind: String, CaseIterable, Identifiable {
    case photo
    case document
    var id: String { rawValue }
}

struct SharedItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let kind: SharedKind
    let date: Date
    let imageData: Data?
    let fileURL: URL?
}

// MARK: - Root Social View
struct SocialView: View {
    enum Section: String, CaseIterable, Identifiable { case chat = "Chat", forum = "Forum", sharing = "Sharing"; var id: String { rawValue } }

    @State private var section: Section = .chat

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $section) {
                ForEach(Section.allCases) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .padding([.horizontal, .top])

            Divider()

            switch section {
            case .chat:
                ChatOneOnOneView()
            case .forum:
                ForumPerCourseView()
            case .sharing:
                SharingView()
            }
        }
        .navigationTitle("Social")
    }
}

// MARK: - 1-on-1 Chat
struct ChatOneOnOneView: View {
    @State private var recipient: String = ""
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(sender: "alice", text: "Hey there!", date: .now.addingTimeInterval(-3600), isMe: false),
        ChatMessage(sender: "me", text: "Hi! What's up?", date: .now.addingTimeInterval(-3500), isMe: true)
    ]

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                TextField("Recipient username or ID", text: $recipient)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                Button("Start") {}
                    .buttonStyle(.bordered)
            }
            .padding()

            Divider()

            ScrollViewReader { proxy in
                List {
                    ForEach(messages) { msg in
                        HStack {
                            if msg.isMe { Spacer() }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(msg.text)
                                    .padding(10)
                                    .background(msg.isMe ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                Text(msg.date, style: .time)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            if !msg.isMe { Spacer() }
                        }
                        .listRowSeparator(.hidden)
                        .id(msg.id)
                    }
                }
                .listStyle(.plain)
                .onChange(of: messages.count) { _ in
                    if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
                }
            }

            Divider()

            HStack {
                TextField("Message", text: $messageText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Button {
                    send()
                } label: {
                    Image(systemName: "paperplane.fill")
                }
                .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || recipient.isEmpty)
            }
            .padding()
        }
    }

    private func send() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !recipient.isEmpty else { return }
        withAnimation {
            messages.append(ChatMessage(sender: "me", text: trimmed, date: .now, isMe: true))
        }
        messageText = ""
        // Hook: send to backend here using recipient
    }
}

// MARK: - Forum per Course
struct ForumPerCourseView: View {
    @State private var courses: [String] = ["Math 101", "History 202", "Biology 303"]
    @State private var selectedCourse: String = "Math 101"

    @State private var posts: [ForumPost] = [
        ForumPost(course: "Math 101", author: "alice", content: "How did you solve problem 5?", date: .now.addingTimeInterval(-7200), comments: [
            ForumComment(author: "bob", content: "I used substitution.", date: .now.addingTimeInterval(-7100))
        ])
    ]

    @State private var newPostText: String = ""

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Course", selection: $selectedCourse) {
                    ForEach(courses, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                Spacer()
            }
            Divider()

            List {
                Section("Create Post in \(selectedCourse)") {
                    VStack(alignment: .leading) {
                        TextField("Share something with the course...", text: $newPostText, axis: .vertical)
                            .lineLimit(1...5)
                        HStack {
                            Spacer()
                            Button("Post") { addPost() }
                                .disabled(newPostText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }

                ForEach(posts.filter { $0.course == selectedCourse }) { post in
                    ForumPostRow(post: binding(for: post))
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    private func addPost() {
        let trimmed = newPostText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            posts.insert(ForumPost(course: selectedCourse, author: "me", content: trimmed, date: .now), at: 0)
        }
        newPostText = ""
        // Hook: persist post to backend here
    }

    private func binding(for post: ForumPost) -> Binding<ForumPost> {
        guard let idx = posts.firstIndex(where: { $0.id == post.id }) else {
            return .constant(post)
        }
        return $posts[idx]
    }
}

struct ForumPostRow: View {
    @Binding var post: ForumPost
    @State private var newComment: String = ""
    @State private var expanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(post.author).font(.subheadline).bold()
                    Text(post.content)
                    Text(post.date, style: .relative).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }

            DisclosureGroup(isExpanded: $expanded) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(post.comments) { c in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.author).font(.footnote).bold()
                            Text(c.content)
                            Text(c.date, style: .time).font(.caption2).foregroundStyle(.secondary)
                        }
                        .padding(8)
                        .background(Color.gray.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    HStack(alignment: .top) {
                        TextField("Add a comment", text: $newComment, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(8)
                            .background(Color.gray.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button("Send") { addComment() }
                            .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(.top, 4)
            } label: {
                Text("Comments (\(post.comments.count))").font(.subheadline)
            }
        }
        .padding(.vertical, 6)
    }

    private func addComment() {
        let trimmed = newComment.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            post.comments.append(ForumComment(author: "me", content: trimmed, date: .now))
        }
        newComment = ""
        // Hook: persist comment to backend here
    }
}

// MARK: - Photo/Documents Sharing
struct SharingView: View {
    @State private var items: [SharedItem] = []

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isImportingDoc = false

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                    Label("Add Photo", systemImage: "photo.on.rectangle")
                }
                .onChange(of: photoPickerItem) { _, newValue in
                    if let item = newValue { handlePickedPhoto(item) }
                }

                Button {
                    isImportingDoc = true
                } label: {
                    Label("Upload File", systemImage: "tray.and.arrow.up")
                }
                .fileImporter(isPresented: $isImportingDoc, allowedContentTypes: [.item]) { result in
                    switch result {
                    case .success(let url):
                        addDocument(url: url)
                    case .failure:
                        break
                    }
                }
                Spacer()
            }
            .padding()

            if items.isEmpty {
                ContentUnavailableView("No shared items", systemImage: "tray", description: Text("Upload a photo or file to get started."))
                    .padding()
            } else {
                List {
                    ForEach(items) { item in
                        SharedItemRow(item: item)
                    }
                    .onDelete { indexSet in
                        items.remove(atOffsets: indexSet)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }

    private func handlePickedPhoto(_ item: PhotosPickerItem) {
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let name = (try? await item.loadTransferable(type: String.self)) ?? "Photo"
                withAnimation {
                    items.insert(SharedItem(name: name, kind: .photo, date: .now, imageData: data, fileURL: nil), at: 0)
                }
                // Hook: upload image data to backend here
            }
        }
    }

    private func addDocument(url: URL) {
        withAnimation {
            items.insert(SharedItem(name: url.lastPathComponent, kind: .document, date: .now, imageData: nil, fileURL: url), at: 0)
        }
        // Hook: upload file at url to backend here
    }
}

struct SharedItemRow: View {
    let item: SharedItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            switch item.kind {
            case .photo:
                if let data = item.imageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "photo")
                        .font(.title2)
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.secondary)
                }
            case .document:
                Image(systemName: "doc")
                    .font(.title2)
                    .frame(width: 48, height: 48)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading) {
                Text(item.name).lineLimit(1)
                Text(item.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
}

#Preview {
    NavigationStack { SocialView() }
}
