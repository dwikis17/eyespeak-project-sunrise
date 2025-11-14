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
    @AppStorage("fontScale") private var fontScaleRaw: String = "medium"

    var body: some View {
        Group {
            if viewModel.isEditActionsMode {
                EditActionsView()
                    .environmentObject(viewModel)
                    .id(fontScaleRaw)
            } else {
                VStack(spacing: 15) {
                    headerView
                        .id("\(fontScaleRaw)-header")
                    ResetTimerView()
                        .id("\(fontScaleRaw)-reset")
                    TextSizeSettingView()
                        .id("\(fontScaleRaw)-textsize")
                    AvailableActionsView()
                        .id("\(fontScaleRaw)-available")
                    EditLayoutview()
                        .id("\(fontScaleRaw)-editlayout")
                    Spacer()
                }
                .padding(.vertical, 20)
                .environmentObject(viewModel)
            }
        }
        .onAppear {
            self.viewModel.fetchAllUserGestures()
            // Generate edit actions combos if not already generated
            if viewModel.getCombosForMenu(.settings).isEmpty {
                viewModel.generateEditActionsCombos()
            }
        }
        .onChange(of: viewModel.menuActionTrigger) { oldValue, newValue in
            handleMenuAction(newValue)
        }
    }
    
    private func handleMenuAction(_ trigger: MenuActionTrigger?) {
        guard let trigger = trigger else { return }
        
        if trigger.menu == "settings" && trigger.actionId == 0 {
            // Action ID 0: Enter edit actions mode
            viewModel.isEditActionsMode = true
            // Reload combos for edit actions mode
            viewModel.reloadCombosForCurrentMenu()
        }
    }

    private var headerView: some View {
        HStack {
            Text("SETTINGS")
                .font(Typography.boldHeader)
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
                Slider(
                    value: Binding(
                        get: { settings.timerSpeed },
                        set: { settings.timerSpeed = $0 }
                    ),
                    in: 0.5...10,
                    step: 0.5
                )
            }

            VStack(alignment: .leading) {
                Text("Font Size: \(settings.fontSize, specifier: "%.0f")pt")
                Slider(
                    value: Binding(
                        get: { settings.fontSize },
                        set: { settings.fontSize = $0 }
                    ),
                    in: 10...36,
                    step: 1
                )
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
