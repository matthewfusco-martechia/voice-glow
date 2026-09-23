import Foundation

/// The manual-level input chain. A later audio source can feed RMS and true
/// low/mid/high energies into this same envelope and renderer.
public struct VoiceBeamDriver: Sendable {
    private var level = 0.0
    private var low = 0.0
    private var mid = 0.0
    private var high = 0.0
    private var phase = 0.0
    private var processingBlend = 0.0
    private var activeBlend = 1.0
    private var processingClock = 0.0
    private var time = 0.0
    private var lastTimestamp: Double?
    private var heldFrame = VoiceBeamFrame()

    public init() {}

    public mutating func step(
        timestamp: Double,
        input: Double,
        configuration: VoiceBeamConfiguration,
        reduceMotion: Bool = false
    ) -> VoiceBeamFrame {
        if configuration.paused { return heldFrame }
        let dt = min(0.05, max(0, timestamp - (lastTimestamp ?? timestamp - 1 / 60)))
        lastTimestamp = timestamp
        time += dt
        activeBlend = follow(activeBlend, configuration.active ? 1 : 0,
                             dt: dt, rise: 0.18, fall: 0.24)

        if !configuration.active {
            level = follow(level, 0, dt: dt, rise: configuration.attack, fall: configuration.release)
            processingBlend = follow(processingBlend, 0, dt: dt, rise: 0.1, fall: 0.18)
        } else {
            // The source's manual level bypasses microphone gain. Sensitivity
            // belongs to the live-audio input chain, not this 0–1 getter.
            let raw = clamp(input)
            level = follow(level, shape(raw, gate: configuration.threshold), dt: dt,
                           rise: configuration.attack, fall: configuration.release)
            let syntheticMid = raw * (0.72 + 0.28 * sin(time * 9.1))
            let syntheticHigh = raw * (0.6 + 0.4 * sin(time * 13.7 + 2))
            low = follow(low, shape(raw, gate: configuration.threshold * 0.6), dt: dt,
                         rise: configuration.attack, fall: configuration.release * 1.15)
            mid = follow(mid, shape(syntheticMid, gate: configuration.threshold * 0.6), dt: dt,
                         rise: configuration.attack, fall: configuration.release * 1.15)
            high = follow(high, shape(syntheticHigh, gate: configuration.threshold * 0.6), dt: dt,
                          rise: configuration.attack, fall: configuration.release * 1.15)
            processingBlend = follow(processingBlend, configuration.processing ? 1 : 0, dt: dt,
                                     rise: configuration.processingEase * 0.9,
                                     fall: configuration.processingEase * 0.8)
        }

        if configuration.processing && configuration.active {
            if processingClock == 0 { processingClock = max(0.05, configuration.processingDuration) / 2 }
            processingClock += dt
        } else if processingBlend < 0.001 {
            processingClock = 0
        }

        let morph = smoothstep(processingBlend)
        let span = 252 * configuration.lobeSpacing * configuration.scale
        let passes = processingClock / max(0.05, configuration.processingDuration)
        let passIndex = floor(passes)
        let position = passes - passIndex
        let curve = max(1, configuration.processingCurve)
        let eased = position < 0.5
            ? 0.5 * pow(2 * position, curve)
            : 1 - 0.5 * pow(2 - 2 * position, curve)
        let direction = Int(passIndex) % 2 == 0 ? 1.0 : -1.0
        let pass = reduceMotion ? 0 : direction * (2 * eased - 1)
        let center = morph * span / 2 * configuration.processingTravel * pass

        let breath = reduceMotion ? 0.5 : 0.5 + 0.5 * sin(2 * .pi * time / max(0.1, configuration.breatheDuration))
        let voiced = level + (1 - level) * configuration.idle * breath
        let held = smoothstep(clamp((morph - 0.25) / 0.75))
        let effective = max(voiced, configuration.processingLevel * held) * activeBlend
        if configuration.flow != 0 && !reduceMotion {
            phase = wrap(phase + configuration.flow * configuration.scale * effective * dt, span: span)
        }

        let frame = VoiceBeamFrame(
            level: level, low: low, mid: mid, high: high, phase: phase,
            center: center, intensity: effective, glow: (0.15 + 0.85 * effective) * activeBlend,
            width: (0.85 + configuration.spread * effective) * (1 + morph * 0.3 * (1 - pass * pass)),
            height: 0.5 + configuration.reach * effective,
            gather: 1 - morph * 0.6, maskWidth: 1 - morph * 0.45,
            processingMorph: morph,
            hue: configuration.staticColors || reduceMotion ? 0 :
                -configuration.hueRange * cos(2 * .pi * time / max(0.1, configuration.hueDuration)),
            time: time
        )
        heldFrame = frame
        return frame
    }

    public var currentFrame: VoiceBeamFrame { heldFrame }

    private func clamp(_ x: Double) -> Double { min(1, max(0, x)) }
    private func shape(_ raw: Double, gate: Double) -> Double {
        if raw <= gate { return 0 }
        let value = (raw - gate) / max(0.001, 1 - gate)
        return clamp((1 - exp(-3 * value)) / (1 - exp(-3)))
    }
    private func follow(_ value: Double, _ target: Double, dt: Double, rise: Double, fall: Double) -> Double {
        let tau = target > value ? rise : fall
        return value + (target - value) * (1 - exp(-dt / max(0.001, tau)))
    }
    private func smoothstep(_ x: Double) -> Double { x * x * (3 - 2 * x) }
    private func wrap(_ x: Double, span: Double) -> Double {
        guard span > 0 else { return 0 }
        return ((x.truncatingRemainder(dividingBy: span)) + span).truncatingRemainder(dividingBy: span)
    }
}
