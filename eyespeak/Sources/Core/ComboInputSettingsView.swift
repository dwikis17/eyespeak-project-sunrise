import SwiftUI

struct ComboInputSettingsView: View {
    @Environment(AppStateManager.self) private var appState

    var body: some View {
        let settings = appState.settings
        @State var localSettings = settings.comboInputSettings
        Form {
            Section(header: Text("Combo Input")) {
                Toggle("Enabled", isOn: Binding(
                    get: { settings.comboInputSettings.isEnabled },
                    set: { newValue in
                        var s = settings.comboInputSettings
                        s.isEnabled = newValue
                        settings.comboInputSettings = s
                        localSettings = s
                    }
                ))

                Stepper(value: Binding(
                    get: { settings.comboInputSettings.maxCombos },
                    set: { newValue in
                        var s = settings.comboInputSettings
                        s.maxCombos = max(0, newValue)
                        settings.comboInputSettings = s
                        localSettings = s
                    }
                ), in: 0...10) {
                    Text("Max Combos: \(settings.comboInputSettings.maxCombos)")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Sensitivity: \(settings.comboInputSettings.sensitivity, specifier: "%.2f")")
                    Slider(value: Binding(
                        get: { settings.comboInputSettings.sensitivity },
                        set: { newValue in
                            var s = settings.comboInputSettings
                            s.sensitivity = newValue
                            settings.comboInputSettings = s
                            localSettings = s
                        }
                    ), in: 0...1)
                }

                Button(role: .destructive) {
                    settings.comboInputSettings = .defaults
                    localSettings = settings.comboInputSettings
                } label: {
                    Text("Reset to Defaults")
                }
            }
        }
        .navigationTitle("Combo Input")
    }
}

#Preview {
    ComboInputSettingsView()
        .environment(AppStateManager())
}
