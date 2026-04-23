//
//  ContentView.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI

struct ContentView: View {
    @Binding var showSignInView: Bool
    @Environment(AppDataStore.self) private var store
    private let tabBarColor = Color(red: 207/255, green: 193/255, blue: 170/255)
    
    init(showSignInView: Binding<Bool> = .constant(false)) {
        _showSignInView = showSignInView
    }
    
    var body: some View {
        
        TabView(selection: Binding(
            get: { store.selectedTab },
            set: { store.selectedTab = $0 }
        )) {
            HubView()
                .tag(AppDataStore.MainTab.hub)
                .tabItem {
                    Image(systemName: "house.circle")
                    Text("Hub")
                }
            
                 ScheduleView()
                .tag(AppDataStore.MainTab.schedule)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Schedule")
                }
                
                SocialView()
                .tag(AppDataStore.MainTab.social)
                .tabItem {
                    Image(systemName: "person.2.circle.fill")
                    Text("Social")
                }
            
                MapView()
                .tag(AppDataStore.MainTab.map)
                .tabItem {
                    Image(systemName: "building.2")
                    Text("Map")
                }
            ProfileView(showSignInView: $showSignInView)
            .tag(AppDataStore.MainTab.profile)
            .tabItem {
                Image(systemName: "person.icloud.fill")
                Text("Profile")
            }
            
        }
        .toolbarBackground(tabBarColor, for: .tabBar)
        .toolbarBackgroundVisibility(.visible, for: .tabBar)
        .tint(.brown)
        
    }
}

#Preview {
    ContentView()
        .environment(AppDataStore())
}
