import SwiftUI
import SwiftData

@main
struct EyespeakApp: App {
    @State private var appState = AppStateManager()

    var body: some Scene {
        WindowGroup {
          ContentView()
                .background(Color.boneWhite.ignoresSafeArea())
        }
        .environment(appState)
        .modelContainer(ModelContainer.shared)
    }
}
