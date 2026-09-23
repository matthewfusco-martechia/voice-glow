import SwiftUI
import VoiceGlowSwift

private struct NumericSetting: Identifiable {
    let name: String
    let keyPath: WritableKeyPath<VoiceBeamConfiguration, Double>
    let range: ClosedRange<Double>
    var id: String { name }

    init(_ name: String, _ keyPath: WritableKeyPath<VoiceBeamConfiguration, Double>, _ range: ClosedRange<Double>) {
        self.name = name
        self.keyPath = keyPath
        self.range = range
    }
}

private struct SettingGroup: Identifiable {
    let name: String
    let settings: [NumericSetting]
    var id: String { name }
}

struct SettingsView: View {
    @Binding var configuration: VoiceBeamConfiguration
    @Binding var level: Double
    @Binding var playingSample: Bool

    private let groups: [SettingGroup] = [
        SettingGroup(name: "Input envelope", settings: [
            .init("Sensitivity", \.sensitivity, 0...8),
            .init("Threshold", \.threshold, 0...0.25),
            .init("Attack", \.attack, 0.01...1.5),
            .init("Release", \.release, 0.01...2),
            .init("Idle", \.idle, 0...1),
            .init("Breathe duration", \.breatheDuration, 0.2...12)
        ]),
        SettingGroup(name: "Reaction", settings: [
            .init("Reach", \.reach, 0...4),
            .init("Spread", \.spread, 0...3),
            .init("Flow", \.flow, -120...120),
            .init("Bend", \.bend, 0...120),
            .init("Scale", \.scale, 0.15...3),
            .init("Strength", \.strength, 0...1)
        ]),
        SettingGroup(name: "Processing", settings: [
            .init("Duration", \.processingDuration, 0.2...4),
            .init("Level", \.processingLevel, 0...1),
            .init("Ease", \.processingEase, 0.05...2),
            .init("Travel", \.processingTravel, 0...3),
            .init("Curve", \.processingCurve, 1...5),
            .init("Corner follow", \.cornerFollow, 0...1)
        ]),
        SettingGroup(name: "Color and light", settings: [
            .init("Hue range", \.hueRange, 0...180),
            .init("Hue duration", \.hueDuration, 0.2...30),
            .init("Brightness", \.brightness, 0...2),
            .init("Saturation", \.saturation, 0...2),
            .init("Core light", \.coreLight, 0...3),
            .init("Glow size", \.glowSize, 0...3),
            .init("Stroke opacity", \.strokeOpacity, 0...2),
            .init("Inner opacity", \.innerOpacity, 0...2),
            .init("Bloom opacity", \.bloomOpacity, 0...2)
        ]),
        SettingGroup(name: "Band shape", settings: [
            .init("Band strength", \.bandStrength, 0...4),
            .init("Band width", \.bandWidth, 0...5),
            .init("Band position", \.bandPosition, 0...1.3),
            .init("Band curve", \.bandCurve, 0.2...5),
            .init("Band spread", \.bandSpread, 0...3),
            .init("Band skew", \.bandSkew, -1...1),
            .init("Band offset", \.bandOffset, -100...100),
            .init("Band tail", \.bandTail, 0...2),
            .init("Tail position", \.bandTailPosition, 0...1),
            .init("Tail curve", \.bandTailCurve, 0.2...5),
            .init("Tail overflow", \.bandTailOverflow, 0...60),
            .init("Chromatic aberration", \.bandAberration, 0...3),
            .init("Distortion", \.distortion, 0...2),
            .init("Distortion detail", \.distortionDetail, 0...6)
        ]),
        SettingGroup(name: "Glow geometry", settings: [
            .init("Glow width", \.glowWidth, 0...3),
            .init("Glow height", \.glowHeight, 0...4),
            .init("Lobe spacing", \.lobeSpacing, 0...3),
            .init("Range width", \.rangeWidth, 0...3),
            .init("Range height", \.rangeHeight, 0...3),
            .init("Softness", \.softness, 0...3),
            .init("Core size", \.coreSize, 0...3),
            .init("Core light width", \.coreLightWidth, 0...3),
            .init("Core light height", \.coreLightHeight, 0...3),
            .init("Stroke scale", \.strokeScale, 0...3),
            .init("Inner scale", \.innerScale, 0...3),
            .init("Inner height", \.innerHeight, 0...3),
            .init("Bloom scale", \.bloomScale, 0...3),
            .init("Bloom height", \.bloomHeight, 0...4),
            .init("Border radius", \.borderRadius, 0...40)
        ])
    ]

