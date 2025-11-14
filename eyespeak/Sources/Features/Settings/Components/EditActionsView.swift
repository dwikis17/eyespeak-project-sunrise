//
//  EditActionsView.swift
//  eyespeak
//
//  Created by Dwiki on 12/11/25.
//

import SwiftUI

struct EditActionsView: View {
    @EnvironmentObject private var viewModel: AACViewModel
    @State private var localGestures: [UserGesture] = []
    @State private var refreshId = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            headerView
            VStack(alignment: .leading, spacing: 15) {
                Text("Available Actions")
                    .font(Typography.boldHeader)
                Text("Select which movements you can do comfortably")
                    .font(Typography.regularTitle)
                    .foregroundStyle(Color.placeholder)
            }
            .padding()

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 15),
                    GridItem(.flexible(), spacing: 15),
                ],
                spacing: 10
            ) {
                ForEach(Array(localGestures.enumerated()), id: \.element.id) {
                    index,
                    gesture in
                    ActionCard(
                        userGesture: gesture,
                        isCompleted: gesture.isEnabled,
                        action: {
                            toggleGesture(at: index)
                        },
                        firstComboGesture: getComboForGesture(at: index).0,
                        secondComboGesture: getComboForGesture(at: index).1
                    )
                }
            }
            .padding(.horizontal)
            .id(refreshId)

            footerView
        }
        .padding(.vertical, 20)
        .onAppear {
            loadGestures()
            // Generate combos if not already generated
            if viewModel.getCombosForMenu(.settings).isEmpty {
                viewModel.generateEditActionsCombos()
            }
        }
        .onChange(of: viewModel.menuActionTrigger) { oldValue, newValue in
            handleMenuAction(newValue)
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("SETTINGS")
                    .font(AppFont.Montserrat.bold(15))
                    .foregroundStyle(Color.mellowBlue)
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        )
        .padding(.horizontal)
    }

    private var footerView: some View {
        HStack {
            NavigationCard(
                title: "BACK",
                background: .mellowBlue,
                cornerRadius: 22,
                firstCombo: getCancelCombo().0,
                secondCombo: getCancelCombo().1,
                height: 51
            ) {
                cancelEdit()
            }
            .frame(width: 200)

            Spacer()

            NavigationCard(
                title: "SAVE",
                background: .mellowBlue,
                cornerRadius: 22,
                firstCombo: getSaveCombo().0,
                secondCombo: getSaveCombo().1,
                height: 51
            ) {
                saveChanges()
            }
            .frame(width: 200)
        }
        .padding(.horizontal)
    }

    private func loadGestures() {
        localGestures = viewModel.fetchAllUserGestures().sorted {
            $0.order < $1.order
        }
    }

    private func toggleGesture(at index: Int) {
        guard index < localGestures.count else { return }
        localGestures[index].isEnabled.toggle()
        // Force view update
        refreshId = UUID()
    }

    private func getComboForGesture(at index: Int) -> (
        GestureType?, GestureType?
    ) {
        // Get combos from viewModel for this gesture index
        // Action IDs: 0 = Edit Actions, 1-12 = gesture toggles, 13 = Cancel, 14 = Save
        let actionId = index + 1
        let combos = viewModel.getCombosForMenu(.settings)

        for (combo, id) in combos where id == actionId {
            return (combo.firstGesture, combo.secondGesture)
        }
        return (nil, nil)
    }

    private func getCancelCombo() -> (GestureType?, GestureType?) {
        let combos = viewModel.getCombosForMenu(.settings)
        for (combo, id) in combos where id == 13 {
            return (combo.firstGesture, combo.secondGesture)
        }
        return (nil, nil)
    }

    private func getSaveCombo() -> (GestureType?, GestureType?) {
        let combos = viewModel.getCombosForMenu(.settings)
        for (combo, id) in combos where id == 14 {
            return (combo.firstGesture, combo.secondGesture)
        }
        return (nil, nil)
    }

    private func handleMenuAction(_ trigger: MenuActionTrigger?) {
        guard let trigger = trigger else { return }

        if trigger.menu == "settings" {
            // Action IDs: 0 = Edit Actions, 1-12 = gesture toggles, 13 = Cancel, 14 = Save
            if trigger.actionId == 13 {
                cancelEdit()
            } else if trigger.actionId == 14 {
                saveChanges()
            } else if trigger.actionId >= 1 && trigger.actionId <= 12 {
                let index = trigger.actionId - 1
                if index < localGestures.count {
                    toggleGesture(at: index)
                    // Force view update
                    refreshId = UUID()
                }
            }
        }
    }

    private func cancelEdit() {
        // Revert changes by reloading from database
        loadGestures()
        viewModel.isEditActionsMode = false
    }

    private func saveChanges() {
        // Save all gesture changes to SwiftData
        for gesture in localGestures {
            try? viewModel.dataManager.updateUserGesture(
                userGesture: gesture,
                isEnabled: gesture.isEnabled
            )
        }

        // Regenerate combos based on new enabled gestures
        viewModel.regenerateCombosForEditActions()

        // Exit edit mode
        viewModel.isEditActionsMode = false
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

    EditActionsView()
        .environmentObject(vm)
}
