import SwiftUI

struct VoiceBeamRenderer: View {
    let frame: VoiceBeamFrame
    let configuration: VoiceBeamConfiguration
    let theme: VoiceBeamTheme

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true) { context, size in
            guard size.width > 0, size.height > 0, configuration.strength > 0 else { return }
            var clipped = context
            clipped.clip(to: Path(roundedRect: CGRect(origin: .zero, size: size),
                                  cornerRadius: min(configuration.borderRadius, size.height / 2)))
            drawLobes(in: clipped, size: size, bloom: true)
            drawLobes(in: clipped, size: size, bloom: false)
            drawCore(in: clipped, size: size)
            drawEdge(in: clipped, size: size)
            drawBand(in: clipped, size: size)
        }
    }

    private var palette: [BeamRGB] {
        let defaults = VoiceBeamPalettes.colors(for: configuration.colorVariant, theme: theme)
        return defaults.enumerated().map { index, fallback in
            index < configuration.colors.count ? configuration.colors[index] : fallback
        }
    }

    private func drawLobes(in context: GraphicsContext, size: CGSize, bloom: Bool) {
        let specs: [(x: Double, w: Double, h: Double, band: Int)] = [
            (0, 74, 46, 0), (-36, 54, 40, 1), (36, 54, 40, 1),
            (-72, 48, 32, 2), (72, 48, 32, 2),
            (-108, 42, 26, 1), (108, 42, 26, 1),
        ]
        let baseline = bloom ? (theme == .dark ? 0.89 : 0.5) : (theme == .dark ? 0.47 : 0.85)
        let layerMultiplier = bloom ? configuration.bloomOpacity : configuration.innerOpacity
        let layerScale = bloom ? configuration.bloomScale : configuration.innerScale
        let heightScale = bloom ? configuration.bloomHeight : configuration.innerHeight
        let opacity = min(1, baseline * layerMultiplier * configuration.strength * frame.glow)
        guard opacity > 0.001 else { return }
        var layer = context
        layer.addFilter(.blur(radius: max(0.5, (bloom ? 15 : 2.2) * configuration.glowSize * configuration.scale)))
        let span = 252 * configuration.lobeSpacing * configuration.scale
        let visibleHalf = 170 * configuration.rangeWidth * configuration.scale * frame.width * frame.maskWidth
        let mask = Path(ellipseIn: CGRect(
            x: size.width / 2 + frame.center - visibleHalf,
            y: size.height - (80 * configuration.rangeHeight * frame.height + configuration.bend * frame.intensity),
            width: visibleHalf * 2,
            height: 170 * configuration.rangeHeight * frame.height + configuration.bend * frame.intensity
        ))
        layer.clip(to: mask)

        for (index, spec) in specs.enumerated() {
            let offset = wrapped(spec.x * configuration.lobeSpacing * configuration.scale + frame.phase, span: span)
            let edgeFade = max(0, 1 - pow(offset / (span / 2 + 4), 2))
            let bandEnergy = configuration.bands
                ? [frame.low, frame.mid, frame.high][spec.band] : frame.level
            let energy = 0.65 + 0.35 * bandEnergy
            let shimmer = configuration.distortion * frame.level * (1 - frame.processingMorph)
                * sin(frame.time * 2 + Double(index) * configuration.distortionDetail) * 8
            let x = size.width / 2 + frame.center
                + offset * frame.gather * frame.width + shimmer
            let arc = frame.processingMorph * configuration.cornerFollow
                * cornerLift(x: x, size: size)
            let y = size.height + 4 * configuration.scale - arc
            let radiusX = spec.w * configuration.glowWidth * frame.width * configuration.scale * layerScale
            let radiusY = spec.h * configuration.glowHeight * frame.height * configuration.scale * heightScale
                * energy * layerScale
            let color = palette[index].adjusted(
                saturation: configuration.saturation,
                brightness: configuration.brightness,
                hueDegrees: frame.hue
            )
            drawSoftEllipse(in: layer, x: x, y: y, radiusX: radiusX, radiusY: radiusY,
                            color: color, alpha: opacity * edgeFade,
                            softness: configuration.softness)
        }
    }

    private func drawSoftEllipse(in context: GraphicsContext, x: Double, y: Double,
                                 radiusX: Double, radiusY: Double, color: Color,
                                 alpha: Double, softness: Double) {
        guard radiusX > 0, radiusY > 0, alpha > 0 else { return }
        var local = context
        local.translateBy(x: x, y: y)
        local.scaleBy(x: radiusX / radiusY, y: 1)
        let radius = radiusY * max(0.6, softness)
        let path = Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
        local.fill(path, with: .radialGradient(
            Gradient(stops: [
                .init(color: color.opacity(alpha), location: 0),
                .init(color: color.opacity(alpha * 0.48), location: 0.36),
                .init(color: color.opacity(0), location: 1),
            ]), center: .zero, startRadius: 0, endRadius: radius
        ))
    }

    private func drawCore(in context: GraphicsContext, size: CGSize) {
        guard configuration.coreLight > 0 else { return }
        drawSoftEllipse(
            in: context, x: size.width / 2 + frame.center, y: size.height + 2,
            radiusX: 24 * configuration.coreLightWidth * configuration.coreSize * configuration.scale,
            radiusY: 30 * configuration.coreLightHeight * configuration.coreSize * configuration.scale,
            color: theme == .light ? BeamRGB(197, 139, 255).color : .white,
            alpha: min(0.7, configuration.coreLight * 0.23 * configuration.strength * frame.glow),
            softness: configuration.softness
        )
    }

    private func drawEdge(in context: GraphicsContext, size: CGSize) {
        let colors = palette
        let strokeAlpha = min(1, (theme == .dark ? 1.16 : 1.2) * configuration.strokeOpacity
                              * configuration.strength * frame.glow)
        guard strokeAlpha > 0.001 else { return }
        let half = max(12, 170 * configuration.rangeWidth * frame.width * configuration.scale * frame.maskWidth)
        let center = size.width / 2 + frame.center
        let stops = colors.enumerated().map { index, item in
            Gradient.Stop(color: item.adjusted(saturation: configuration.saturation,
                                               brightness: configuration.brightness,
                                               hueDegrees: frame.hue).opacity(strokeAlpha),
                          location: Double(index) / Double(colors.count - 1))
        }
        let gradient = Gradient(stops: stops)
        var stroke = context
        let bottom = CGRect(x: 0, y: max(0, size.height - max(3, configuration.borderRadius) - 1),
                            width: size.width, height: max(3, configuration.borderRadius) + 1)
        stroke.clip(to: Path(bottom))
        let shape = Path(roundedRect: CGRect(origin: .zero, size: size),
                         cornerRadius: min(configuration.borderRadius, size.height / 2))
        stroke.stroke(shape, with: .linearGradient(gradient,
            startPoint: CGPoint(x: center - half * configuration.strokeScale, y: size.height),
            endPoint: CGPoint(x: center + half * configuration.strokeScale, y: size.height)),
            lineWidth: max(0.7, configuration.scale))
    }

    private func drawBand(in context: GraphicsContext, size: CGSize) {
        let strength = min(1, 0.6 * configuration.bandStrength * configuration.strength
                           * frame.intensity * (1 - frame.processingMorph * 0.2))
        guard strength > 0.006, configuration.bandWidth > 0 else { return }
        let colors = configuration.bandColors.resolved(for: theme)
        let center = size.width / 2 + frame.center
        let half = max(1, 170 * configuration.rangeWidth * frame.width * frame.maskWidth * configuration.scale)
        let apex = min(size.height * 0.82 * min(1, configuration.scale),
                       (64 * configuration.rangeHeight * frame.height + configuration.bend * frame.intensity)
                       * configuration.bandPosition)
        let tail = configuration.bandTail * (1 - frame.processingMorph)
        let over = tail > 0 ? configuration.bandTailOverflow * configuration.scale : 0
        let x0 = tail > 0 ? -over : center - half
        let x1 = tail > 0 ? size.width + over : center + half
        var path = Path()
        for i in 0...64 {
            let x = x0 + (x1 - x0) * Double(i) / 64
            let t = min(1, max(-1, (x - center) / half))
            let skewed = max(0.05, configuration.bandSpread * (t < 0 ? 1 - configuration.bandSkew : 1 + configuration.bandSkew))
            let tailBase = exp(-pow(1 / skewed, max(0.5, configuration.bandCurve)))
            let bell = max(0, (exp(-pow(abs(t) / skewed, max(0.5, configuration.bandCurve))) - tailBase)
                           / max(0.001, 1 - tailBase))
            let edge = (x < center ? center : size.width - center) + over
            let start = edge * min(0.98, max(0, configuration.bandTailPosition))
            let distance = abs(x - center)
            let tailRise = distance <= start ? 0 : tail * pow(min(1, (distance - start) / max(1, edge - start)),
                                                             max(0.5, configuration.bandTailCurve))
            let y = size.height - configuration.bandOffset * configuration.scale - apex * (bell + tailRise)
                - frame.processingMorph * cornerLift(x: x, size: size)
            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        let split = configuration.bandAberration * (0.35 + 0.65 * frame.level)
        let dy = (4 + 12 * split) * configuration.scale
        let dx = 4 * split * configuration.scale
        drawRidge(path, in: context, color: colors.core, size: size, x: 0, y: 0,
                  alpha: strength * 0.65, width: configuration.bandWidth * configuration.scale * 3.0,
                  blur: configuration.bandWidth * configuration.glowSize * 4)
        drawRidge(path, in: context, color: colors.above, size: size, x: dx, y: -dy,
                  alpha: strength * 0.4, width: configuration.bandWidth * configuration.scale * 2.0,
                  blur: configuration.bandWidth * configuration.glowSize * 2)
        drawRidge(path, in: context, color: colors.mid, size: size, x: dx * 0.35, y: -dy * 0.35,
                  alpha: strength * 0.35, width: configuration.bandWidth * configuration.scale * 1.5,
                  blur: configuration.bandWidth * configuration.glowSize)
        drawRidge(path, in: context, color: colors.below, size: size, x: -dx, y: dy,
                  alpha: strength * 0.4, width: configuration.bandWidth * configuration.scale * 2.0,
                  blur: configuration.bandWidth * configuration.glowSize * 2)
        drawRidge(path, in: context, color: colors.core, size: size, x: 0, y: 0,
                  alpha: strength * 0.9, width: max(0.6, configuration.bandWidth * configuration.scale * 0.75),
                  blur: 0)
    }

    private func drawRidge(_ path: Path, in context: GraphicsContext, color: BeamRGB,
                           size: CGSize, x: Double, y: Double, alpha: Double, width: Double, blur: Double) {
        var layer = context
        layer.translateBy(x: x, y: y)
        if blur > 0 { layer.addFilter(.blur(radius: blur)) }
        layer.stroke(path, with: .color(color.adjusted(saturation: configuration.saturation,
                                                       brightness: configuration.brightness,
                                                       hueDegrees: frame.hue).opacity(alpha)),
                     style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func wrapped(_ x: Double, span: Double) -> Double {
        guard span > 0 else { return 0 }
        let half = span / 2
        return ((x + half).truncatingRemainder(dividingBy: span) + span)
            .truncatingRemainder(dividingBy: span) - half
    }

    private func cornerLift(x: Double, size: CGSize) -> Double {
        let radius = max(0, min(configuration.borderRadius, size.width / 2, size.height / 2))
        let distance = min(x, size.width - x)
        if distance >= radius { return 0 }
        if distance <= 0 { return radius }
        let dx = radius - distance
        return radius - sqrt(max(0, radius * radius - dx * dx))
    }
}
