import Testing
@testable import VoiceGlowSwift

struct VoiceBeamDriverTests {
    @Test func presetValuesRemainDistinct() {
        let pill = VoiceBeamConfiguration(preset: .pill)
        let mobile = VoiceBeamConfiguration(preset: .mobile)
        #expect(pill.scale == 0.45)
        #expect(mobile.scale == 1.25)
        #expect(mobile.reach > pill.reach)
    }

    @Test func envelopeRisesAndFalls() {
        var driver = VoiceBeamDriver()
        let config = VoiceBeamConfiguration()
        for tick in 0..<60 {
            _ = driver.step(timestamp: Double(tick) / 60, input: 0.8, configuration: config)
        }
        let peak = driver.currentFrame.level
        #expect(peak > 0.5)
        for tick in 60..<240 {
            _ = driver.step(timestamp: Double(tick) / 60, input: 0, configuration: config)
        }
        #expect(driver.currentFrame.level < peak)
    }

    @Test func processingTravelsAndPauseHoldsFrame() {
        var driver = VoiceBeamDriver()
        var config = VoiceBeamConfiguration()
        config.processing = true
        var centers = [Double]()
        for tick in 0..<160 {
            let frame = driver.step(timestamp: Double(tick) / 60, input: 0, configuration: config)
            centers.append(frame.center)
        }
        #expect(driver.currentFrame.processingMorph > 0.9)
        #expect((centers.max() ?? 0) - (centers.min() ?? 0) > 10)
        let held = driver.currentFrame
        config.paused = true
        let after = driver.step(timestamp: 10, input: 1, configuration: config)
        #expect(after.center == held.center)
        #expect(after.level == held.level)
    }

    @Test func allVariantsHaveSevenColors() {
        for variant in VoiceBeamColorVariant.allCases {
            #expect(VoiceBeamPalettes.colors(for: variant, theme: .dark).count == 7)
            #expect(VoiceBeamPalettes.colors(for: variant, theme: .light).count == 7)
        }
    }

    @Test func inactiveEffectFadesOut() {
        var driver = VoiceBeamDriver()
        var config = VoiceBeamConfiguration()
        for tick in 0..<60 {
            _ = driver.step(timestamp: Double(tick) / 60, input: 0.8, configuration: config)
        }
        let lit = driver.currentFrame.glow
        config.active = false
        for tick in 60..<240 {
            _ = driver.step(timestamp: Double(tick) / 60, input: 0, configuration: config)
        }
        #expect(driver.currentFrame.glow < lit * 0.01)
    }

    @Test func manualLevelDoesNotUseMicrophoneSensitivity() {
        var lowGain = VoiceBeamDriver()
        var highGain = VoiceBeamDriver()
        var lowConfig = VoiceBeamConfiguration(preset: .mobile)
        var highConfig = lowConfig
        lowConfig.sensitivity = 0.1
        highConfig.sensitivity = 20
        for tick in 0..<180 {
            let timestamp = Double(tick) / 60
            _ = lowGain.step(timestamp: timestamp, input: 0.65, configuration: lowConfig)
            _ = highGain.step(timestamp: timestamp, input: 0.65, configuration: highConfig)
        }
        #expect(abs(lowGain.currentFrame.level - highGain.currentFrame.level) < 0.000_001)
        #expect(lowGain.currentFrame.level > 0.8)
    }

    @Test func staticColorsHoldHueWhileAnimationContinues() {
        var driver = VoiceBeamDriver()
        var configuration = VoiceBeamConfiguration(preset: .mobile)
        configuration.staticColors = true
        configuration.flow = 0
        for tick in 0..<180 {
            _ = driver.step(timestamp: Double(tick) / 60, input: 0.65,
                            configuration: configuration)
        }
        #expect(driver.currentFrame.hue == 0)
        #expect(driver.currentFrame.intensity > 0.8)
    }
}
