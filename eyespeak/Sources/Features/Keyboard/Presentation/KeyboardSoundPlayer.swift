import Foundation
#if canImport(AudioToolbox)
import AudioToolbox
#endif

@MainActor
struct KeyboardSoundPlayer {
    #if canImport(AudioToolbox)
    private let keySound: SystemSoundID = 1104
    private let deleteSound: SystemSoundID = 1155
    private let modifierSound: SystemSoundID = 1156
    #endif
    
    func playKey() {
        #if canImport(AudioToolbox)
        AudioServicesPlaySystemSound(keySound)
        #endif
    }
    
    func playDelete() {
        #if canImport(AudioToolbox)
        AudioServicesPlaySystemSound(deleteSound)
        #endif
    }
    
    func playModifier() {
        #if canImport(AudioToolbox)
        AudioServicesPlaySystemSound(modifierSound)
        #endif
    }
}
