import SwiftUI

public enum VoiceBeamPreset: String, CaseIterable, Sendable {
    case `default`, pill, mobile
}

public enum VoiceBeamTheme: String, CaseIterable, Sendable {
    case dark, light, auto
}

public enum VoiceBeamColorVariant: String, CaseIterable, Sendable {
    case colorful, mono, ocean, sunset, forest, candy, ice, gold
}

/// Native equivalents of the source package's appearance and response controls.
/// Values are mutable so an app can bind a settings panel directly to them.
public struct VoiceBeamConfiguration: Sendable {
    public var preset: VoiceBeamPreset = .default
    public var theme: VoiceBeamTheme = .dark
    public var colorVariant: VoiceBeamColorVariant = .colorful
    public var colors: [BeamRGB] = []
    public var bandColors = VoiceBeamBandColors()

    public var scale = 1.0
    public var sensitivity = 3.1
    public var threshold = 0.015
    public var attack = 0.325
    public var release = 0.86
    public var idle = 0.23
    public var breatheDuration = 5.2
    public var reach = 1.2
    public var spread = 1.05
    public var bands = true
    public var flow = 48.0

    public var processing = false
    public var processingDuration = 1.1
    public var processingLevel = 0.55
    public var processingEase = 0.6
    public var processingTravel = 1.55
    public var processingCurve = 2.1
    public var cornerFollow = 0.45

    public var staticColors = false
    public var hueRange = 24.0
    public var hueDuration = 12.0
    public var active = true
    public var paused = false
    public var borderRadius = 16.0
    public var brightness = 1.15
    public var saturation = 1.2
    public var glowSize = 1.0
    public var strokeOpacity = 1.0
    public var innerOpacity = 1.0
    public var bloomOpacity = 1.0

    public var bend = 60.0
    public var bandStrength = 1.55
    public var bandWidth = 2.15
    public var bandPosition = 0.35
    public var bandCurve = 1.75
    public var bandSpread = 0.87
    public var bandSkew = 0.12
    public var bandOffset = -27.0
    public var bandTail = 0.59
    public var bandTailPosition = 0.67
    public var bandTailCurve = 2.4
    public var bandTailOverflow = 15.0
    public var bandAberration = 0.89
    public var distortion = 0.62
    public var distortionDetail = 2.3

    public var glowWidth = 0.65
    public var glowHeight = 1.25
    public var lobeSpacing = 0.85
    public var rangeWidth = 0.75
    public var rangeHeight = 1.0
    public var softness = 1.07
    public var coreSize = 1.0
    public var coreLight = 0.0
    public var coreLightWidth = 1.0
    public var coreLightHeight = 1.0
    public var strokeScale = 1.0
    public var innerScale = 1.0
    public var innerHeight = 1.0
    public var bloomScale = 1.0
    public var bloomHeight = 1.0
    public var strength = 1.0

    public init(preset: VoiceBeamPreset = .default, theme: VoiceBeamTheme = .dark) {
        self.preset = preset
        self.theme = theme
        applyPreset(preset, theme: theme == .auto ? .dark : theme)
    }

    public mutating func applyPreset(_ preset: VoiceBeamPreset, theme: VoiceBeamTheme) {
        self.preset = preset
        self.theme = theme
        switch preset {
        case .default:
            break
        case .pill:
            scale = 0.45; glowSize = 0.95
            strokeOpacity = 1.2; innerOpacity = 0.85
            reach = 1.35; spread = 1.1; flow = 0; bend = 23
            bandWidth = 1.85; bandCurve = 1.95; bandSpread = 0.38
            bandOffset = -16; bandTail = 0
            processingTravel = 2; cornerFollow = 0
            distortion = 0.45; distortionDetail = 3
            glowHeight = 0.95; lobeSpacing = 0.45
            rangeWidth = 0.8; rangeHeight = 0.7; softness = 0.88
            coreSize = 0.25; strokeScale = 1.25; innerScale = 0.95
            bloomScale = 1.05; bloomHeight = 2.25
            brightness = 1.35; saturation = 1.5
        case .mobile:
            scale = 1.25; spread = 0.45; reach = 3
            flow = 60; bend = 70; bandWidth = 2.4; bandCurve = 1.55
            bandSpread = 0.9; bandOffset = -50; bandTail = 0.62
            bandTailPosition = 0.42; bandTailCurve = 2.7
            bandTailOverflow = 22; processingDuration = 1.05
            processingLevel = 0.35; processingTravel = 1
            cornerFollow = 0.4; bandStrength = 1.8
            distortionDetail = 2; glowWidth = 1.15; glowHeight = 2.1
            lobeSpacing = 1.35; rangeWidth = 1.25; rangeHeight = 1.2
            softness = 1.1; brightness = 1.2; saturation = 1.5
        }
        if theme == .light {
            if preset == .default { reach = 1.8; spread = 0.8; bandStrength = 1.7 }
            if preset == .pill { bandStrength = 2 }
            if preset == .mobile { bandStrength = 1.7 }
            coreLight = 1.8
            hueRange = 40; hueDuration = 8.5
            brightness = 0.95; saturation = 1.6
            strength = preset == .mobile ? 1 : 0.8
        }
    }
}
