//
//  RootView.swift
//  FP.Studius
//
//  Created by Apple on 16/04/2026.
//

import SwiftUI

struct RootView: View {
    
    @State private var showSignInView: Bool = false
    @AppStorage("studius_logged_in") private var isLoggedIn = false
    var body: some View {
        
        ZStack{
            ContentView(showSignInView: $showSignInView)
        }
        
        .onAppear{
            let authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
            // The local flag is used for the demo login, while Firebase is used when it is available.
            self.showSignInView = authUser == nil && isLoggedIn == false ? true: false
        }
        .fullScreenCover(isPresented: $showSignInView){
            NavigationStack{
                AuthView(showSignInView: $showSignInView)
            }
            .interactiveDismissDisabled()
            
        }
    }
}

struct RootView_Previews: PreviewProvider{
    static var previews: some View{
        
        RootView()
            .environment(AppDataStore())
    }
}
