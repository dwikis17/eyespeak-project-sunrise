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
    private var didCompleteHold = false
    private var releaseTimer: Timer?
    private let releaseGraceDuration: TimeInterval = 0.15

    init(duration: CGFloat = 2.0) {
        holdDuration = duration
        soundPlayer = HoldProgressSoundPlayer(duration: TimeInterval(duration))
    }

    func update(eyesClosed: Bool) {
        guard isEnabled else { return }
        if eyesClosed {
            guard !didCompleteHold else { return }
            cancelReleaseTimer()
            startHoldIfNeeded()
        } else {
            guard !didCompleteHold else {
                cancelReleaseTimer()
                return
            }
            scheduleReleaseReset()
        }
    }

    func completeImmediately() {
        guard isEnabled, !didCompleteHold else { return }
        progress = 1
        completeHold()
    }

    func disable() {
        isEnabled = false
        resetHold(clearProgress: !didCompleteHold)
    }

    func enable() {
        isEnabled = true
        prepareForNextHold()
    }

    func prepareForNextHold() {
        stopTimer()
        soundPlayer.stopProgressTone()
        cancelReleaseTimer()
        progress = 0
        isHolding = false
        hasCompletedCurrentHold = false
        didCompleteHold = false
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
        didCompleteHold = true
        stopTimer()
        cancelReleaseTimer()
        soundPlayer.stopProgressTone()
        soundPlayer.playCompletionPop()
        isHolding = false
        DispatchQueue.main.async { [weak self] in
            self?.onCompleted?()
        }
    }

    private func resetHold(clearProgress: Bool = true) {
        guard progress > 0 || isHolding else { return }
        stopTimer()
        soundPlayer.stopProgressTone()
        cancelReleaseTimer()
        if clearProgress {
            progress = 0
            hasCompletedCurrentHold = false
            didCompleteHold = false
        }
        isHolding = false
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func cancelReleaseTimer() {
        releaseTimer?.invalidate()
        releaseTimer = nil
    }

    private func scheduleReleaseReset() {
        cancelReleaseTimer()
        guard progress > 0 || isHolding else { return }
        releaseTimer = Timer.scheduledTimer(withTimeInterval: releaseGraceDuration, repeats: false) { [weak self] _ in
            self?.resetHold(clearProgress: true)
        }
    }

    deinit {
        stopTimer()
        soundPlayer.stopProgressTone()
        cancelReleaseTimer()
    }
}
