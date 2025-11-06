//
//  CardCell.swift
//  eyespeak
//
//  Created by Dwiki on [date]
//

import SwiftUI
import SwiftData

struct CardCell: View {
    let position: GridPosition
    let dataManager: DataManager?
    let columns: Int
    var isHighlighted: Bool = false
    let viewModel: AACViewModel
    
    @State private var isPressed = false
    @State private var wiggleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            if let card = position.card {
                // Card with content
                CardContentView(
                    card: card,
                    isPressed: isPressed,
                    isHighlighted: isHighlighted
                )
            } else {
                // Empty cell
                EmptyCellView()
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
        .rotationEffect(.degrees(viewModel.isEditMode ? wiggleOffset : 0))
        .onTapGesture {
            handleCardTap()
        }
        .onChange(of: viewModel.isEditMode) { oldValue, newValue in
            if newValue {
                startWiggleAnimation()
            } else {
                stopWiggleAnimation()
            }
        }
        .onAppear {
            if viewModel.isEditMode {
                startWiggleAnimation()
            }
        }
    }
    
    private func startWiggleAnimation() {
        // Create a unique delay based on position to create a wave effect
        let delay = Double(position.order % 5) * 0.05
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            // Use a consistent wiggle pattern based on position for better visual effect
            let baseAngle = Double(position.order % 4) * 2.0 - 3.0 // -3, -1, 1, 3 degrees
            withAnimation(
                Animation.easeInOut(duration: 0.1)
                    .repeatForever(autoreverses: true)
            ) {
                wiggleOffset = baseAngle
            }
        }
    }
    
    private func stopWiggleAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            wiggleOffset = 0
        }
    }
    
    private func handleCardTap() {
        guard let card = position.card else { return }
        
        // Visual feedback
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            isPressed = true
        }
        
        // Use view model to handle the card tap
        viewModel.handleCardTap(for: card)
        
        // Reset animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                isPressed = false
            }
        }
    }
}

// MARK: - Card Content View

struct CardContentView: View {
    let card: AACard
    let isPressed: Bool
    var isHighlighted: Bool = false
    
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
                    .foregroundColor(.white)
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isHighlighted ? Color.green.opacity(0.2) : card.color)
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .foregroundStyle(.white)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isHighlighted ? Color.green : (isPressed ? Color.blue : Color.clear),
                    lineWidth: isHighlighted ? 4 : 3
                )
        )
        .animation(.spring(response: 0.3), value: isHighlighted)
    }
}

// MARK: - Empty Cell View

struct EmptyCellView: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray.opacity(0.1))
            .overlay(
                Image(systemName: "plus.circle.dashed")
                    .font(.largeTitle)
                    .foregroundColor(.gray.opacity(0.3))
            )
    }
}

// MARK: - Gesture Indicator Badge

struct GestureIndicatorBadge: View {
    let combo: ActionCombo
    var badgeColor: Color? = nil
    
    var body: some View {
        ComboPill(
            firstGesture: combo.firstGesture,
            secondGesture: combo.secondGesture,
            foreground: badgeColor ?? .mellowBlue,
            background: .whiteWhite,
            size: CGSize(width: 38.431, height: 21.679),
            paddingValue: 4.927,
            iconSize: 11.825,
            spacing: 4.927,
            cornerRadius: 64.0517
        )
        .padding(8)
    }
}

#Preview("Card Cell with Highlight") {
    let modelContainer = AACDIContainer.makePreviewContainer()
    let di = AACDIContainer.makePreviewDI(modelContainer: modelContainer)
    let viewModel = di.makeAACViewModel()
    let position = try! modelContainer.mainContext.fetch(FetchDescriptor<GridPosition>()).first!
    
    return CardCell(
        position: position,
        dataManager: viewModel.dataManager,
        columns: 3,
        isHighlighted: true,
        viewModel: viewModel
    )
    .frame(width: 150, height: 150)
    .padding()
    .modelContainer(modelContainer)
}
