//
//  SettingsView.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AACViewModel
    @State private var testButtonCombo: ActionCombo?
    @State private var showingComboPicker = false
    @State private var buttonTriggered = false
    
    
    var body: some View {
        VStack(spacing:15) {
            headerView
            AvailableActionsView()
            EditLayoutview()
            Spacer()
        }
    
    }
//    var body: some View {
//        NavigationStack {
//            List {
//                Section("Input") {
//                    NavigationLink("Combo Input (ARKit)") {
//                        ComboInputSettingsView()
//                    }
//                    NavigationLink("ARKit Face Test") {
//                        ARKitFaceTestView()
//                    }
//                }
//
//                Section("App Settings") {
//                    SettingsSliders()
//                }
//                
//                Section("Test Button") {
//                    VStack(alignment: .leading, spacing: 12) {
//                        // Display assigned combo
//                        if let combo = testButtonCombo {
//                            HStack {
//                                Text("Assigned Combo:")
//                                    .foregroundColor(.secondary)
//                                Spacer()
//                                HStack(spacing: 8) {
//                                    Image(systemName: combo.firstGesture.iconName)
//                                        .font(.title3)
//                                    Image(systemName: "arrow.right")
//                                        .font(.caption)
//                                    Image(systemName: combo.secondGesture.iconName)
//                                        .font(.title3)
//                                }
//                            }
//                        } else {
//                            Text("No combo assigned")
//                                .foregroundColor(.secondary)
//                        }
//                        
//                        // Button to assign combo
//                        Button(action: {
//                            showingComboPicker = true
//                        }) {
//                            Text(testButtonCombo == nil ? "Assign Combo" : "Change Combo")
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(10)
//                        }
//                        
//                        // The actual test button
//                        Button(action: {
//                            buttonTriggered = true
//                            print("✅ Test Button Pressed!")
//                            // Reset after a short delay
//                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                                buttonTriggered = false
//                            }
//                        }) {
//                            HStack {
//                                Spacer()
//                                Text(buttonTriggered ? "Button Triggered! ✅" : "Test Button")
//                                    .font(.headline)
//                                Spacer()
//                            }
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(buttonTriggered ? Color.green : Color.gray.opacity(0.2))
//                            .foregroundColor(buttonTriggered ? .white : .primary)
//                            .cornerRadius(10)
//                        }
//                        .disabled(testButtonCombo == nil && !buttonTriggered)
//                    }
//                    .padding(.vertical, 8)
//                }
//            }
//        }
//        .onAppear {
//            // Load saved combo if exists
//            let settingsCombos = viewModel.getCombosForMenu(.settings)
//            if let (combo, _) = settingsCombos.first(where: { $0.value == 1 }) {
//                testButtonCombo = combo
//            }
//        }
//        .onChange(of: viewModel.menuActionTrigger) { oldValue, newValue in
//            // React to menu action triggers
//            if let trigger = newValue, trigger.menu == "settings" && trigger.actionId == 1 {
//                print("🎯 Settings combo triggered -> Button Action")
//                buttonTriggered = true
//                print("✅ Test Button Pressed via Combo!")
//                // Reset after a short delay
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//                    buttonTriggered = false
//                }
//            }
//        }
//        .sheet(isPresented: $showingComboPicker) {
//            ComboPickerView(selectedCombo: $testButtonCombo) { combo in
//                // Assign combo to Settings menu action ID 1
//                viewModel.assignComboToMenu(combo, menu: .settings, actionId: 1)
//                testButtonCombo = combo
//            }
//        }
//    }
    
    
    
    private var headerView: some View {
        HStack {
            Text("SETTINGS")
                .font(AppFont.Montserrat.bold(15))
                .foregroundStyle(Color.mellowBlue)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
    }
}

// MARK: - Combo Picker View

struct ComboPickerView: View {
    @EnvironmentObject private var viewModel: AACViewModel
    @Binding var selectedCombo: ActionCombo?
    var onComboSelected: (ActionCombo) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                let allCombos = viewModel.fetchAllActionCombos()
                ForEach(allCombos, id: \.id) { combo in
                    Button(action: {
                        selectedCombo = combo
                        onComboSelected(combo)
                        dismiss()
                    }) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: combo.firstGesture.iconName)
                                Image(systemName: "arrow.right")
                                Image(systemName: combo.secondGesture.iconName)
                            }
                            .font(.title3)
                            Text(combo.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedCombo?.id == combo.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Combo")
            .navigationBarTitleDisplayMode(.inline)
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
    let container = AACDIContainer.makePreviewContainer()
    let vm = AACViewModel(
        modelContext: container.mainContext,
        dataManager: DataManager(modelContext: container.mainContext),
        gestureInputManager: GestureInputManager(),
        speechService: SpeechService.shared
    )
    
    SettingsView()
        .environment(AppStateManager())
        .environmentObject(vm)
}
