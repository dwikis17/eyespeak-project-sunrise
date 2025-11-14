import SwiftData
import SwiftUI

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
                        bindableAppState.checkOnboardingStatus(
                            modelContext: modelContext
                        )
                    }
            } else {
                MainContentView(
                    container: container ?? AACDIContainer.shared
                )
                .onAppear {
                    bindableAppState.checkOnboardingStatus(
                        modelContext: modelContext
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.boneWhite)
        .ignoresSafeArea()
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
        self._aacViewModel = StateObject(
            wrappedValue: container.makeAACViewModel()
        )
    }

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 0) {
               InformationView()
                    .frame(
                        width: geo.size.width * 0.22,
                        height: geo.size.height - 60
                    )
        
                    .padding()
                Spacer()
                Group {
                    switch appState.currentTab {
                    case .aac:
                        CardGridView()
                            .frame(
                                width: geo.size.width * 0.73,
                                height: geo.size.height
                            )

                    case .settings:
                        SettingsView()
                            .frame(
                                width: geo.size.width * 0.72,
                                height: geo.size.height
                            )

                    case .keyboard:
                        KeyboardUIView()
                            .frame(
                                width: geo.size.width * 0.72,
                                height: geo.size.height
                            )

                    case .eyeTrackingAccessible, .eyeTrackingSimple:
                        // Legacy tabs - default to AAC
                        CardGridView()
                            .frame(
                                width: geo.size.width * 0.75,
                                height: geo.size.height
                            )
                    }
                }
            }
            .padding()
            .background(Color.boneWhite)
            .ignoresSafeArea()
        }
        .environmentObject(aacViewModel)
        .onAppear {
            // Wire up navigation callbacks
            aacViewModel.onNavigateToSettings = {
                appState.currentTab = .settings
            }
            aacViewModel.onNavigateToAAC = {
                appState.currentTab = .aac
            }
            aacViewModel.onNavigateToKeyboard = {
                appState.currentTab = .keyboard
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
        let defaultAppState = AppStateManager()
        let keyboardAppState = AppStateManager()
        keyboardAppState.currentTab = .keyboard
        let settingsAppState = AppStateManager()
        settingsAppState.currentTab = .settings

        return Group {
            ContentView(container: di)
                .environment(defaultAppState)
                .modelContainer(modelContainer)
                .previewDisplayName("AAC")

            ContentView(container: di)
                .environment(keyboardAppState)
                .modelContainer(modelContainer)
                .previewDisplayName("Keyboard")

            ContentView(container: di)
                .environment(settingsAppState)
                .modelContainer(modelContainer)
                .previewDisplayName("Settings")
        }
    }
}
