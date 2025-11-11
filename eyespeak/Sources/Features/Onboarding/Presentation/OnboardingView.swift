//
//  OnboardingView.swift
//  eyespeak
//
//  Created by Dwiki on 20/10/25.
//

import SwiftUI
import AudioToolbox

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStateManager.self) private var appState
    @State private var viewModel: OnboardingViewModel?
    @State private var currentStep: Int = 0
    private let totalSteps: Int = 3
    
    var body: some View {
        Group {
            if currentStep == 0 {
                OnboardingWelcomeView(
                    onContinue: {
                        AudioServicesPlaySystemSound(1057)
                        withAnimation(.spring(response: 0.3)) { currentStep = 1 }
                    },
                    totalSteps: totalSteps,
                    currentStep: currentStep
                )
                .environment(appState)
            } else if currentStep == 1 {
                OnboardingFirstTimeSetupView(
                    onContinue: {
                        AudioServicesPlaySystemSound(1057)
                        withAnimation(.spring(response: 0.3)) { currentStep = 2 }
                    },
                    totalSteps: totalSteps,
                    currentStep: currentStep
                )
                .environment(appState)
            } else if let viewModel = viewModel {
                GestureSelectionView()
                    .environment(appState)
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear {
            // Initialize the view model with the actual modelContext
            viewModel = OnboardingViewModel(modelContext: modelContext)
        }
    }
}

#Preview {
    OnboardingView()
}
