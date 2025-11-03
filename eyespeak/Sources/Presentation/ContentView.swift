import SwiftUI
import SwiftData

public struct ContentView: View {
    @Environment(AppStateManager.self) private var appState
    @Environment(\.modelContext) private var modelContext

    
    public var body: some View {
        @Bindable var bindableAppState = appState
        
        Group {
            if bindableAppState.showOnboarding {
                OnboardingView()
                    .onAppear {
                        bindableAppState.checkOnboardingStatus(modelContext: modelContext)
                    }
            } else {
                TabView(selection: $bindableAppState.currentTab) {
                    // Keyboard Tab
                    Text("Keyboard View")
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
                       
                        }
                        .tag(Tab.settings)
//                    
//                    ARKitFaceTestView()
//                        .tabItem {
//                            Image(systemName:"camera.fill")
//                        }
                }
                .onAppear {
                    bindableAppState.checkOnboardingStatus(modelContext: modelContext)
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(AppStateManager())
            .modelContainer(ModelContainer.preview)
    }
}
