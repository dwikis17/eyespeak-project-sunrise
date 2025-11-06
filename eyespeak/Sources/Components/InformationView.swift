import SwiftUI

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
                .frame(maxHeight: 191) // Stretches the HStack
            } else {
                gestureModePlaceholder
            }
            controlPanelSection
            LegendsView()
        }
    }

    private var controlPanelSection: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            // Settings button with optional combo badge
            if let settingsCombo = viewModel.settings.settingsCombo {
                NavigationCard(
                    title: "Settings",
                    background: .mellowBlue,
                    cornerRadius: 22,
                    firstCombo: settingsCombo.0.iconName,
                    secondCombo: settingsCombo.1.iconName
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
                .frame(maxHeight: .infinity)

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
                    ForEach(Array(viewModel.recentCombos.prefix(3).enumerated()), id: \.offset) { _, pair in
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
