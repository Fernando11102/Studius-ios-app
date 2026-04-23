//
//  AuthView.swift
//  FP.Studius
//
//  Created by Apple on 15/04/2026.
//

import SwiftUI

struct AuthView: View {
    @Binding var showSignInView: Bool
    private let background = Color(red: 0.81, green: 0.76, blue: 0.67)
    private let cardBackground = Color(red: 0.94, green: 0.88, blue: 0.80)
    private let buttonColour = Color(red: 0.36, green: 0.28, blue: 0.20)
    
    var body: some View {
        ZStack {
            background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer(minLength: 24)
                
                WavingLogoView()
                
                VStack(spacing: 8) {
                    Text("Welcome to Studius")
                        .font(.largeTitle)
                        .bold()
                    Text("Your academic hub for classes, deadlines and student life.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Student Login")
                                .font(.headline)
                            Text("Use your email and password to continue.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "graduationcap.fill")
                            .font(.title2)
                            .foregroundStyle(buttonColour)
                    }
                    
                    NavigationLink{
                        SignInEmailView(showSignInView: $showSignInView)
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Continue with Email")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(buttonColour)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
                .padding(20)
                .background(cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 6)
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AuthView_Previews: PreviewProvider{
    static var previews: some View {
        NavigationStack {
            AuthView(showSignInView: .constant(false))
        }
    }
}
