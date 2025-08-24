import SwiftUI
import Combine

struct MainTabView: View {
    @StateObject private var apiService = APIService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Чаты
            ChatsListView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "message.fill" : "message")
                        .font(.system(size: 20))
                    Text("Чаты")
                }
                .tag(0)
            
            // Профиль
            ProfileView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "person.circle.fill" : "person.circle")
                        .font(.system(size: 20))
                    Text("Профиль")
                }
                .tag(1)
        }
        .accentColor(.blue)
        .onAppear {
            // Настройка внешнего вида TabView
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}



#Preview {
    MainTabView()
}
