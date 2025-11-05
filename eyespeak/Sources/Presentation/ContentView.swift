import SwiftUI
import SwiftData

public struct ContentView: View {
    @Environment(AppStateManager.self) private var appState
    @Environment(\.modelContext) private var modelContext
    private let container: AACDIContainer?
    
    public init(container: AACDIContainer? = nil) {
        self.container = container
    }

    
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
                    AACView(container: container ?? AACDIContainer.shared)
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
                .tabViewStyle(.page(indexDisplayMode: .never)) // ✅ hides tab bar
                .onAppear {
                    bindableAppState.checkOnboardingStatus(modelContext: modelContext)
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let modelContainer = ModelContainer.preview
        let di = AACDIContainer.makePreviewDI(modelContainer: modelContainer)
        return ContentView(container: di)
            .environment(AppStateManager())
            .modelContainer(modelContainer)
    }
}
