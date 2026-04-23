//
//  Social.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI
import Combine
import PhotosUI
import UniformTypeIdentifiers
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

private enum SocialTheme {
    static let background = Color(red: 0.81, green: 0.76, blue: 0.67)
    static let card = Color(red: 0.94, green: 0.88, blue: 0.80)
    static let darkCard = Color(red: 0.36, green: 0.28, blue: 0.20)
}
//struct that manages the function to post in the forum
struct ChatMessage: Identifiable, Hashable {
    let id: String
    let sender: String
    let text: String
    let date: Date
    let isMe: Bool
}

struct ForumComment: Identifiable, Hashable {
    let id: String
    let author: String
    let content: String
    let date: Date
}

struct ForumPost: Identifiable, Hashable {
    let id: String
    let course: String
    let author: String
    let content: String
    let date: Date
    let comments: [ForumComment]
}

enum SharedKind: String, CaseIterable, Identifiable {
    case photo
    case document

    var id: String { rawValue }
}

struct SharedItem: Identifiable, Hashable {
    let id: String
    let name: String
    let kind: SharedKind
    let author: String
    let date: Date
    let downloadURL: URL?
    let storagePath: String
    let course: String
}

@MainActor
final class SocialStore: ObservableObject {
    let courses = [
        "Software Engineering Principles",
        "Programming & Algorithms",
        "Data Structures",
        "Database Systems",
        "Web Development",
        "Mobile App Development",
        "Cloud & DevOps",
        "Software Testing",
        "Cyber Security",
        "Final Year Project"
    ]

    @Published var isReady = false
    @Published var isUploading = false
    @Published var errorMessage: String?
    @Published var displayName = "Student"
    @Published var currentRoom = "general"
    @Published var selectedCourse = "Software Engineering Principles"
    @Published var messages: [ChatMessage] = []
    @Published var posts: [ForumPost] = []
    @Published var sharedItems: [SharedItem] = []

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private var started = false
    private var chatListener: ListenerRegistration?
    private var postsListener: ListenerRegistration?
    private var sharedItemsListener: ListenerRegistration?
    private var localPosts: [ForumPost] = []
    private var localCommentsByPostID: [String: [ForumComment]] = [:]

    // Firestore listeners stay open while the social page is being used, so they are removed here.
    deinit {
        chatListener?.remove()
        postsListener?.remove()
        sharedItemsListener?.remove()
    }

    var currentUserID: String {
        auth.currentUser?.uid ?? ""
    }

    func start() async {
        guard !started else { return }
        started = true

        do {
            // The social page needs a Firebase user before reading or writing chat data.
            try await ensureSignedIn()
            beginPostsListener(for: selectedCourse)
            beginSharedItemsListener()
            isReady = true
        } catch {
            isReady = true
            handle(error)
        }
    }

    func openRoom(named rawValue: String) {
        let sanitized = Self.sanitizedRoomID(rawValue)
        guard !sanitized.isEmpty else { return }

        // Room names are sanitised so they are safe to use as Firestore document IDs.
        currentRoom = sanitized
        beginChatListener(for: sanitized)
    }

    func selectCourse(_ course: String) {
        selectedCourse = course
        beginPostsListener(for: course)
    }

    func sendMessage(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !currentRoom.isEmpty else { return }

        do {
            try await ensureSignedIn()

            let messageRef = db
                .collection("socialChats")
                .document(currentRoom)
                .collection("messages")
                .document()

            try await setData(
                messageRef,
                data: [
                    "authorID": currentUserID,
                    "authorName": displayName,
                    "text": trimmed,
                    "createdAt": FieldValue.serverTimestamp()
                ]
            )
        } catch {
            handle(error)
        }
    }

