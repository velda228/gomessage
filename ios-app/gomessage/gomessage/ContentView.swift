//
//  ContentView.swift
//  gomessage
//
//  Created by Игорь on 24.08.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var apiService = APIService.shared
    
    var body: some View {
        Group {
            if apiService.isAuthenticated {
                MainTabView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                AuthView()
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.easeInOut(duration: 0.5), value: apiService.isAuthenticated)
    }
}
