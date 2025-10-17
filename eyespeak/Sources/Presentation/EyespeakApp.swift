import SwiftUI

@main
struct EyespeakApp: App {
    @State private var appState = AppStateManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
        }
    }
}
