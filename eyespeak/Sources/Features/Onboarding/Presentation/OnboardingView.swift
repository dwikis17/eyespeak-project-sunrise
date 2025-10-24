//
//  OnboardingView.swift
//  eyespeak
//
//  Created by Dwiki on 20/10/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStateManager.self) private var appState
    @State private var viewModel: OnboardingViewModel?
    
    var body: some View {
        Group {
            if let viewModel = viewModel {
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
