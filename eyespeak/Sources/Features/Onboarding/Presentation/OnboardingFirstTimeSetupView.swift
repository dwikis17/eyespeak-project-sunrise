import SwiftUI
import AudioToolbox
import ARKit

struct OnboardingFirstTimeSetupView: View {
    var onContinue: () -> Void
    var totalSteps: Int
    var currentStep: Int
    @State private var faceStatus = FaceStatus()
    @State private var playedBlinkStartCue = false

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .top, spacing: 20) {
                // Main intro card
                OnboardingCardContainer {
                    VStack(alignment: .leading, spacing: 16) {
                        WelcomeHeaderView(
                            title: "First Time Setup",
                            subtitle: "We need to learn about you"
                        )

                        Text("Since this is your first time, we’ll guide you through Blink Scanning — a simple way to help your device understand your movement. Don’t worry, this is quick and easy.")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        ProgressDotsView(current: currentStep, total: totalSteps)
                    }
                }

                // Right column - sample steps/items (original UI)
                VStack(spacing: 12) {
                    OnboardingInfoTile(
                        icon: "arrow.right",
                        title: "Look Right",
                        subtitle: "Select when you look toward your right"
                    )
                    OnboardingInfoTile(
                        icon: "arrow.left",
                        title: "Look Left",
                        subtitle: "Select when you look toward your left"
                    )
                    OnboardingInfoTile(
                        icon: "arrow.up",
                        title: "Look Up",
                        subtitle: "Select when you look upward"
                    )
                }
                .frame(width: 320)
            }

            BlinkHoldCTAView(action: {
                // First cue: simulate blink start when button tapped
                AudioServicesPlaySystemSound(1057)
                onContinue() // Second cue handled by parent during page change
            })
        }
        .padding(24)
        .overlay(
            AACFaceTrackingView(
                status: $faceStatus,
                onEyesClosed: {
                    AudioServicesPlaySystemSound(1057)
                    onContinue()
                },
                eyesClosedDuration: 3.0
            )
            .frame(width: 1, height: 1)
            .allowsHitTesting(false)
            .opacity(0.01)
        )
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