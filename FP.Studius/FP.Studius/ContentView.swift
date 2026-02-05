//
//  ContentView.swift
//  FP.Studius
//
//  Created by Fernando Jose cw1993048
//

import SwiftUI


struct ContentView: View {
    private let tabBarColor = Color(red: 207/255, green: 193/255, blue: 170/255)
    var body: some View {
        
        TabView {
            HubView()
                .tabItem {
                    Image(systemName: "house.circle")
                    Text("Hub")
                }
            
                 ScheduleView()
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Schedule")
                }
                
                SocialView()
                .tabItem {
                    Image(systemName: "person.2.circle.fill")
                    Text("Social")
                }
            
                MapView()
                .tabItem {
                    Image(systemName: "building.2")
                    Text("Map")
                }
            ProfileView()
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
}