    func addPost(text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let course = selectedCourse

        do {
            try await ensureSignedIn()

            let postRef = db.collection("socialForumPosts").document()
            try await setData(
                postRef,
                data: [
                    "course": course,
                    "authorID": currentUserID,
                    "authorName": displayName,
                    "content": trimmed,
                    "createdAt": FieldValue.serverTimestamp(),
                    "comments": []
                ]
            )
        } catch {
            addLocalPost(text: trimmed, course: course)
            handle(error)
        }
    }

    func addComment(to postID: String, text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if postID.hasPrefix("local-") {
            addLocalComment(to: postID, text: trimmed)
            return
        }

        do {
            try await ensureSignedIn()

            let comment: [String: Any] = [
                "id": UUID().uuidString,
                "authorID": currentUserID,
                "authorName": displayName,
                "content": trimmed,
                "createdAt": Timestamp(date: Date())
            ]

            try await updateData(
                db.collection("socialForumPosts").document(postID),
                data: ["comments": FieldValue.arrayUnion([comment])]
            )
        } catch {
            addLocalComment(to: postID, text: trimmed)
            handle(error)
        }
    }

    func uploadPhoto(data: Data, suggestedName: String) async {
        let trimmedName = suggestedName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fileName = trimmedName.isEmpty ? "Photo" : trimmedName
        let itemID = UUID().uuidString
        let storagePath = "shared/\(itemID).jpg"
        let storageRef = storage.reference(withPath: storagePath)

        isUploading = true

        do {
            try await ensureSignedIn()

            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"

            try await putData(storageRef, data: data, metadata: metadata)
            let downloadURL = try await fetchDownloadURL(for: storageRef)

            try await setData(
                db.collection("socialSharedItems").document(itemID),
                data: [
                    "name": fileName,
                    "kind": SharedKind.photo.rawValue,
                    "authorID": currentUserID,
                    "authorName": displayName,
                    "createdAt": FieldValue.serverTimestamp(),
                    "downloadURL": downloadURL.absoluteString,
                    "storagePath": storagePath,
                    "course": selectedCourse
                ]
            )
        } catch {
            handle(error)
        }

        isUploading = false
    }

    func uploadDocument(url: URL) async {
        let itemID = UUID().uuidString
        let storagePath = "shared/\(itemID)-\(url.lastPathComponent)"
        let storageRef = storage.reference(withPath: storagePath)
        let didStartAccess = url.startAccessingSecurityScopedResource()

        isUploading = true

        defer {
            if didStartAccess {
                url.stopAccessingSecurityScopedResource()
            }
            isUploading = false
        }

        do {
            try await ensureSignedIn()

            let data = try Data(contentsOf: url)
            let metadata = StorageMetadata()
            metadata.contentType = UTType(filenameExtension: url.pathExtension)?.preferredMIMEType

            try await putData(storageRef, data: data, metadata: metadata)
            let downloadURL = try await fetchDownloadURL(for: storageRef)

            try await setData(
                db.collection("socialSharedItems").document(itemID),
                data: [
                    "name": url.lastPathComponent,
                    "kind": SharedKind.document.rawValue,
                    "authorID": currentUserID,
                    "authorName": displayName,
                    "createdAt": FieldValue.serverTimestamp(),
                    "downloadURL": downloadURL.absoluteString,
                    "storagePath": storagePath,
                    "course": selectedCourse
                ]
            )
        } catch {
            handle(error)
        }
    }

    func deleteSharedItems(at offsets: IndexSet) async {
        let itemsToDelete = offsets.map { sharedItems[$0] }

        for item in itemsToDelete {
            do {
                try await deleteDocument(db.collection("socialSharedItems").document(item.id))
                try await deleteStorageItem(at: item.storagePath)
            } catch {
                handle(error)
            }
        }
    }

    private func beginChatListener(for roomID: String) {
        chatListener?.remove()
        messages = []

        chatListener = db
            .collection("socialChats")
            .document(roomID)
            .collection("messages")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    Task { @MainActor in
                        self.handle(error)
                    }
                    return
                }

