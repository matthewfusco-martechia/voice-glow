import SwiftUI
import VoiceGlowSwift

struct DemoView: View {
    @State private var configuration: VoiceBeamConfiguration = {
        var result = VoiceBeamConfiguration(preset: .mobile, theme: .dark)
        result.colors = [
            BeamRGB(230, 65, 165), BeamRGB(188, 59, 173), BeamRGB(222, 93, 170),
            BeamRGB(63, 165, 165), BeamRGB(244, 166, 96),
            BeamRGB(65, 152, 178), BeamRGB(98, 188, 163)
        ]
        result.flow = 4
        result.bandStrength = 0.12
        result.strokeOpacity = 0.22
        result.innerOpacity = 0.55
        result.bloomOpacity = 0.80
        result.glowHeight = 1.55
        result.rangeHeight = 0.88
        result.strength = 0.9
        result.borderRadius = 56
        return result
    }()
    @State private var level = 0.65
    @State private var playingSample = true
    @State private var sampleTask: Task<Void, Never>?
    @State private var showsSettings = false
    @State private var selectedAgent = "Agent (auto)"

    var body: some View {
        GeometryReader { geometry in
            VoiceBeam(level: level, configuration: configuration) {
                Rectangle()
                    .fill(panelColor)
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .overlay {
                ListeningPanelContent(
                    selectedAgent: $selectedAgent,
                    playingSample: $playingSample,
                    level: $level,
                    showsSettings: $showsSettings,
                    screenHeight: geometry.size.height,
                    lightTheme: configuration.theme == .light
                )
            }
        }
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showsSettings) {
            NavigationStack {
                SettingsView(configuration: $configuration, level: $level, playingSample: $playingSample)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("Done") { showsSettings = false }
                        }
                    }
            }
        }
        .task { startSampleIfNeeded() }
        .onChange(of: playingSample) { _, newValue in
            if newValue { startSampleIfNeeded() }
            else {
                sampleTask?.cancel()
                sampleTask = nil
            }
        }
        .onDisappear {
            sampleTask?.cancel()
            sampleTask = nil
        }
    }

    private var panelColor: Color {
        configuration.theme == .light
            ? Color(red: 0.96, green: 0.96, blue: 0.97)
            : Color(red: 0.105, green: 0.105, blue: 0.105)
    }

    private func startSampleIfNeeded() {
        guard playingSample, sampleTask == nil else { return }
        sampleTask = Task { @MainActor in
            let start = Date()
            while !Task.isCancelled {
                let t = Date().timeIntervalSince(start)
                let syllable = max(0, sin(t * 12.5)) * (0.23 + 0.28 * sin(t * 2.4))
                level = min(1, max(0.1, 0.34 + syllable + 0.12 * sin(t * 3.2)))
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }
}
