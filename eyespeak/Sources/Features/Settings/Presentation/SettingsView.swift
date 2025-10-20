//
//  SettingsView.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Input") {
                    NavigationLink("Combo Input (ARKit)") {
                        ComboInputSettingsView()
                    }
                    NavigationLink("ARKit Face Test") {
                        ARKitFaceTestView()
                    }
                }

                Section("App Settings") {
                    SettingsSliders()
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct SettingsSliders: View {
    @Environment(AppStateManager.self) private var appState

    var body: some View {
        let settings = appState.settings
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                Text("Timer Speed: \(settings.timerSpeed, specifier: "%.1f")s")
                Slider(value: Binding(
                    get: { settings.timerSpeed },
                    set: { settings.timerSpeed = $0 }
                ), in: 0.5...10, step: 0.5)
            }

            VStack(alignment: .leading) {
                Text("Font Size: \(settings.fontSize, specifier: "%.0f")pt")
                Slider(value: Binding(
                    get: { settings.fontSize },
                    set: { settings.fontSize = $0 }
                ), in: 10...36, step: 1)
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppStateManager())
}
