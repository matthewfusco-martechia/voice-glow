import SwiftUI

struct ListeningPanelContent: View {
    @Binding var selectedAgent: String
    @Binding var playingSample: Bool
    @Binding var level: Double
    @Binding var showsSettings: Bool

    let screenHeight: CGFloat
    let lightTheme: Bool

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    Spacer()
                    Button("Adjust glow", systemImage: "slider.horizontal.3") {
                        showsSettings = true
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(foreground.opacity(0.55))
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(lightTheme ? 0.12 : 0.04), in: Circle())
                    .accessibilityHint("Opens the demo input and all glow settings")
                }
                .padding(.top, 74)
                .padding(.trailing, 18)
                Spacer()
            }

            Text("Set a timer for ten minutes and\nremind me to water the plants")
                .font(.title2)
                .multilineTextAlignment(.center)
                .foregroundStyle(foreground.opacity(0.86))
                .lineSpacing(5)
                .padding(.horizontal, 30)
                .offset(y: screenHeight * 0.035)

            VStack {
                Spacer()
                HStack(spacing: 14) {
                    Menu {
                        Button("Agent (auto)") { selectedAgent = "Agent (auto)" }
                        Button("Writing agent") { selectedAgent = "Writing agent" }
                        Button("Research agent") { selectedAgent = "Research agent" }
                    } label: {
                        HStack(spacing: 9) {
                            Text(selectedAgent)
                                .font(.subheadline)
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.semibold))
                        }
                        .foregroundStyle(foreground.opacity(0.76))
                        .padding(.horizontal, 18)
                        .frame(height: 48)
                        .background(.white.opacity(lightTheme ? 0.13 : 0.08), in: Capsule())
                        .overlay { Capsule().strokeBorder(.white.opacity(0.08)) }
                    }

                    Spacer(minLength: 4)

                    Button(playingSample ? "Pause sample voice" : "Play sample voice",
                           systemImage: playingSample ? "mic.fill" : "mic.slash.fill") {
                        playingSample.toggle()
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(foreground)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(lightTheme ? 0.14 : 0.09), in: Circle())
                    .overlay { Circle().strokeBorder(.white.opacity(0.07)) }

                    Button("Clear sample", systemImage: "xmark") {
                        playingSample = false
                        level = 0
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(foreground)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(lightTheme ? 0.14 : 0.09), in: Circle())
                    .overlay { Circle().strokeBorder(.white.opacity(0.07)) }
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 100)
            }
        }
        .frame(height: screenHeight)
    }

    private var foreground: Color { lightTheme ? .black : .white }
}
