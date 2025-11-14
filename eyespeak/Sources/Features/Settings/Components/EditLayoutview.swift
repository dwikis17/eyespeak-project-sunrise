//
//  EditLayoutview.swift
//  eyespeak
//
//  Created by Dwiki on 07/11/25.
//

import SwiftUI

struct EditLayoutview: View {
    @EnvironmentObject private var viewModel: AACViewModel
    
    var body: some View {
        HStack {
            VStack(alignment:.leading, spacing: 15) {
                Text("Edit Layout")
                    .font(Typography.boldHeader)
                Text("Customize your own AAC Board Layout")
                    .font(Typography.regularTitle)
                    .foregroundStyle(Color.placeholder)
               
                VStack {
                    if let editLayoutCombo = viewModel.settings.editLayoutCombo {
                        NavigationCard(
                            title: "Edit Layout",
                            background: .mellowBlue,
                            cornerRadius: 22,
                            firstCombo: editLayoutCombo.0,
                            secondCombo: editLayoutCombo.1
                        ) {
                            viewModel.toggleEditMode()
                            viewModel.onNavigateToAAC?()

                        }
                    } else {
                        NavigationCard(
                            title: "Edit Layouts",
                            background: .mellowBlue,
                            cornerRadius: 22,
                            firstCombo: nil,
                            secondCombo: nil
                        ) {
                            viewModel.toggleEditMode()
                        }
                    }
                }
                .frame(width: 200)
                
            }
            Spacer()
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
    
    EditLayoutview()
        .environmentObject(vm)
    
}
