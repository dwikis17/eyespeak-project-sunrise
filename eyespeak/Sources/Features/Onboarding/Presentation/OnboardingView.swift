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
        ZStack {
            if currentStep == 0 {
                OnboardingWelcomeView(
                    onContinue: {
                        AudioServicesPlaySystemSound(1057)
                        withAnimation(.easeInOut(duration: 0.35)) { currentStep = 1 }
                    },
                    totalSteps: totalSteps,
                    currentStep: currentStep
                )
                .environment(appState)
                .transition(.opacity)
                .zIndex(0)
            }
            if currentStep == 1 {
                OnboardingFirstTimeSetupView(
                    onContinue: {
                        AudioServicesPlaySystemSound(1057)
                        // Preload gestures in the background to avoid jank on step 3
                        Task { await viewModel?.loadUserGestures() }
                        withAnimation(.easeInOut(duration: 0.35)) { currentStep = 2 }
                    },
                    totalSteps: totalSteps,
                    currentStep: currentStep
                )
                .environment(appState)
                .transition(.opacity)
                .zIndex(1)
            }
            if let viewModel = viewModel, currentStep >= 2 {
                GestureSelectionView()
                    .environment(appState)
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: currentStep)
        .onAppear {
            // Initialize the view model with the actual modelContext
            viewModel = OnboardingViewModel(modelContext: modelContext)
        }
    }
}

#Preview {
    OnboardingView()
}
