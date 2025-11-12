//
//  ActionCard.swift
//  eyespeak
//
//  Created by Dwiki on 12/11/25.
//

import SwiftUI

struct ActionCard: View {
    let userGesture: UserGesture

    var background: Color = .whiteWhite
    var cornerRadius: CGFloat = 20
    var height: CGFloat = 100.72

    // Optional description text (defaults to gesture display name if not provided)
    var description: String? = nil

    // Optional completion status (defaults to userGesture.isEnabled)
    var isCompleted: Bool? = nil

    // Optional tap action
    var action: (() -> Void)? = nil

    // Optional combo gestures to display
    var firstComboGesture: GestureType? = nil
    var secondComboGesture: GestureType? = nil

    private var resolvedDescription: String {
        description ?? getDescription(for: userGesture.gestureType)
    }

    private var resolvedIsCompleted: Bool {
        isCompleted ?? userGesture.isEnabled
    }

    private func getDescription(for gesture: GestureType) -> String {
        switch gesture {
        case .lookLeft: return "Look away from the screen toward your left side"
        case .lookRight: return "Look away from the screen toward your right side"
        case .lookUp: return "Look away from the screen toward your up side"
        case .lookDown: return "Look away from the screen toward your down side"
        case .winkLeft: return "Close your left eye briefly"
        case .winkRight: return "Close your right eye briefly"
        case .blink: return "Blink both eyes"
        case .mouthOpen: return "Open your mouth"
        case .raiseEyebrows: return "Raise your eyebrows"
        case .lipPuckerLeft: return "Pucker your lips to the left"
        case .lipPuckerRight: return "Pucker your lips to the right"
        case .smile: return "Smile"
        }
    }

    @ViewBuilder
    private func gestureIcon(for gesture: GestureType, iconSize: CGFloat)
        -> some View
    {
        if let assetName = gesture.legendAssetName {
            Image(assetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
        } else {
            Image(systemName: gesture.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
        }
    }

    @ViewBuilder
    private var contentBody: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(background)
                .frame(height: height)
            
            HStack(spacing: 10) {
                // Left section: Gradient background with large icon
                ZStack {
                    LinearGradient.orangeGradient

                    gestureIcon(for: userGesture.gestureType, iconSize: 40)
                        .foregroundStyle(.white)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    if let first = firstComboGesture, let second = secondComboGesture {
                        OutlineComboPill(firstGesture: first, secondGesture: second)
                    }
    
                    Text(userGesture.displayName)
                        .font(Typography.boldHeader)
                    Text(resolvedDescription)
                        .lineLimit(2)
                        .font(Typography.regularTitle)
                }

                .frame(minHeight: 90)

            
                Spacer()

                if resolvedIsCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.oldHulkGreen)
                        .font(.system(size: 30))
                        .frame(width: 30, height: 30)
                } else {
                Circle()
                    .stroke(Color.placeholder, lineWidth: 1)
                    .frame(width: 30, height: 30)
                }
                
            }
            .padding(8)
            .frame(height: height)
          
        }
        .clipShape(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        )
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
        .frame(width:462)
    }

    var body: some View {
        // If an action is provided, make the entire card tappable via Button
        if let action = action {
            Button(action: action) {
                contentBody
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            contentBody
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ActionCard(
            userGesture: UserGesture(
                gestureType: .lookRight,
                isEnabled: true,
                order: 0
            ),
            description: "Look away"
        )

        ActionCard(
            userGesture: UserGesture(
                gestureType: .lookUp,
                isEnabled: false,
                order: 1
            )
        )
    }
    .padding()
}