                let currentUserID = self.currentUserID
                let parsedMessages = snapshot?.documents.compactMap { document in
                    Self.makeChatMessage(from: document, currentUserID: currentUserID)
                } ?? []

                Task { @MainActor in
                    self.messages = parsedMessages
                }
            }
    }

    private func beginPostsListener(for course: String) {
        postsListener?.remove()
        posts = postsForDisplay(remotePosts: [], course: course)

        postsListener = db
            .collection("socialForumPosts")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    Task { @MainActor in
                        self.handle(error)
                    }
                    return
                }

                let parsedPosts = snapshot?.documents.compactMap(Self.makeForumPost).filter { $0.course == course } ?? []

                Task { @MainActor in
                    self.posts = self.postsForDisplay(remotePosts: parsedPosts, course: course)
                }
            }
    }

    private func addLocalPost(text: String, course: String) {
        let post = ForumPost(
            id: "local-\(UUID().uuidString)",
            course: course,
            author: displayName,
            content: text,
            date: Date(),
            comments: []
        )

        localPosts.insert(post, at: 0)

        if selectedCourse == course {
            posts.insert(post, at: 0)
        }
    }

    private func addLocalComment(to postID: String, text: String) {
        let comment = ForumComment(
            id: "local-\(UUID().uuidString)",
            author: displayName,
            content: text,
            date: Date()
        )

        localCommentsByPostID[postID, default: []].append(comment)
        posts = posts.map { post in
            guard post.id == postID else { return post }

            return ForumPost(
                id: post.id,
                course: post.course,
                author: post.author,
                content: post.content,
                date: post.date,
                comments: post.comments + [comment]
            )
        }
    }

    private func postsForDisplay(remotePosts: [ForumPost], course: String) -> [ForumPost] {
        let storedLocalPosts = localPosts.filter { $0.course == course }
        return (storedLocalPosts + remotePosts).map(postAddingLocalComments)
    }

    private func postAddingLocalComments(_ post: ForumPost) -> ForumPost {
        guard let localComments = localCommentsByPostID[post.id], !localComments.isEmpty else {
            return post
        }

        return ForumPost(
            id: post.id,
            course: post.course,
            author: post.author,
            content: post.content,
            date: post.date,
            comments: post.comments + localComments
        )
    }

    private func beginSharedItemsListener() {
        sharedItemsListener?.remove()
        sharedItems = []

        sharedItemsListener = db
            .collection("socialSharedItems")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    Task { @MainActor in
                        self.handle(error)
                    }
                    return
                }

                let parsedItems = snapshot?.documents.compactMap(Self.makeSharedItem) ?? []

                Task { @MainActor in
                    self.sharedItems = parsedItems
                }
            }
    }

    private func ensureSignedIn() async throws {
        if let user = auth.currentUser {
            displayName = Self.displayName(for: user)
            return
        }

        throw NSError(
            domain: "SocialStore",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Please sign in before using the student forum."]
        )
    }

    private func setData(_ reference: DocumentReference, data: [String: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.setData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func updateData(_ reference: DocumentReference, data: [AnyHashable: Any]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.updateData(data) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func putData(_ reference: StorageReference, data: Data, metadata: StorageMetadata?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.putData(data, metadata: metadata) { _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func fetchDownloadURL(for reference: StorageReference) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            reference.downloadURL { url, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: NSError(domain: "SocialStore", code: -2, userInfo: [NSLocalizedDescriptionKey: "Could not fetch download URL."]))
                }
            }
        }
    }

    private func deleteDocument(_ reference: DocumentReference) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            reference.delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func deleteStorageItem(at path: String) async throws {
        guard !path.isEmpty else { return }

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            storage.reference(withPath: path).delete { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    private func handle(_ error: Error) {
        errorMessage = nil
    }

    private static func displayName(for user: User) -> String {
        if let email = user.email,
           let name = email.split(separator: "@").first {
            return String(name)
        }
        
        return "Student \(user.uid.prefix(6))"
    }

    private static func sanitizedRoomID(_ rawValue: String) -> String {
        let lowered = rawValue
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")

        return String(lowered.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" })
    }

    private static func makeChatMessage(from document: QueryDocumentSnapshot, currentUserID: String) -> ChatMessage? {
        let data = document.data()
        guard let sender = data["authorName"] as? String,
              let text = data["text"] as? String else {
            return nil
        }

        let senderID = data["authorID"] as? String ?? ""
        let timestamp = data["createdAt"] as? Timestamp

        return ChatMessage(
            id: document.documentID,
            sender: sender,
            text: text,
            date: timestamp?.dateValue() ?? Date(),
            isMe: senderID == currentUserID
        )
    }

    private static func makeForumPost(from document: QueryDocumentSnapshot) -> ForumPost? {
        let data = document.data()
        guard let course = data["course"] as? String,
              let author = data["authorName"] as? String,
              let content = data["content"] as? String else {
            return nil
        }

        let commentsArray = data["comments"] as? [[String: Any]] ?? []
        let comments = commentsArray.compactMap(makeForumComment).sorted { $0.date < $1.date }
        let timestamp = data["createdAt"] as? Timestamp

        return ForumPost(
            id: document.documentID,
            course: course,
            author: author,
            content: content,
            date: timestamp?.dateValue() ?? Date(),
            comments: comments
        )
    }

    private static func makeForumComment(from data: [String: Any]) -> ForumComment? {
        guard let id = data["id"] as? String,
              let author = data["authorName"] as? String,
              let content = data["content"] as? String else {
            return nil
        }

        let timestamp = data["createdAt"] as? Timestamp

        return ForumComment(
            id: id,
            author: author,
            content: content,
            date: timestamp?.dateValue() ?? Date()
        )
    }

    private static func makeSharedItem(from document: QueryDocumentSnapshot) -> SharedItem? {
        let data = document.data()
        guard let name = data["name"] as? String,
              let kindRawValue = data["kind"] as? String,
              let kind = SharedKind(rawValue: kindRawValue),
              let author = data["authorName"] as? String,
              let storagePath = data["storagePath"] as? String else {
            return nil
        }

        let timestamp = data["createdAt"] as? Timestamp
        let urlString = data["downloadURL"] as? String
        let course = data["course"] as? String ?? "General"

        return SharedItem(
            id: document.documentID,
            name: name,
            kind: kind,
            author: author,
            date: timestamp?.dateValue() ?? Date(),
            downloadURL: urlString.flatMap(URL.init(string:)),
            storagePath: storagePath,
            course: course
        )
    }
}

struct SocialView: View {
    enum Section: String, CaseIterable, Identifiable {
        case forum = "Forum"
        case sharing = "Resources"

        var id: String { rawValue }
    }

    @StateObject private var store = SocialStore()
    @State private var section: Section = .forum

    var body: some View {
        NavigationStack {
            ZStack {
                SocialTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Studius Forum")
                                    .font(.title)
                                    .bold()
                                    .foregroundStyle(.white)
                                Text("Share questions, notes and useful sources with software engineering students.")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.78))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "person.3.sequence.fill")
                                .font(.system(size: 38))
                                .foregroundStyle(.white)
                        }
                        
                        HStack {
                            Label(store.isReady ? "Live forum" : "Connecting", systemImage: store.isReady ? "checkmark.circle.fill" : "wifi")
                            Spacer()
                            Text(store.displayName)
                                .lineLimit(1)
                        }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color.white.opacity(0.12), in: Capsule())
                    }
                    .padding()
                    .background(SocialTheme.darkCard)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
                    .padding()
                    
                    Picker("Section", selection: $section) {
                        ForEach(Section.allCases) { section in
                            Text(section.rawValue).tag(section)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    Group {
                        switch section {
                        case .forum:
                            ForumPerCourseView(store: store)
                        case .sharing:
                            SharingView(store: store)
                        }
                    }
                }
            }
            .navigationTitle("Social")
            .navigationBarTitleDisplayMode(.inline)
            .tint(SocialTheme.darkCard)
            .task {
                await store.start()
            }
        }
    }
}

