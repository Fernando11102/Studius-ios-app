//
//  SettingsView.swift
//  FP.Studius
//
//  Created by Apple on 16/04/2026.
//

import SwiftUI

@MainActor
final class SettingsViewModel {
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }

    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        try await AuthenticationManager.shared.resetPassword(email: email)
    }

    func updateEmail(email: String) async throws {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedEmail.isEmpty else {
            throw URLError(.badURL)
        }
        try await AuthenticationManager.shared.updateEmail(email: trimmedEmail)
    }

    func updatePassword(password: String) async throws {
        guard password.count >= 6 else {
            throw URLError(.badURL)
        }
        try await AuthenticationManager.shared.updatePassword(password: password)
    }
}

struct SettingsView: View {
    private let viewModel = SettingsViewModel()
    @Binding var showSignInView: Bool
    @AppStorage("studius_logged_in") private var isLoggedIn = false
    @State private var newEmail = ""
    @State private var newPassword = ""
    
    var body: some View {
        List {
            Section("Account") {
                Button("Log out") {
                    Task {
                        do {
                            try viewModel.signOut()
                        } catch {
                            print(error)
                        }
                        
                        isLoggedIn = false
                        showSignInView = true
                    }
                }
                Button("Reset password") {
                    Task {
                        do {
                            try await viewModel.resetPassword()
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            
            Section("Update Email") {
                TextField("New email address", text: $newEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                
                Button("Update email") {
                    Task {
                        do {
                            try await viewModel.updateEmail(email: newEmail)
                            newEmail = ""
                        } catch {
                            print(error)
                        }
                    }
                }
            }
            
            Section("Update Password") {
                SecureField("New password", text: $newPassword)
                
                Button("Update password") {
                    Task {
                        do {
                            try await viewModel.updatePassword(password: newPassword)
                            newPassword = ""
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
        
}

    



struct SettingsView_Previews: PreviewProvider {
    static var previews: some View{
        NavigationStack{
            SettingsView(showSignInView: .constant(false))
        }
    }
}
