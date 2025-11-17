import SwiftUI

/// Tracks blink-and-hold progress for onboarding CTAs and drives the audio cues.
final class BlinkHoldProgressHandler: ObservableObject {
    @Published var progress: CGFloat = 0
    @Published private(set) var isHolding = false

    var onCompleted: (() -> Void)?

    private let holdDuration: CGFloat
    private let tickInterval: CGFloat = 0.01
    private var timer: Timer?
    private var hasCompletedCurrentHold = false
    private var isEnabled = true
    private let soundPlayer: HoldProgressSoundPlayer

    init(duration: CGFloat = 2.0) {
        holdDuration = duration
        soundPlayer = HoldProgressSoundPlayer(duration: TimeInterval(duration))
    }

    func update(eyesClosed: Bool) {
        guard isEnabled else { return }
        if eyesClosed {
            startHoldIfNeeded()
        } else {
            resetHold()
        }
    }

    func completeImmediately() {
        guard isEnabled else { return }
        progress = 1
        completeHold()
        resetHold()
    }

    func disable() {
        isEnabled = false
        resetHold()
    }

    func enable() {
        isEnabled = true
    }

    private func startHoldIfNeeded() {
        guard !isHolding else { return }
        isHolding = true
        soundPlayer.startProgressTone()
        startTimer()
    }

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.handleTick()
        }
    }

    private func handleTick() {
        guard isHolding, !hasCompletedCurrentHold else { return }
        progress = min(1, progress + (tickInterval / holdDuration))
        if progress >= 1 {
            completeHold()
        }
    }

    private func completeHold() {
        guard !hasCompletedCurrentHold else { return }
        hasCompletedCurrentHold = true
        stopTimer()
        soundPlayer.stopProgressTone()
        soundPlayer.playCompletionPop()
        DispatchQueue.main.async { [weak self] in
            self?.onCompleted?()
        }
    }

    private func resetHold() {
        guard progress > 0 || isHolding else { return }
        stopTimer()
        soundPlayer.stopProgressTone()
        progress = 0
        isHolding = false
        hasCompletedCurrentHold = false
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        stopTimer()
        soundPlayer.stopProgressTone()
    }
}
