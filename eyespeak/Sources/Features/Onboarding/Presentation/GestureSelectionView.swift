//
//  GestureSelectionView.swift
//  eyespeak
//
//  Created by Dwiki on 20/10/25.
//

import SwiftUI
import SwiftData

struct GestureSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppStateManager.self) private var appState
    @State private var viewModel: OnboardingViewModel?
    @State private var isInitialized = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let viewModel = viewModel {
                    contentView(viewModel: viewModel)
                } else {
                    ProgressView("Loading gestures...")
                }
            }
            .navigationTitle("Select Your Gestures")
            .onAppear {
                initializeViewModel()
            }
        }
    }
    
    @ViewBuilder
    private func contentView(viewModel: OnboardingViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView("Loading...")
        } else if let errorMessage = viewModel.errorMessage {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text(errorMessage)
                    .foregroundColor(.red)
                Button("Retry") {
                    Task {
                        await viewModel.loadUserGestures()
                    }
                }
            }
        } else {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Choose 3-4 gestures you can perform")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("Selected: \(viewModel.getSelectedGestureCount())/4")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Gesture Grid
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(viewModel.userGestures, id: \.id) { userGesture in
                        GestureCard(
                            userGesture: userGesture,
                            isSelected: userGesture.isEnabled,
                            isDisabled: false,
                            onTap: {
                                viewModel.toggleGestureSelection(userGesture)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Continue Button
                Button {
                    Task {
                        do {
                            try await viewModel.saveGestureSelection()
                            // Complete onboarding and return to main app
                            appState.completeOnboarding()
                            print("Onboarding completed successfully!")
                        } catch {
                            print("Failed to save gesture selection: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Text("Continue")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            viewModel.getSelectedGestureCount() >= 2 ? Color.blue : Color.gray
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(viewModel.getSelectedGestureCount() < 2)
                .padding(.horizontal)
            }
        }
    }
    
    private func initializeViewModel() {
        guard !isInitialized else { return }
        isInitialized = true
        
        let viewModel = OnboardingViewModel(modelContext: modelContext)
        self.viewModel = viewModel
        
        Task {
            await viewModel.loadUserGestures()
        }
    }
}

// MARK: - Gesture Card Component

struct GestureCard: View {
    let userGesture: UserGesture
    let isSelected: Bool
    let isDisabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                Image(systemName: userGesture.iconName)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(userGesture.displayName)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.blue : (isDisabled ? Color.gray.opacity(0.3) : Color.blue.opacity(0.3)),
                        lineWidth: isSelected ? 3 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1.0)
    }
}

#Preview {
    GestureSelectionView()
        .modelContainer(ModelContainer.preview)
}