struct ForumPerCourseView: View {
    @ObservedObject var store: SocialStore
    @State private var newPostText = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TopicSelectorView(store: store)
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Post to \(store.selectedCourse)", systemImage: "bubble.left.and.bubble.right.fill")
                            .font(.headline)
                        Spacer()
                    }
                    
                    TextField("Ask a question, share notes, paste a useful link...", text: $newPostText, axis: .vertical)
                        .lineLimit(2...6)
                        .padding(12)
                        .background(Color.white.opacity(0.65))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    
                    HStack {
                        Text("Helpful posts: lecture notes, GitHub links, articles, code tips, exam prep.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        
                        Button {
                            let text = newPostText
                            newPostText = ""
                            
                            Task {
                                await store.addPost(text: text)
                            }
                        } label: {
                            Label("Post", systemImage: "paperplane.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SocialTheme.darkCard)
                        .disabled(newPostText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding()
                .background(SocialTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                
                if store.posts.isEmpty {
                    SocialEmptyState(
                        systemImage: "text.bubble",
                        title: "No posts for this topic yet",
                        subtitle: "Start the discussion by sharing a question, resource or study tip."
                    )
                } else {
                    ForEach(store.posts) { post in
                        ForumPostRow(post: post) { text in
                            await store.addComment(to: post.id, text: text)
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

struct ForumPostRow: View {
    let post: ForumPost
    let onAddComment: (String) async -> Void

    @State private var newComment = ""
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(String(post.author.prefix(1)).uppercased())
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(SocialTheme.darkCard, in: Circle())
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text(post.author)
                            .font(.subheadline.bold())
                        Text(post.date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(post.content)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
            }

            VStack(alignment: .leading, spacing: 10) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                        expanded.toggle()
                    }
                } label: {
                    HStack {
                        Label("Replies (\(post.comments.count))", systemImage: "bubble.left.fill")
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(expanded ? 0 : -90))
                    }
                    .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                
                if expanded {
                    ForEach(post.comments) { comment in
                        ForumCommentBubble(comment: comment)
                    }
                    
                    HStack(alignment: .top) {
                        TextField("Reply like a chat...", text: $newComment, axis: .vertical)
                            .lineLimit(1...3)
                            .padding(10)
                            .background(Color.white.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        Button {
                            let text = newComment
                            newComment = ""
                            
                            Task {
                                await onAddComment(text)
                            }
                        } label: {
                            Image(systemName: "paperplane.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(SocialTheme.darkCard, in: Circle())
                        }
                        .disabled(newComment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
        }
        .padding()
        .background(SocialTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }
}

struct ForumCommentBubble: View {
    let comment: ForumComment
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "person.crop.circle.fill")
                .foregroundStyle(SocialTheme.darkCard.opacity(0.75))
            
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(comment.author)
                        .font(.footnote.bold())
                    Text(comment.date, style: .time)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Text(comment.content)
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SharingView: View {
    @ObservedObject var store: SocialStore

    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isImportingDocument = false
    
    private var filteredItems: [SharedItem] {
        store.sharedItems.filter { $0.course == store.selectedCourse }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                TopicSelectorView(store: store)
                
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Label("Share Sources", systemImage: "tray.and.arrow.up.fill")
                            .font(.headline)
                        Spacer()
                    }
                    
                    Text("Upload screenshots, diagrams, PDFs or files that help with \(store.selectedCourse).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 12) {
                        PhotosPicker(selection: $photoPickerItem, matching: .images, photoLibrary: .shared()) {
                            Label("Photo", systemImage: "photo.on.rectangle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(SocialTheme.darkCard)
                        .onChange(of: photoPickerItem) { _, newValue in
                            guard let newValue else { return }
                            
                            Task {
                                if let data = try? await newValue.loadTransferable(type: Data.self) {
                                    await store.uploadPhoto(data: data, suggestedName: "Study Photo")
                                }
                                photoPickerItem = nil
                            }
                        }
                        
                        Button {
                            isImportingDocument = true
                        } label: {
                            Label("File", systemImage: "doc.badge.plus")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(SocialTheme.darkCard)
                        .fileImporter(isPresented: $isImportingDocument, allowedContentTypes: [.item]) { result in
                            guard case let .success(url) = result else { return }
                            
                            Task {
                                await store.uploadDocument(url: url)
                            }
                        }
                    }
                }
                .padding()
                .background(SocialTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                
                if store.isUploading {
                    ProgressView("Uploading source...")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                
                if filteredItems.isEmpty {
                    SocialEmptyState(
                        systemImage: "folder.badge.plus",
                        title: "No sources shared yet",
                        subtitle: "Upload the first useful file for this topic."
                    )
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Shared in \(store.selectedCourse)")
                            .font(.headline)
                        
                        ForEach(filteredItems) { item in
                            SharedItemRow(item: item)
                        }
                    }
                    .padding()
                    .background(SocialTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }
}

struct SharedItemRow: View {
    let item: SharedItem

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            resourceIcon
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text("Shared by \(item.author)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(item.date, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let url = item.downloadURL {
                Link(destination: url) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(SocialTheme.darkCard)
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
    
    @ViewBuilder
    private var resourceIcon: some View {
        switch item.kind {
        case .photo:
            if let url = item.downloadURL {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: "photo")
                    .font(.title2)
                    .frame(width: 52, height: 52)
                    .foregroundStyle(.secondary)
                    .background(Color.white.opacity(0.50))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

        case .document:
            Image(systemName: "doc.text.fill")
                .font(.title2)
                .frame(width: 52, height: 52)
                .foregroundStyle(.white)
                .background(SocialTheme.darkCard)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

struct TopicSelectorView: View {
    @ObservedObject var store: SocialStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Software Engineering Topics", systemImage: "square.stack.3d.up.fill")
                    .font(.headline)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(store.courses, id: \.self) { course in
                        Button {
                            store.selectCourse(course)
                        } label: {
                            Text(course)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(store.selectedCourse == course ? .white : SocialTheme.darkCard)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 9)
                                .background(store.selectedCourse == course ? SocialTheme.darkCard : Color.white.opacity(0.55), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Text(topicHint(for: store.selectedCourse))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(SocialTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }
    
    private func topicHint(for topic: String) -> String {
        switch topic {
        case "Software Engineering Principles":
            return "Requirements, agile methods, UML, design patterns and teamwork."
        case "Programming & Algorithms":
            return "Swift, Java, Python, pseudocode, complexity and problem solving."
        case "Data Structures":
            return "Stacks, queues, trees, graphs, hashing and algorithm practice."
        case "Database Systems":
            return "SQL, ERDs, normalisation, Firebase and data modelling."
        case "Web Development":
            return "HTML, CSS, JavaScript, APIs, authentication and deployment."
        case "Mobile App Development":
            return "SwiftUI, app architecture, Firebase integration and UI testing."
        case "Cloud & DevOps":
            return "Git, CI/CD, Docker, cloud services and release workflows."
        case "Software Testing":
            return "Unit tests, UI tests, test plans, QA and debugging strategies."
        case "Cyber Security":
            return "Secure coding, authentication, privacy, threats and risk."
        default:
            return "Ideas, research, report structure, prototypes and presentation prep."
        }
    }
}

struct SocialEmptyState: View {
    let systemImage: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 34))
                .foregroundStyle(SocialTheme.darkCard)
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(SocialTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }
}

#Preview {
    SocialView()
}