    var body: some View {
        Form {
            Section("Demo input") {
                Toggle("Synthetic voice pulse", isOn: $playingSample)
                Slider(value: $level, in: 0...1) {
                    Text("Manual level")
                }
                .disabled(playingSample)
                Text("Live microphone analysis is planned for v2.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Presets") {
                Picker("Geometry", selection: presetBinding) {
                    ForEach(VoiceBeamPreset.allCases, id: \.self) { preset in
                        Text(preset.rawValue.capitalized).tag(preset)
                    }
                }
                Picker("Theme", selection: themeBinding) {
                    ForEach(VoiceBeamTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue.capitalized).tag(theme)
                    }
                }
                Picker("Color variant", selection: variantBinding) {
                    ForEach(VoiceBeamColorVariant.allCases, id: \.self) { variant in
                        Text(variant.rawValue.capitalized).tag(variant)
                    }
                }
            }

            Section("Mode") {
                Toggle("Active", isOn: $configuration.active)
                Toggle("Paused", isOn: $configuration.paused)
                Toggle("Processing", isOn: $configuration.processing)
                Toggle("Bands", isOn: $configuration.bands)
                Toggle("Static colors", isOn: $configuration.staticColors)
            }

            Section("Custom lobe colors") {
                ForEach(0..<7, id: \.self) { index in
                    ColorPicker("Lobe \(index + 1)", selection: lobeColor(index))
                }
                Button("Restore variant colors") { configuration.colors = [] }
            }

            Section("Custom band colors") {
                ColorPicker("Core", selection: bandColor(\.core))
                ColorPicker("Above", selection: bandColor(\.above))
                ColorPicker("Middle", selection: bandColor(\.mid))
                ColorPicker("Below", selection: bandColor(\.below))
                Button("Restore theme band colors") { configuration.bandColors = .init() }
            }

            ForEach(groups) { group in
                Section(group.name) {
                    ForEach(group.settings) { setting in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(setting.name)
                                Spacer()
                                Text(configuration[keyPath: setting.keyPath].formatted(.number.precision(.fractionLength(2))))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: numericBinding(setting.keyPath), in: setting.range)
                        }
                    }
                }
            }
        }
        .navigationTitle("All settings")
    }

    private var presetBinding: Binding<VoiceBeamPreset> {
        Binding(get: { configuration.preset }, set: { preset in
            let variant = configuration.colorVariant
            let custom = configuration.colors
            let bandColors = configuration.bandColors
            configuration = VoiceBeamConfiguration(preset: preset, theme: configuration.theme)
            configuration.colorVariant = variant
            configuration.colors = custom
            configuration.bandColors = bandColors
        })
    }

    private var themeBinding: Binding<VoiceBeamTheme> {
        Binding(get: { configuration.theme }, set: { theme in
            let variant = configuration.colorVariant
            let custom = configuration.colors
            let bandColors = configuration.bandColors
            configuration = VoiceBeamConfiguration(preset: configuration.preset, theme: theme)
            configuration.colorVariant = variant
            configuration.colors = custom
            configuration.bandColors = bandColors
        })
    }

    private var variantBinding: Binding<VoiceBeamColorVariant> {
        Binding(get: { configuration.colorVariant }, set: { variant in
            configuration.colorVariant = variant
            configuration.colors = []
        })
    }

    private func numericBinding(_ path: WritableKeyPath<VoiceBeamConfiguration, Double>) -> Binding<Double> {
        Binding(get: { configuration[keyPath: path] },
                set: { configuration[keyPath: path] = $0 })
    }

    private func lobeColor(_ index: Int) -> Binding<Color> {
        Binding(get: {
            let theme = configuration.theme == .auto ? VoiceBeamTheme.dark : configuration.theme
            let palette = VoiceBeamPalettes.colors(for: configuration.colorVariant, theme: theme)
            return (configuration.colors.count > index ? configuration.colors[index] : palette[index]).color
        }, set: { color in
            let theme = configuration.theme == .auto ? VoiceBeamTheme.dark : configuration.theme
            if configuration.colors.count != 7 {
                configuration.colors = VoiceBeamPalettes.colors(for: configuration.colorVariant, theme: theme)
            }
            configuration.colors[index] = rgb(color)
        })
    }

    private func bandColor(_ path: WritableKeyPath<VoiceBeamBandColors, BeamRGB?>) -> Binding<Color> {
        Binding(get: {
            configuration.bandColors[keyPath: path]?.color ?? .white
        }, set: { color in
            configuration.bandColors[keyPath: path] = rgb(color)
        })
    }

    private func rgb(_ color: Color) -> BeamRGB {
        let resolved = color.resolve(in: EnvironmentValues())
        return BeamRGB(red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue))
    }
}
