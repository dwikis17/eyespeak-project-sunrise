//
//  TextSizeSettingView.swift
//  eyespeak
//
//  Created by Dwiki on 10/11/25.
//

import SwiftUI

struct TextSizeSettingView: View {
    @Environment(AppStateManager.self) private var appState
    @EnvironmentObject private var viewModel: AACViewModel
    @AppStorage("fontScale") private var fontScaleRaw: String = "medium"
    
    private var currentFontScale: FontScale {
        FontScale(rawValue: fontScaleRaw) ?? .medium
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 15) {
                Text("Text Size")
                    .font(Typography.boldHeader)
                Text("Size of the text")
                    .font(Typography.regularTitle)
                    .foregroundStyle(Color.placeholder)
                
                HStack(spacing: 20) {
                    // SMALL card
                    NavigationCard(
                        title: "SMALL",
                        background: .mellowBlue,
                        cornerRadius: 22,
                        isSelected: currentFontScale == .small,
                        firstCombo: appState.settings.fontSmallCombo?.0,
                        secondCombo: appState.settings.fontSmallCombo?.1
                    ) {
                        appState.settings.fontScale = .small
                    }
                    
                    // MEDIUM card
                    NavigationCard(
                        title: "MEDIUM",
                        background: .mellowBlue,
                        cornerRadius: 22,
                        isSelected: currentFontScale == .medium,
                        firstCombo: appState.settings.fontMediumCombo?.0,
                        secondCombo: appState.settings.fontMediumCombo?.1
                    ) {
                        appState.settings.fontScale = .medium
                    }
                    
                    // BIG card
                    NavigationCard(
                        title: "BIG",
                        background: .mellowBlue,
                        cornerRadius: 22,
                        isSelected: currentFontScale == .big,
                        firstCombo: appState.settings.fontBigCombo?.0,
                        secondCombo: appState.settings.fontBigCombo?.1
                    ) {
                        appState.settings.fontScale = .big
                    }
                }
            }
            .frame(maxWidth: 650)
            
            Spacer()
        }
        .onAppear {
            ensureCombosExist()
        }
    }
    
    private func ensureCombosExist() {
        let settings = appState.settings
        let allCombos = viewModel.fetchAllActionCombos()
        print(settings.fontSmallCombo,"smallcomb")
        
        // Ensure fontSmallCombo exists
        if settings.fontSmallCombo == nil {
            // Try decrementTimerCombo first
            if let decrementCombo = settings.decrementTimerCombo {
                settings.fontSmallCombo = decrementCombo
            } else if let firstCombo = allCombos.first {
                settings.fontSmallCombo = (firstCombo.firstGesture, firstCombo.secondGesture)
            }
        }
        
        // Ensure fontMediumCombo exists
        if settings.fontMediumCombo == nil {
            // Try settingsCombo first
            if let settingsCombo = settings.settingsCombo {
                settings.fontMediumCombo = settingsCombo
            } else if let firstCombo = allCombos.first {
                settings.fontMediumCombo = (firstCombo.firstGesture, firstCombo.secondGesture)
            }
        }
        
        // Ensure fontBigCombo exists
        if settings.fontBigCombo == nil {
            // Try incrementTimerCombo first
            if let incrementCombo = settings.incrementTimerCombo {
                settings.fontBigCombo = incrementCombo
            } else if let firstCombo = allCombos.first {
                settings.fontBigCombo = (firstCombo.firstGesture, firstCombo.secondGesture)
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
    
    TextSizeSettingView()
        .environment(AppStateManager())
        .environmentObject(vm)
}

