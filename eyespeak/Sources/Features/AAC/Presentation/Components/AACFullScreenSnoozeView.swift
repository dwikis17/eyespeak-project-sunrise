//
//  AACFullScreenSnoozeView.swift
//  eyespeak
//
//  Created by Dwiki on 2024/12/19.
//

import SwiftUI

struct AACFullScreenSnoozeView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject private var viewModel: AACViewModel
    
    @State private var unlockActions: [GestureType] = []
    @State private var unlockProgress: [Bool] = []
    @State private var currentStep: Int = 0
    @State private var gestureCheckTimer: Timer?
    
    var body: some View {
        ZStack {
            // Blurred background that subtly reveals underlying content
            Color.black.opacity(1)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                
                Spacer()
                
                // Main content
                VStack(spacing: 20) {
                    // Large orange lock icon
                    Image(systemName: "lock.fill")
                        .font(.system(size: 150, weight: .bold))
                        .foregroundStyle(Color.energeticOrange)
                        .shadow(color: Color.energeticOrange.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // Bold "Snoozed!" text
                    Text("Snoozed!")
                        .font(Typography.boldHeaderJumbo)
                        .foregroundStyle(LinearGradient.orangeGradient)
                    
                    // Instruction text
                    Text("Perform your unlock gesture to continue")
                        .font(Typography.regularTitle)
                        .foregroundStyle(Color.whiteWhite)
                    
                    // Unlock action display
                    VStack(spacing: 12) {
                        Text("Your unlock actions")
                            .font(Typography.boldTitle)
                            .foregroundStyle(Color.whiteWhite)
                        
                        HStack(spacing: 12) {
                            ForEach(Array(unlockActions.enumerated()), id: \.offset) { index, gesture in
                                let isComplete = currentStep > index
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(isComplete ? Color.energeticOrange : Color.blueholder)
                                    .overlay(
                                        Image(systemName: gesture.iconName)
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundStyle(isComplete ? Color.whiteWhite : Color.placeholder)
                                    )
                                    .frame(width: 60, height: 56)
                                    .scaleEffect(unlockProgress.indices.contains(index) && unlockProgress[index] ? 1.08 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: unlockProgress.indices.contains(index) ? unlockProgress[index] : false)
                                    .shadow(color: isComplete ? Color.energeticOrange.opacity(0.35) : .clear, radius: 12, x: 0, y: 6)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.whiteWhite.opacity(0.06))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(LinearGradient.orangeGradient, lineWidth: 2)
                                )
                        )
                    }
                    
                    Text("or")
                        .font(Typography.regularTitle)
                        .foregroundStyle(Color.whiteWhite)
                    
                    // Emergency unlock button
                    Button(action: emergencyUnlock) {
                        Text("Emergency Unlock")
                            .font(Typography.boldTitle)
                            .foregroundStyle(Color.blueack)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.whiteWhite)
                            )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
        }
        .onAppear {
            // Load unlock actions from viewModel
            loadUnlockActions()
            // Setup gesture handling for unlock
            setupGestureHandling()
        }
        .onDisappear {
            // Clean up gesture handling
            cleanupGestureHandling()
        }

    }
    
    private func loadUnlockActions() {
        unlockActions = viewModel.generateSnoozeUnlockActions()
        unlockProgress = Array(repeating: false, count: unlockActions.count)
        currentStep = 0
    }
    
    private func setupGestureHandling() {
        // Start a timer to periodically check for new gestures
        gestureCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [self] _ in
            if let gesture = viewModel.lastDetectedGesture {
                handleUnlockGesture(gesture)
                // Clear the gesture after handling to avoid processing it multiple times
                viewModel.lastDetectedGesture = nil
            }
        }
    }
    
    private func cleanupGestureHandling() {
        // Stop the timer
        gestureCheckTimer?.invalidate()
        gestureCheckTimer = nil
    }
    
    private func handleUnlockGesture(_ gesture: GestureType) {
        guard currentStep < unlockActions.count else {
            resetUnlockSequence()
            return
        }
        
        if gesture == unlockActions[currentStep] {
            // Mark this step as completed
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                if unlockProgress.indices.contains(currentStep) {
                    unlockProgress[currentStep] = true
                }
            }
            
            // Move to next step
            currentStep += 1
            
            // If all steps completed, unlock
            if currentStep == unlockActions.count {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isPresented = false
                    }
                }
            }
        } else {
            // Wrong gesture - reset sequence
            resetUnlockSequence()
        }
    }
    
    private func resetUnlockSequence() {
        withAnimation {
            unlockProgress = Array(repeating: false, count: unlockActions.count)
            currentStep = 0
        }
    }
    
    private func emergencyUnlock() {
        // Immediate unlock without gesture sequence
        withAnimation {
            isPresented = false
        }
    }
}

// Blur view for background effect
struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

#if DEBUG
struct AACFullScreenSnoozeView_Previews: PreviewProvider {
    static var previews: some View {
        AACFullScreenSnoozeView(isPresented: .constant(true))
            .environmentObject(AACViewModel(modelContext: AACDIContainer.makePreviewContainer().mainContext))
    }
}
#endif
