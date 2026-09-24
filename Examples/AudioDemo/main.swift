import Foundation
import SwiftGameKit

print("=== Audio Demo ===")
Audio.masterVolume = 0.8
Audio.sfxVolume = 1.0
Audio.musicVolume = 0.6

let sfx = Audio.play("explosion")
print("Played SFX handle: \(sfx.id)")
Audio.music.play("theme")
print("Music started")
Audio.music.pause()
print("Music paused")
Audio.music.resume()
print("Music resumed")
Audio.music.stop()
print("Audio demo completed (using NullAudioBackend on this platform).")
