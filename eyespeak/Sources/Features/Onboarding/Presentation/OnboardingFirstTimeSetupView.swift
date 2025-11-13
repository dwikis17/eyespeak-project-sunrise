import SwiftUI
import AudioToolbox
import ARKit

struct OnboardingFirstTimeSetupView: View {
    var onContinue: () -> Void
    var totalSteps: Int
    var currentStep: Int
    @State private var faceStatus = FaceStatus()
    @State private var playedBlinkStartCue = false
    @State private var trackingEnabled = true

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 16) {
                OnboardingCardContainer {
                    HStack(alignment: .center, spacing: 20) {
                        // Left: Header, description, dots, CTA (centered column)
                        VStack(alignment: .center, spacing: 16) {
                            Spacer()

                            WelcomeHeaderView(
                                title: "First Time Setup",
                                subtitle: "We need to learn about you",
                                alignment: .center,
                                titleSize: 72,
                                subtitleSize: 32
                            )

                            Text("Since this is your first time, we'll use **Switch Scanning** to help you select which actions work for you")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            ProgressDotsView(current: currentStep, total: totalSteps, dotSize: 12, spacing: 8)
                                .frame(maxWidth: .infinity)

                            Spacer()

                            BlinkHoldCTAView(title: "Blink and hold to continue", action: {
                                trackingEnabled = false
                                AudioServicesPlaySystemSound(1057)
                                onContinue()
                            }, background: Color(.systemGray5), foreground: .black, cornerRadius: 20, height: 120, textSize: 22, iconSize: 24)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 24)

                        // Right: Animated steps column from OnboardingSelectionAnimationView
                        OnboardingSelectionAnimationView()
                            .frame(width: 500)
                            .frame(maxHeight: .infinity, alignment: .center)
                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: geo.size.height - 40)
            }
            .padding(20)
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color(.systemGroupedBackground))
        .overlay(
            Group {
                if trackingEnabled {
                    AACFaceTrackingView(
                        status: $faceStatus,
                        onEyesClosed: {
                            trackingEnabled = false
                            AudioServicesPlaySystemSound(1057)
                            onContinue()
                        },
                        eyesClosedDuration: 1.5
                    )
                    .frame(width: 1, height: 1)
                    .allowsHitTesting(false)
                    .opacity(0.01)
                }
            }
        )
        .onDisappear { trackingEnabled = false }
        .onChange(of: faceStatus.leftBlink) { newVal in
            if newVal && !playedBlinkStartCue {
                AudioServicesPlaySystemSound(1057)
                playedBlinkStartCue = true
            } else if !faceStatus.leftBlink && !faceStatus.rightBlink {
                playedBlinkStartCue = false
            }
        }
        .onChange(of: faceStatus.rightBlink) { newVal in
            if newVal && !playedBlinkStartCue {
                AudioServicesPlaySystemSound(1057)
                playedBlinkStartCue = true
            } else if !faceStatus.leftBlink && !faceStatus.rightBlink {
                playedBlinkStartCue = false
            }
        }
    }
}

#Preview {
    OnboardingFirstTimeSetupView(onContinue: {}, totalSteps: 3, currentStep: 1)
}
