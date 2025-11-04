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
                        GestureIndicatorBadge(combo: combo)
                    }
                    Spacer()
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onTapGesture {
            handleCardTap()
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
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: combo.firstGesture.iconName)
                .font(.caption2)
            Image(systemName: "arrow.right")
                .font(.system(size: 8))
            Image(systemName: combo.secondGesture.iconName)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.8))
        )
        .foregroundColor(.white)
        .padding(8)
    }
}

#Preview("Card Cell with Highlight") {
    let container = AACDIContainer.makePreviewContainer()
    let viewModel = AACDIContainer.shared.makeAACViewModel()
    let position = try! container.mainContext.fetch(FetchDescriptor<GridPosition>()).first!
    
    return CardCell(
        position: position,
        dataManager: viewModel.dataManager,
        columns: 3,
        isHighlighted: true,
        viewModel: viewModel
    )
    .frame(width: 150, height: 150)
    .padding()
    .modelContainer(container)
}
