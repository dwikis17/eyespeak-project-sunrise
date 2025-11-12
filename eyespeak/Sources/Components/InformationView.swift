import SwiftUI
import UIKit

// Reusable Card wrapper
struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()  // internal padding for content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
            )
            .fixedSize(horizontal: false, vertical: false)  // important: allow card to fit its content height
    }
}

struct InformationView: View {
    @EnvironmentObject private var viewModel: AACViewModel
    @Environment(AppStateManager.self) private var appState

    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 15) {
            currentInputSection
            if viewModel.isGestureMode {
                GeometryReader { geo in
                    HStack(alignment: .top, spacing: 15) {
                        AACFaceTrackingPanel()
                            .frame(maxWidth: .infinity)

                        lastInputSection
                            .frame(width: 112)
                            .frame(maxHeight: .infinity)
                    }

                }
                .frame(maxHeight: 191)  // Stretches the HStack
            } else {
                gestureModePlaceholder
            }
            if viewModel.isEditMode {
                editView
            } else {
                controlPanelSection
            }
            LegendsView()
        }
    }

    private var controlPanelSection: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            // Settings button with optional combo badge
            if viewModel.currentMenu != .settings {
                if let settingsCombo = viewModel.settings.settingsCombo {
                    NavigationCard(
                        title: "Settings",
                        background: .mellowBlue,
                        cornerRadius: 22,
                        firstCombo: settingsCombo.0,
                        secondCombo: settingsCombo.1
                    ) {
                        // action closure
                        appState.currentTab = .settings
                    }
                } else {
                    // no combo configured — keep same visual but without pill
                    NavigationCard(
                        title: "Settings",
                        background: .mellowBlue,
                        cornerRadius: 22,
                        firstCombo: nil,
                        secondCombo: nil
                    ) {
                        appState.currentTab = .settings
                    }
                }
            } else {
                if let settingsCombo = viewModel.settings.settingsCombo {
                    NavigationCard(
                        title: "AAC Board",
                        background: .mellowBlue,
                        cornerRadius: 22,
                        firstCombo: settingsCombo.0,
                        secondCombo: settingsCombo.1
                    ) {
                        // action closure
                        appState.currentTab = .aac
                    }
                } else {
                    // no combo configured — keep same visual but without pill
                    NavigationCard(
                        title: "AAC Board",
                        background: .mellowBlue,
                        cornerRadius: 22,
                        firstCombo: nil,
                        secondCombo: nil
                    ) {
                        appState.currentTab = .aac
                    }
                }
            }
            // Calibrate card
            NavigationCard(
                title: "Calibrate",
                background: .mellowBlue,
                cornerRadius: 22,
                firstCombo: nil,
                secondCombo: nil
            ) {
                viewModel.toggleCalibration()
            }
        }
    }

    private var currentInputSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("CURRENT INPUT")
                    .font(Typography.boldTitle)
                    .foregroundColor(.primary)

                Divider()

                // Inner gradient card with live last-input icons
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient.orangeGradient)
                        .shadow(
                            color: .black.opacity(0.08),
                            radius: 6,
                            x: 0,
                            y: 3
                        )

                    // Show up to last two gestures as large, white icons
                    HStack(spacing: 28) {
                        ForEach(
                            Array(
                                viewModel.gestureInputManager.gestureSequence
                                    .enumerated()
                            ),
                            id: \.offset
                        ) { _, gesture in
                            Image(systemName: gesture.iconName)
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(
                                    color: .black.opacity(0.12),
                                    radius: 4,
                                    x: 0,
                                    y: 2
                                )
                        }
                    }
                }
                .frame(maxHeight: 206)

                // Live countdown bar linked to gesture timing window
                GeometryReader { geo in
                    TimelineView(.periodic(from: .now, by: 0.05)) { context in
                        let fraction = viewModel.gestureInputManager
                            .remainingTimeFraction(referenceDate: context.date)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .frame(height: 6)
                                .foregroundColor(Color(.systemGray5))
                            Capsule()
                                .frame(
                                    width: geo.size.width * fraction,
                                    height: 6
                                )
                                .foregroundColor(
                                    Color(
                                        red: 246 / 255,
                                        green: 146 / 255,
                                        blue: 79 / 255
                                    )
                                )
                        }
                        .animation(.easeOut(duration: 0.1), value: fraction)
                    }
                }
                .frame(height: 20)
            }
        }
    }

    private var lastInputSection: some View {
        Card {
            VStack(alignment: .center, spacing: 12) {
                Text("LAST INPUT")
                    .font(AppFont.Montserrat.bold(13))
                Divider()
                VStack(spacing: 10) {
                    ForEach(
                        Array(viewModel.recentCombos.prefix(3).enumerated()),
                        id: \.offset
                    ) { _, pair in
                        HStack(spacing: 12) {
                            Image(systemName: pair.0.iconName)
                            Image(systemName: pair.1.iconName)
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }

            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    
    private var editView: some View {
        Card {
            VStack(alignment: .center, spacing: 20) {
                HStack {
                    Text("Edit Mode")
                        .font(AppFont.Montserrat.bold(13))
                        .foregroundColor(.primary)
                    
                    if viewModel.isSwapMode {
                        Spacer()
                        Text("SWAP MODE")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                
                Divider()
                
                if viewModel.isSwapMode {
                    // Swap mode: show first selected card and waiting message
                    VStack(spacing: 12) {
                        selectedCardView
                        Text("Select second card to swap")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                        
                        Button("Cancel Swap") {
                            viewModel.cancelSwapMode()
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                    }
                } else {
                    HStack(alignment: .center, spacing: 15) {
                        // Selected Item (Left)
                        VStack(spacing: 8) {
                            selectedCardView
                            Text("Selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Connector Arrow (Middle)
                        Image("arrow")
                            .renderingMode(.template)
                            .foregroundColor(.primary)
                        
                        // Edit Options (Right)
                        editOptionsView
                    }
                }
            }
        }
    }
    
    private var selectedCardView: some View {
        Group {
            // In swap mode, show first swap position; otherwise show selected position
            let positionToShow = viewModel.isSwapMode ? viewModel.firstSwapPosition : viewModel.selectedPosition
            
            if let position = positionToShow,
               let card = position.card,
               !card.title.isEmpty {
                // Selected card with content
                CardContentView(
                    card: card,
                    isPressed: false,
                    isHighlighted: false
                )
                .frame(width:103, height:103)
            } else {
                // Default fallback - empty card placeholder
                EmptyCellView()
                    .frame(width:103, height:103)
    
            }
        }
    }
    
    private var editOptionsView: some View {
        VStack(spacing: 10) {
            // Delete button
            editOptionButton(
                icon: "arrow.left",
                title: "Delete",
                combo: viewModel.settings.deleteCombo
            ) {
                // Delete action is handled by combo matching in edit mode
                viewModel.performDeleteAction()
            }
            
            // Swap button
            editOptionButton(
                icon: "questionmark",
                title: "Swap",
                combo: viewModel.settings.swapCombo,
                useDoubleIcon: true
            ) {
                // Swap action is handled by combo matching in edit mode
                if let position = viewModel.selectedPosition {
                    viewModel.performSwapAction()
                }
            }
            
            // Color button
            editOptionButton(
                icon: "arrow.left",
                title: "Color",
                combo: viewModel.settings.changeColorCombo
            ) {
                // TODO: Implement color action
            }
        }
    }
    
    private func editOptionButton(
        icon: String,
        title: String,
        combo: (GestureType, GestureType)?,
        useDoubleIcon: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Combo badge or icon on left
                if let combo = combo {
                    // Show combo badge if combo is provided
                    ComboPill(
                        firstGesture: combo.0,
                        secondGesture: combo.1,
                        foreground: .black,
                        background: Color.customGray,
                        size: CGSize(width: 38.431, height: 21.679),
                        paddingValue: 4.927,
                        iconSize: 11.825,
                        spacing: 4.927,
                        cornerRadius: 64.0517
                    )
                } else if useDoubleIcon {
                    // For Swap button with question marks when no combo is provided
                    HStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: 11.825, weight: .semibold))
                        Image(systemName: icon)
                            .font(.system(size: 11.825, weight: .semibold))
                    }
                    .foregroundColor(.whiteWhite)
                    .padding(4.927)
                    .frame(width: 38.431, height: 21.679)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(64.0517)
                } else {
                    // Single icon fallback
                    Image(systemName: icon)
                        .font(.system(size: 11.825, weight: .semibold))
                        .foregroundColor(.whiteWhite)
                        .padding(4.927)
                        .frame(width: 38.431, height: 21.679)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(64.0517)
                }
                
                // Button title
                Text(title)
                    .font(AppFont.Montserrat.bold(7.4))
                    .foregroundStyle(.white)
    
        
            }
            .frame(maxWidth: 90)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.mellowBlue)
            .cornerRadius(16.44)
           
        }
    }
    
    private var gestureModePlaceholder: some View {
        Card {
            VStack(spacing: 16) {
                Text("Gesture Mode")
                    .font(.headline)
                    .foregroundColor(.primary)

                VStack(spacing: 8) {
                    Text(
                        "Turn on gesture mode to control the grid with your eyes."
                    )
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    HStack(spacing: 40) {
                        Image(systemName: "arrow.left")
                        Image(systemName: "eye")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.blue.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)  // placeholder card stretches horizontally but still fits content height
    }
}

#Preview {
    let modelContainer = AACDIContainer.makePreviewContainer()
    let di = AACDIContainer.makePreviewDI(modelContainer: modelContainer)
    return InformationView()
        .environmentObject(di.makeAACViewModel())
        .environment(AppStateManager())
        .modelContainer(modelContainer)
        .frame(width: 360)
}
