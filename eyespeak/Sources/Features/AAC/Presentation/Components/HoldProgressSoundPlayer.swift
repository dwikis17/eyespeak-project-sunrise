//
//  HoldProgressSoundPlayer.swift
//  eyespeak
//

import Foundation
import AVFoundation
import UIKit

/// Generates the rising synth tone that mirrors the hold-to-snooze progress bar.
final class HoldProgressSoundPlayer: ObservableObject {
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let sampleRate: Double = 44100
    private let startFrequency: Double = 220
    private let endFrequency: Double = 880
    private let amplitude: Float = 0.25
    private let duration: TimeInterval
    private var toneBuffer: AVAudioPCMBuffer?
    private var completionPlayer: AVAudioPlayer?

    init(duration: TimeInterval = 2.0) {
        self.duration = duration
        configureSession()
        configureEngine()
    }

    func startProgressTone() {
        startEngineIfNeeded()
        guard let buffer = toneBuffer else { return }
        playerNode.stop()
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        playerNode.play()
    }

    func stopProgressTone() {
        guard playerNode.isPlaying else { return }
        playerNode.stop()
    }

    func playCompletionPop() {
        prepareCompletionPlayerIfNeeded()
        completionPlayer?.currentTime = 0
        completionPlayer?.play()
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            print("HoldProgressSoundPlayer session error: \(error)")
        }
    }

    private func configureEngine() {
        engine.attach(playerNode)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2) else {
            return
        }
        toneBuffer = makeToneBuffer(duration: duration, format: format)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        engine.prepare()
        startEngineIfNeeded()
    }

    private func startEngineIfNeeded() {
        guard !engine.isRunning else { return }
        do {
            try engine.start()
        } catch {
            print("HoldProgressSoundPlayer engine error: \(error)")
        }
    }

    private func makeToneBuffer(duration: TimeInterval, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let totalFrames = AVAudioFrameCount(format.sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: totalFrames),
              let channelData = buffer.floatChannelData else {
            return nil
        }

        buffer.frameLength = totalFrames
        var phase: Double = 0
        let totalSamples = Int(totalFrames)
        let fadeSamples = Int(format.sampleRate * 0.05)

        for frame in 0..<totalSamples {
            let time = Double(frame) / format.sampleRate
            let progress = min(1.0, time / duration)
            let frequency = startFrequency + (endFrequency - startFrequency) * progress
            let phaseIncrement = 2.0 * Double.pi * frequency / format.sampleRate
            var sampleValue = Float(sin(phase) * Double(amplitude))

            if frame >= totalSamples - fadeSamples {
                let fadeProgress = Float(totalSamples - frame) / Float(fadeSamples)
                sampleValue *= max(0, fadeProgress)
            }

            phase += phaseIncrement
            if phase > 2.0 * Double.pi {
                phase -= 2.0 * Double.pi
            }

            for channel in 0..<Int(format.channelCount) {
                channelData[channel][frame] = sampleValue
            }
        }

        return buffer
    }

    private func prepareCompletionPlayerIfNeeded() {
        guard completionPlayer == nil else { return }
        guard let asset = NSDataAsset(name: "pop") else {
            print("HoldProgressSoundPlayer missing pop asset")
            return
        }
        do {
            completionPlayer = try AVAudioPlayer(data: asset.data)
            completionPlayer?.prepareToPlay()
        } catch {
            print("HoldProgressSoundPlayer pop asset error: \(error)")
        }
    }
}
