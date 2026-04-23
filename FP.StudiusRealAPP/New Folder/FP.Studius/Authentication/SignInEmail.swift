//
//  SignInEmail.swift
//  FP.Studius
//
//  Created by Apple on 15/04/2026.
//

import Combine
import FirebaseAuth
import SwiftUI

final class SignInEmailModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    
    // This keeps the demo login simple for testing: any typed email/password can enter the app.
    func enterDemoAccount() throws -> String {
        let userEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let userPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !userEmail.isEmpty, !userPassword.isEmpty else {
            throw URLError(.badURL)
        }
        
        return userEmail
    }
    
    // Firebase is still attempted in the background, but it should not block the student from viewing the app.
    func tryFirebaseSession(for userEmail: String) async {
        do {
            try await openFirebaseSession(for: userEmail)
        } catch {
            print("Firebase login skipped:", error.localizedDescription)
        }
    }
    
    private func openFirebaseSession(for userEmail: String) async throws {
        let details = firebaseLoginDetails(for: userEmail)
        
        do {
            try await AuthenticationManager.shared.signInUser(email: details.email, password: details.password)
        } catch {
            if shouldCreateAccount(from: error) {
                do {
                    try await AuthenticationManager.shared.createUser(email: details.email, password: details.password)
                } catch {
                    if shouldUseAnonymousLogin(from: error) {
                        try await AuthenticationManager.shared.signInAnonymously()
                    } else {
                        throw error
                    }
                }
            } else if shouldUseAnonymousLogin(from: error) {
                try await AuthenticationManager.shared.signInAnonymously()
            } else {
                throw error
            }
        }
    }
    
    // The typed email is converted into a valid Firebase email because Firebase does not accept random text.
    private func firebaseLoginDetails(for userEmail: String) -> (email: String, password: String) {
        let cleanedEmail = userEmail.lowercased()
        let demoEmail = "demo-\(stableHash(cleanedEmail))@studius-demo.com"
        
        return (demoEmail, "StudiusDemo123!")
    }
    
    private func shouldCreateAccount(from error: Error) -> Bool {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        return code == .userNotFound || code == .invalidCredential || code == .wrongPassword
    }
    
    private func shouldUseAnonymousLogin(from error: Error) -> Bool {
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        return code == .operationNotAllowed
    }
    
    private func stableHash(_ text: String) -> String {
        var hash: UInt64 = 5381
        
        for character in text.unicodeScalars {
            hash = ((hash << 5) &+ hash) &+ UInt64(character.value)
        }
        
        return String(hash, radix: 16)
    }
}

struct SignInEmailView: View {
    @StateObject private var viewModel = SignInEmailModel()
    @Binding var showSignInView: Bool
    @State private var message: String?
    @AppStorage("studius_logged_in") private var isLoggedIn = false
    @AppStorage("profile_email") private var profileEmail = ""
    @AppStorage("profile_name") private var profileName = ""
    private let background = Color(red: 0.81, green: 0.76, blue: 0.67)
    private let cardBackground = Color(red: 0.94, green: 0.88, blue: 0.80)
    private let buttonColour = Color(red: 0.36, green: 0.28, blue: 0.20)
    
    var body: some View {
        
        ZStack {
            background.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 22) {
                    VStack(spacing: 10) {
                        BlueBotGraduationLogoView()
                            .frame(width: 86, height: 86)
                            .padding(16)
                            .background(Color.white.opacity(0.20))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        
                        Text("Sign in to Studius")
                            .font(.title)
                            .bold()
                        Text("Keep your schedule, deadlines and profile in one place.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Email and Password")
                            .font(.headline)
                        
                        VStack(spacing: 12) {
                            TextField("Email address", text: $viewModel.email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.white.opacity(0.75))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            
                            SecureField("Password", text: $viewModel.password)
                                .padding()
                                .background(Color.white.opacity(0.75))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        
                        if let message {
                            Text(message)
                                .font(.footnote)
                                .foregroundStyle(message.contains("successfully") ? .green : .red)
                        }
                        
                        VStack(spacing: 10) {
                            Button {
                                enterApp()
                            } label: {
                                HStack {
                                    Image(systemName: "lock.open.fill")
                                    Text("Enter the Hub")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(height: 55)
                                .frame(maxWidth: .infinity)
                                .background(buttonColour)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        
                        Text("Use any email and password to try the app.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .background(cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                }
                .padding()
            }
        }
        .navigationTitle("Email Sign In")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func enterApp() {
        message = nil
        
        do {
            let enteredEmail = try viewModel.enterDemoAccount()
            saveProfileDetails(from: enteredEmail)
            // Local login opens the app immediately, like a simple prototype login.
            isLoggedIn = true
            showSignInView = false
            
            Task {
                await viewModel.tryFirebaseSession(for: enteredEmail)
            }
        } catch {
            print(error)
            message = authMessage(from: error)
        }
    }
    
    private func saveProfileDetails(from enteredEmail: String) {
        profileEmail = enteredEmail
        
        if profileName.isEmpty {
            let namePart = enteredEmail.split(separator: "@").first.map(String.init) ?? enteredEmail
            profileName = namePart
                .replacingOccurrences(of: ".", with: " ")
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }
    
    private func authMessage(from error: Error) -> String {
        let nsError = error as NSError
        
        if nsError.domain == NSURLErrorDomain {
            return "Please enter both email and password."
        }
        
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return nsError.localizedDescription
        }
        
        switch code {
        case .invalidEmail:
            return "There was a problem preparing the Firebase login."
        case .weakPassword:
            return "Firebase needs a stronger password for this test account."
        case .emailAlreadyInUse:
            return "This test account already exists. Please try again."
        case .userNotFound:
            return "This test account could not be created."
        case .wrongPassword, .invalidCredential:
            return "This Firebase test login could not be opened."
        case .operationNotAllowed:
            return "Enable Email/Password or Anonymous sign-in in Firebase."
        case .networkError:
            return "Network problem. Please check your connection."
        default:
            return nsError.localizedDescription
        }
    }
}
        
        struct SignInEmailView_Previews: PreviewProvider {
            static var previews: some View {
                
                NavigationStack {
                    
                    
                    SignInEmailView(showSignInView: .constant(false))
                }
            }
        }
