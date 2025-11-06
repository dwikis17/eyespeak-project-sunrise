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
                MainContentView(
                    container: container ?? AACDIContainer.shared
                )
                .onAppear {
                    bindableAppState.checkOnboardingStatus(modelContext: modelContext)
                }
            }
        }
    }
}

// MARK: - Main Content View with HStack Layout

private struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStateManager.self) private var appState
    private let container: AACDIContainer
    @StateObject private var aacViewModel: AACViewModel
    
    init(container: AACDIContainer) {
        self.container = container
        self._aacViewModel = StateObject(wrappedValue: container.makeAACViewModel())
    }
    
    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 0) {
                // InformationView on the left
                InformationView()
                    .frame(width: geo.size.width * 0.21, height: geo.size.height)
                    .padding()
                
                Spacer()
                
                // Main content on the right - changes based on current tab
                Group {
                    switch appState.currentTab {
                    case .aac:
                        CardGridView()
                            .frame(width: geo.size.width * 0.75, height: geo.size.height)
                    
                    case .settings:
                        SettingsView()
                            .frame(width: geo.size.width * 0.75, height: geo.size.height)
                    
                    case .keyboard:
                        KeyboardView()
                            .frame(width: geo.size.width * 0.75, height: geo.size.height)
                    
                    case .eyeTrackingAccessible, .eyeTrackingSimple:
                        // Legacy tabs - default to AAC
                        CardGridView()
                            .frame(width: geo.size.width * 0.75, height: geo.size.height)
                    }
                }
            }
            .padding(.horizontal)
        }
        .environmentObject(aacViewModel)
        .onAppear {
            // Wire up settings navigation callback
            aacViewModel.onNavigateToSettings = {
                appState.currentTab = .settings
            }
            // Set initial menu
            aacViewModel.setCurrentMenu(appState.currentTab)
        }
        .onChange(of: appState.currentTab) { oldTab, newTab in
            // Reload combos when tab changes
            aacViewModel.setCurrentMenu(newTab)
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
