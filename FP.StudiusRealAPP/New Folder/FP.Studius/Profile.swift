//
//  Profile.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI

private enum ProfileTheme {
    static let background = Color(red: 0.81, green: 0.76, blue: 0.67)
    static let card = Color(red: 0.94, green: 0.88, blue: 0.80)
    static let darkCard = Color(red: 0.36, green: 0.28, blue: 0.20)
    static let softCard = Color.white.opacity(0.58)
}

// Profile View
struct ProfileView: View {
    enum Tab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case calculator = "Calculator"
        case more = "More"
        var id: String { rawValue }
    }

    @State private var selectedTab: Tab = .overview
    @State private var showingEditProfile = false
    @Binding var showSignInView: Bool
    
    init(showSignInView: Binding<Bool> = .constant(false)) {
        _showSignInView = showSignInView
    }

    var body: some View {
        NavigationStack {
            ZStack {
                ProfileTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        profileTopper

                        Picker("Section", selection: $selectedTab) {
                            ForEach(Tab.allCases) { tab in
                                Text(tab.rawValue).tag(tab)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(8)
                        .background(ProfileTheme.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)

                        Group {
                            switch selectedTab {
                            case .overview:
                                OverviewTab(showingEdit: $showingEditProfile)
                            case .calculator:
                                CalculatorTab()
                            case .more:
                                MoreTab(showSignInView: $showSignInView)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 24)
                    }
                    .padding(.top, 12)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .tint(ProfileTheme.darkCard)
        }
        .sheet(isPresented: $showingEditProfile) {
            NavigationStack { EditProfileView() }
        }
    }

    private var profileTopper: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(Color.white.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Student Profile")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Your account, grades and study preferences in one place.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.78))
            }

            Spacer()
        }
        .padding()
        .background(ProfileTheme.darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
        .padding(.horizontal)
    }
}

//  Profile Tabs

private struct OverviewTab: View {
    @Environment(AppDataStore.self) private var store
    @Binding var showingEdit: Bool
    @AppStorage("profile_name") private var name: String = ""
    @AppStorage("profile_email") private var email: String = ""
    @AppStorage("profile_major") private var major: String = ""
    @AppStorage("profile_year") private var year: String = ""

    private var initials: String {
        let parts = name
            .split(separator: " ")
            .compactMap { $0.first }
            .prefix(2)

        let value = parts.map { String($0).uppercased() }.joined()
        return value.isEmpty ? "S" : value
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ProfileHeaderCard(
                initials: initials,
                name: name.isEmpty ? "Student" : name,
                subtitle: major.isEmpty ? "Degree not added" : major,
                year: year.isEmpty ? "Year not added" : year,
                email: email.isEmpty ? "Email not added" : email
            )

            HStack(spacing: 12) {
                StatCard(title: "Classes", value: "\(store.scheduleItems.count)", systemImage: "calendar")
                StatCard(title: "Deadlines", value: "\(store.deadlines.count)", systemImage: "clock.badge.checkmark")
                StatCard(title: "Done", value: "\(store.completedDeadlineCount)", systemImage: "checkmark.circle")
            }

            ProfileCard(title: "Academic Details", systemImage: "graduationcap.fill") {
                VStack(spacing: 10) {
                    InfoRow(systemImage: "envelope.fill", title: "Email", text: email.isEmpty ? "Email not added" : email)
                    InfoRow(systemImage: "book.closed.fill", title: "Degree", text: major.isEmpty ? "Degree not added" : major)
                    InfoRow(systemImage: "person.2.fill", title: "Year", text: year.isEmpty ? "Year not added" : year)
                }

                Divider().padding(.vertical, 4)

                Button {
                    showingEdit = true
                } label: {
                    Label("Edit Profile", systemImage: "pencil")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct CalculatorTab: View {
    @State private var examScore: String = ""
    @State private var courseworkScore: String = ""
    @State private var resultText: String? = nil
    @State private var passed = false

    private func calculate() {
        let exam = Double(examScore) ?? 0
        let coursework = Double(courseworkScore) ?? 0
        let final = 0.5 * exam + 0.5 * coursework
        passed = exam >= 40 && coursework >= 40
        let status = passed ? "Pass" : "Fail - need 40 in both"
        resultText = String(format: "Final: %.1f - %@", final, status)
    }

    private func reset() {
        examScore = ""
        courseworkScore = ""
        resultText = nil
        passed = false
    }

    var body: some View {
        ProfileCard(title: "Grade Calculator", systemImage: "function") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "graduationcap.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(ProfileTheme.darkCard)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Final Grade Estimate")
                            .font(.headline)
                        Text("Exam and coursework are both weighted at 50%. You need at least 40 in both to pass.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(spacing: 12) {
                    ScoreInput(title: "Exam Score", placeholder: "0 - 100", value: $examScore)
                    ScoreInput(title: "Coursework Score", placeholder: "0 - 100", value: $courseworkScore)
                }

                HStack(spacing: 12) {
                    Button(action: calculate) {
                        Label("Calculate", systemImage: "equal.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(ProfileTheme.darkCard)

                    Button(action: reset) {
                        Image(systemName: "arrow.counterclockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(ProfileTheme.darkCard)
                    .accessibilityLabel("Reset calculator")
                }

                if let resultText {
                    Text(resultText)
                        .font(.headline)
                        .foregroundStyle(passed ? .green : .orange)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.58), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

private struct MoreTab: View {
    @Binding var showSignInView: Bool
    @AppStorage("studius_logged_in") private var isLoggedIn = false

    var body: some View {
        VStack(spacing: 16) {
            //links to library and student portal
            ProfileCard(title: "Quick Links", systemImage: "link.circle.fill") {
                LinkRow(title: "University Library", subtitle: "Research, books and online journals", url: URL(string: "https://www.westminster.ac.uk/library-and-it")!)
                LinkRow(title: "Student Portal", subtitle: "University systems and student services", url: URL(string: "https://www.westminster.ac.uk/current-students")!)
            }

            ProfileCard(title: "Account", systemImage: "person.crop.circle.fill") {
                NavigationLink {
                    SettingsView(showSignInView: $showSignInView)
                } label: {
                    SettingsActionRow(
                        title: "Account Settings",
                        subtitle: "Update email, password and sign-in details",
                        systemImage: "gearshape.fill",
                        color: ProfileTheme.darkCard,
                        trailingImage: "chevron.right"
                    )
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    do {
                        try AuthenticationManager.shared.signOut()
                    } catch {
                        print(error)
                    }
                    
                    isLoggedIn = false
                    showSignInView = true
                } label: {
                    SettingsActionRow(
                        //sign out function
                        title: "Sign Out",
                        subtitle: "Leave this account on this device",
                        systemImage: "rectangle.portrait.and.arrow.right",
                        color: .red,
                        trailingImage: nil
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Reusable Components

private struct ProfileCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(ProfileTheme.darkCard)

            content()
        }
        .padding(16)
        .background(ProfileTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.08), radius: 10, y: 5)
    }
}

private struct ProfileHeaderCard: View {
    let initials: String
    let name: String
    let subtitle: String
    let year: String
    let email: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                Text(initials)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 74, height: 74)
                    .background(ProfileTheme.darkCard, in: Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.22), lineWidth: 2))

                VStack(alignment: .leading, spacing: 6) {
                    Text(name)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.82))

                    Text(year)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ProfileTheme.darkCard)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.76), in: Capsule())
                }

                Spacer()
            }

            HStack(spacing: 8) {
                Image(systemName: "envelope.fill")
                Text(email)
                    .lineLimit(1)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.86))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.12), in: Capsule())
        }
        .padding(18)
        .background(ProfileTheme.darkCard)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 5)
    }
}

private struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 19))
                .foregroundStyle(ProfileTheme.darkCard)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(ProfileTheme.darkCard)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(ProfileTheme.card)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, y: 4)
    }
}

private struct InfoRow: View {
    let systemImage: String
    let title: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(ProfileTheme.darkCard, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(text)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding(10)
        .background(ProfileTheme.softCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct ScoreInput: View {
    let title: String
    let placeholder: String
    @Binding var value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $value)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(ProfileTheme.softCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

private struct LinkRow: View {
    let title: String
    let subtitle: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            SettingsActionRow(
                title: title,
                subtitle: subtitle,
                systemImage: "link",
                color: ProfileTheme.darkCard,
                trailingImage: "arrow.up.right"
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SettingsActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let color: Color
    let trailingImage: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(color, in: RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let trailingImage {
                Image(systemName: trailingImage)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(10)
        .background(ProfileTheme.softCard, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Bar Chart (used by Hub)
struct BarRow: View {
    let values: [Int]
    let maxValue: Int

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(values.indices, id: \.self) { idx in
                let value = values[idx]
                RoundedRectangle(cornerRadius: 4)
                    .fill(value == 0 ? .gray.opacity(0.2) : Color.brown)
                    .frame(maxWidth: .infinity)
                    .frame(height: max(CGFloat(value) / CGFloat(maxValue) * 70, 6))
                    .overlay(
                        Text(value > 0 ? "\(value)" : "")
                            .font(.caption2)
                            .foregroundStyle(.white)
                            .padding(2),
                        alignment: .bottom
                    )
                    .accessibilityLabel("Day \(idx + 1) completed \(value) assignments")
            }
        }
    }
}

private struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("profile_name") private var name: String = ""
    @AppStorage("profile_email") private var email: String = ""
    @AppStorage("profile_major") private var major: String = ""
    @AppStorage("profile_year") private var year: String = ""

    var body: some View {
        Form {
            Section("Basic Info") {
                TextField("Name", text: $name)
                    .textContentType(.name)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
            }

            Section("Academic") {
                TextField("Degree", text: $major)
                TextField("Year", text: $year)
            }
        }
        .scrollContentBackground(.hidden)
        .background(ProfileTheme.background)
        .navigationTitle("Edit Profile")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environment(AppDataStore())
}
