import SwiftUI
import VoiceGlowSwift

struct DemoView: View {
    @State private var configuration: VoiceBeamConfiguration = {
        var result = VoiceBeamConfiguration(preset: .mobile, theme: .dark)
        result.borderRadius = 0
        if ProcessInfo.processInfo.arguments.contains("--voice-glow-reference") {
            result.bands = false
            result.flow = 0
            result.staticColors = true
            result.distortion = 0
            result.idle = 0
        }
        return result
    }()
    @State private var level = 0.65
    @State private var playingSample = !ProcessInfo.processInfo.arguments.contains("--voice-glow-reference")
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
            : Color(red: 17 / 255, green: 17 / 255, blue: 17 / 255)
    }

    private func startSampleIfNeeded() {
        guard playingSample, sampleTask == nil else { return }
        sampleTask = Task { @MainActor in
            let start = Date()
            while !Task.isCancelled {
                let t = Date().timeIntervalSince(start)
                let phrase = t.truncatingRemainder(dividingBy: 9)
                if phrase > 6.6 {
                    level = 0
                } else {
                    let syllable = 0.5 + 0.5 * sin(t * .pi * 2 * 3.1)
                    let word = 0.5 + 0.5 * sin(t * .pi * 2 * 0.55 + 1)
                    let rough = 0.86 + 0.14 * sin(t * 23.7)
                    level = min(1, pow(syllable, 1.6) * (0.5 + 0.5 * word) * rough * 1.05)
                }
                try? await Task.sleep(for: .milliseconds(33))
            }
        }
    }
}
