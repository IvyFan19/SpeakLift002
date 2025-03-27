//
//  MainTabView.swift
//  SpeakLiftApp-002
//
//  Created by Trae AI on 3/26/25.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            TopicsView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Topics")
                }
                .tag(1)
            
            BookmarksView()
                .tabItem {
                    Image(systemName: "bookmark.fill")
                    Text("Bookmarks")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
    }
}

#Preview {
    MainTabView()
}