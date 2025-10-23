import SwiftUI

public struct ContentView: View {
    @Environment(AppStateManager.self) private var appState
    
    public var body: some View {
        @Bindable var bindableAppState = appState
        
        TabView(selection: $bindableAppState.currentTab) {
            // Keyboard Tab
            KeyboardView()
                .tabItem {
                    Image(systemName: "keyboard")
                    Text("Keyboard")
                }
                .tag(Tab.keyboard)
            
            // AAC Tab
            AACView()
                .tabItem {
                    Image(systemName: "bubble.left.and.bubble.right")
                    Text("AAC")
                }
                .tag(Tab.aac)
            
            // Settings Tab
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape")
                    Text("Settings")
                }
                .tag(Tab.settings)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(AppStateManager())
    }
}
