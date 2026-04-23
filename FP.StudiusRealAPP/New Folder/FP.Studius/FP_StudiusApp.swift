//
//  FP_StudiusApp.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
 
enum FirebaseConfiguration {
    static func configureIfPossible() -> Bool {
        if FirebaseApp.app() != nil {
            return true
        }

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("GoogleService-Info.plist is missing from the app bundle.")
            return false
        }

        FirebaseApp.configure()
        return FirebaseApp.app() != nil
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    _ = FirebaseConfiguration.configureIfPossible()

    return true
  }
}

@main
struct FP_StudiusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var store = AppDataStore()
    @State private var isFirebaseConfigured = FirebaseApp.app() != nil

    init() {
        _ = FirebaseConfiguration.configureIfPossible()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if isFirebaseConfigured {
                    RootView()
                        .environment(store)
                } else {
                    Text("Firebase is not configured.")
                        .padding()
                }
            }
            .onAppear {
                isFirebaseConfigured = FirebaseApp.app() != nil
            }
        }
    }
}
