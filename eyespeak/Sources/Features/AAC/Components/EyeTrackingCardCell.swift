//
//  EyeTrackingCardCell.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import SwiftUI
import SwiftData

// MARK: - Eye Tracking Card Cell
struct EyeTrackingCardCell: View {
    let position: GridPosition
    let dataManager: DataManager?
    let columns: Int
    let viewModel: AACViewModel
    
    @State private var eyeTrackingState: EyeTrackingState = .idle
    @State private var gazeProgress: Double = 0.0
    @State private var gazeTimer: Timer?
    @State private var activationTimer: Timer?
    @State private var resetTimer: Timer?
    @State private var isPressed = false
    
    // Eye tracking configuration
    private let config = EyeTrackingConfig()
    
    var body: some View {
        ZStack {
            if let card = position.card {
                // Card with eye tracking content
                EyeTrackingCardContentView(
                    card: card,
                    isPressed: isPressed,
                    eyeTrackingState: eyeTrackingState,
                    gazeProgress: gazeProgress
                )
            } else {
                // Empty cell with eye tracking
                EyeTrackingEmptyCellView(
                    eyeTrackingState: eyeTrackingState,
                    gazeProgress: gazeProgress
                )
            }
            
            // Gesture combo indicator
            if let combo = position.actionCombo {
                VStack {
                    HStack {
                        Spacer()
                        GestureIndicatorBadge(combo: combo, badgeColor: position.card?.color)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            handleCardTap()
        }
        .onReceive(NotificationCenter.default.publisher(for: .gazeEntered)) { notification in
            if let cardId = notification.object as? String, cardId == position.card?.id.uuidString {
                handleGazeEntered()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .gazeExited)) { notification in
            if let cardId = notification.object as? String, cardId == position.card?.id.uuidString {
                handleGazeExited()
            }
        }
    }
    
    // MARK: - Gaze Handling
    
    private func handleGazeEntered() {
        resetTimers()
        
        // Start gaze timer
        gazeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            withAnimation(.linear(duration: 0.05)) {
                gazeProgress += 0.05 / config.gazeThreshold
                if gazeProgress >= 1.0 {
                    gazeProgress = 1.0
                    handleGazeThresholdReached()
                }
            }
        }
        
        withAnimation {
            eyeTrackingState = .gazing
        }
    }
    
    private func handleGazeExited() {
        resetTimers()
        
        // Start reset timer
        resetTimer = Timer.scheduledTimer(withTimeInterval: config.resetDelay, repeats: false) { _ in
            withAnimation {
                eyeTrackingState = .idle
                gazeProgress = 0.0
            }
        }
    }
    
    private func handleGazeThresholdReached() {
        gazeTimer?.invalidate()
        
        withAnimation {
            eyeTrackingState = .selected
        }
        
        // Start activation timer
        activationTimer = Timer.scheduledTimer(withTimeInterval: config.activationDelay, repeats: false) { _ in
            handleActivation()
        }
    }
    
    private func handleActivation() {
        guard let card = position.card else { return }
        
        withAnimation {
            eyeTrackingState = .activated
        }
        
        // Execute card action
        viewModel.handleCardTap(for: card)
        
        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation {
                eyeTrackingState = .idle
                gazeProgress = 0.0
            }
        }
    }
    
    private func handleCardTap() {
        guard let card = position.card else { return }
        
        // Manual tap - immediate activation
        resetTimers()
        
        // Visual feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isPressed = true
        }
        
        withAnimation {
            eyeTrackingState = .activated
        }
        
        // Use view model to handle the card tap
        viewModel.handleCardTap(for: card)
        
        // Reset animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                isPressed = false
                eyeTrackingState = .idle
                gazeProgress = 0.0
            }
        }
    }
    
    private func resetTimers() {
        gazeTimer?.invalidate()
        activationTimer?.invalidate()
        resetTimer?.invalidate()
        gazeTimer = nil
        activationTimer = nil
        resetTimer = nil
    }
}

// MARK: - Eye Tracking Card Content View
struct EyeTrackingCardContentView: View {
    let card: AACard
    let isPressed: Bool
    let eyeTrackingState: EyeTrackingState
    let gazeProgress: Double
    
    var body: some View {
        VStack(spacing: 8) {
            // Card image
            if let imageData = card.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 60)
            } else {
                Image(systemName: "questionmark.square.dashed")
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            // Card title
            Text(card.title)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(12)
        .background(backgroundView)
        .scaleEffect(scaleEffect)
        .overlay(overlayView)
        .animation(.spring(response: 0.3), value: eyeTrackingState)
        .animation(.spring(response: 0.3), value: gazeProgress)
    }
    
