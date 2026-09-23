# VoiceGlowSwift

A native SwiftUI interpretation of [voice-glow](https://github.com/Jakubantalik/Libraries.dev/tree/main/packages/voice-glow) by Jakub Antalik. This package does not embed React, a web view, JavaScript, CSS, or npm dependencies. It reproduces the seven-lobe palette, edge stroke, band, bloom, idle breathing, processing sweep, and the source's visual controls with SwiftUI `Canvas` and a small response driver.

## Try the demo

Open `Demo/VoiceGlowDemo.xcodeproj`, choose an iPhone simulator or your connected iPhone, and run `VoiceGlowDemo`. For a physical iPhone, select the `VoiceGlowDemo` target in Xcode, open **Signing & Capabilities**, and choose your Apple development team; Xcode will manage the development certificate and provisioning profile. The full-screen listening scene plays a synthetic voice pulse by default; tap the microphone control to pause it or the sliders control at the top to change the manual level, preset, theme, palette, custom colors, and numeric controls.

If the project file needs regenerating, run `xcodegen generate` in `Demo/`.

## Add to an app

In Xcode, add this directory as a local Swift package and import `VoiceGlowSwift`:

```swift
import VoiceGlowSwift

@State private var meter = 0.0
@State private var configuration = VoiceBeamConfiguration(preset: .default, theme: .dark)

var body: some View {
    VoiceBeam(level: meter, configuration: configuration) {
        ChatInput()
    }
}
```

For a rapidly changing source, pass a `@MainActor` getter sampled by the beam's animation clock:

```swift
VoiceBeam(level: { meter.currentLevel }, configuration: configuration) {
    ChatInput()
}
```

Set `configuration.processing = true` while work is in progress. Use `preset: .pill` for a small recording control or `.mobile` for a phone-width control. `theme: .auto` follows the SwiftUI color scheme; `.light` and `.dark` are explicit. Override `configuration.colors` with up to seven `BeamRGB` values and `configuration.bandColors` with any combination of core/above/mid/below.

All visual controls from the source are properties of `VoiceBeamConfiguration`. The demo settings panel exposes them individually. `borderRadius` is explicit in SwiftUI because a view cannot reliably introspect a child's effective corner radius; set it to match the child.

## Version scope

V1 accepts a normalized manual level (0–1) or per-frame getter and synthesizes low/mid/high motion from that level. It does **not** yet request microphone permission, analyze a live audio stream, or respond to true frequency bands. The microphone-shaped demo button pauses or resumes the synthetic pulse; it does not record audio. A later native audio meter can feed this same driver without changing the rendering API. This is a native visual interpretation, not a pixel-matched port of the source renderer. Unlike the source React component, this package does not include web-only `className`, `style`, `css`, or DOM callbacks.

## Verification

`swift test` runs the driver tests. On a File Provider-backed macOS workspace, use `swift test --scratch-path /tmp/voice-glow-swift-build` if local code signing rejects the default build directory. The demo was also built, installed, and launched on the iPhone 18 Pro iOS 27 simulator. The current listening-screen capture is `listening-demo-simulator.png`; visual tuning should still be confirmed in the target app.

## Attribution

The source `voice-glow` package is MIT licensed, copyright 2026 Jakub Antalik. Its license is reproduced in `SOURCE-LICENSE`. The Swift implementation here is a separate native adaptation.
