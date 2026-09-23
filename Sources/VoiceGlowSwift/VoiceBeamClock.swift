import Foundation

@MainActor
final class VoiceBeamClock {
    private var driver = VoiceBeamDriver()

    func frame(at date: Date, level: Double, configuration: VoiceBeamConfiguration, reduceMotion: Bool) -> VoiceBeamFrame {
        driver.step(timestamp: date.timeIntervalSinceReferenceDate, input: level,
                    configuration: configuration, reduceMotion: reduceMotion)
    }
}