    private var backgroundView: some View {
        ZStack {
            // Base background
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Gaze progress overlay
            if eyeTrackingState == .gazing {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.blue.opacity(gazeProgress * 0.3))
            }
            
            // Selected state overlay
            if eyeTrackingState == .selected {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.4))
            }
            
            // Activated state overlay
            if eyeTrackingState == .activated {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.orange.opacity(0.6))
            }
        }
    }
    
    private var overlayView: some View {
        ZStack {
            // Base border
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: borderWidth)
            
            // Gaze progress ring
            if eyeTrackingState == .gazing {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(
                            lineWidth: 4,
                            lineCap: .round,
                            dash: [2, 8]
                        )
                    )
                    .opacity(gazeProgress)
            }
            
            // Selection ring
            if eyeTrackingState == .selected {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green, lineWidth: 4)
                    .shadow(color: .green, radius: 8, x: 0, y: 0)
            }
            
            // Activation ring
            if eyeTrackingState == .activated {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange, lineWidth: 6)
                    .shadow(color: .orange, radius: 12, x: 0, y: 0)
            }
        }
    }
    
    private var scaleEffect: CGFloat {
        let baseScale = isPressed ? 0.95 : 1.0
        
        switch eyeTrackingState {
        case .idle:
            return baseScale
        case .gazing:
            return baseScale + (gazeProgress * 0.05)
        case .selected:
            return baseScale + 0.05
        case .activated:
            return baseScale + 0.1
        }
    }
    
    private var borderColor: Color {
        switch eyeTrackingState {
        case .idle:
            return .clear
        case .gazing:
            return .blue
        case .selected:
            return .green
        case .activated:
            return .orange
        }
    }
    
    private var borderWidth: CGFloat {
        switch eyeTrackingState {
        case .idle:
            return 0
        case .gazing:
            return 2
        case .selected:
            return 4
        case .activated:
            return 6
        }
    }
}

// MARK: - Eye Tracking Empty Cell View
struct EyeTrackingEmptyCellView: View {
    let eyeTrackingState: EyeTrackingState
    let gazeProgress: Double
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundColor)
                .overlay(overlayView)
            
            Image(systemName: "plus.circle.dashed")
                .font(.largeTitle)
                .foregroundColor(iconColor)
        }
        .scaleEffect(scaleEffect)
        .animation(.spring(response: 0.3), value: eyeTrackingState)
        .animation(.spring(response: 0.3), value: gazeProgress)
    }
    
    private var backgroundColor: Color {
        switch eyeTrackingState {
        case .idle:
            return Color.gray.opacity(0.1)
        case .gazing:
            return Color.blue.opacity(gazeProgress * 0.2)
        case .selected:
            return Color.green.opacity(0.3)
        case .activated:
            return Color.orange.opacity(0.4)
        }
    }
    
    private var iconColor: Color {
        switch eyeTrackingState {
        case .idle:
            return .gray.opacity(0.3)
        case .gazing:
            return .blue
        case .selected:
            return .green
        case .activated:
            return .orange
        }
    }
    
    private var overlayView: some View {
        ZStack {
            // Gaze progress ring
            if eyeTrackingState == .gazing {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(
                            lineWidth: 3,
                            lineCap: .round,
                            dash: [2, 8]
                        )
                    )
                    .opacity(gazeProgress)
            }
            
            // Selection ring
            if eyeTrackingState == .selected {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green, lineWidth: 3)
                    .shadow(color: .green, radius: 6, x: 0, y: 0)
            }
            
            // Activation ring
            if eyeTrackingState == .activated {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange, lineWidth: 4)
                    .shadow(color: .orange, radius: 8, x: 0, y: 0)
            }
        }
    }
    
    private var scaleEffect: CGFloat {
        switch eyeTrackingState {
        case .idle:
            return 1.0
        case .gazing:
            return 1.0 + (gazeProgress * 0.05)
        case .selected:
            return 1.05
        case .activated:
            return 1.1
        }
    }
}

#Preview("Eye Tracking Card Cell") {
    let modelContainer = AACDIContainer.makePreviewContainer()
    let di = AACDIContainer.makePreviewDI(modelContainer: modelContainer)
    let viewModel = di.makeAACViewModel()
    let position = try! modelContainer.mainContext.fetch(FetchDescriptor<GridPosition>()).first!
    
    return EyeTrackingCardCell(
        position: position,
        dataManager: viewModel.dataManager,
        columns: 3,
        viewModel: viewModel
    )
    .frame(width: 150, height: 150)
    .padding()
    .modelContainer(modelContainer)
}
