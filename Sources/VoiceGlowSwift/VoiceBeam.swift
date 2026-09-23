import SwiftUI

/// Wrap any SwiftUI content with the layered voice glow. Supply a manual
/// 0–1 level now; a future audio meter can call through the same getter.
public struct VoiceBeam<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var clock = VoiceBeamClock()

    private let configuration: VoiceBeamConfiguration
    private let level: @MainActor () -> Double
    private let content: Content

    public init(
        level: Double,
        configuration: VoiceBeamConfiguration = .init(),
        @ViewBuilder content: () -> Content
    ) {
        self.configuration = configuration
        self.level = { level }
        self.content = content()
    }

    public init(
        level: @escaping @MainActor () -> Double,
        configuration: VoiceBeamConfiguration = .init(),
        @ViewBuilder content: () -> Content
    ) {
        self.configuration = configuration
        self.level = level
        self.content = content()
    }

    public var body: some View {
        content.overlay {
            TimelineView(.animation(minimumInterval: 1 / 60, paused: configuration.paused)) { timeline in
                let resolvedTheme: VoiceBeamTheme = configuration.theme == .auto
                    ? (colorScheme == .dark ? .dark : .light) : configuration.theme
                let frame = clock.frame(at: timeline.date, level: level(),
                                        configuration: configuration, reduceMotion: reduceMotion)
                VoiceBeamRenderer(frame: frame, configuration: configuration, theme: resolvedTheme)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
        }
    }
}
