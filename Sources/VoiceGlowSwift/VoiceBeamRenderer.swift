import SwiftUI

/// The source effect is four separate compositing layers: inner light, a
/// one-point edge ring, a blurred bloom, and an organic chromatic band.
struct VoiceBeamRenderer: View {
    let frame: VoiceBeamFrame
    let configuration: VoiceBeamConfiguration
    let theme: VoiceBeamTheme

    private static let lobes: [(x: Double, width: Double, height: Double, band: Int)] = [
        (0, 74, 46, 0), (-36, 54, 40, 1), (36, 54, 40, 1),
        (-72, 48, 32, 2), (72, 48, 32, 2),
        (-108, 42, 26, 1), (108, 42, 26, 1),
    ]

    private enum Layer { case inner, stroke, bloom }

    var body: some View {
        Canvas(opaque: false, rendersAsynchronously: true) { context, size in
            guard size.width > 0, size.height > 0, configuration.strength > 0 else { return }
            var root = context
            root.clip(to: Path(roundedRect: CGRect(origin: .zero, size: size),
                               cornerRadius: paintedRadius(in: size)))
            drawSoftLayer(in: root, size: size, bloom: false)
            drawStroke(in: root, size: size)
            drawSoftLayer(in: root, size: size, bloom: true)
            let band = bandPath(in: size)
            drawBand(in: root, path: band)
            drawCoreLight(in: root, size: size, band: band)
        }
    }

    private var palette: [BeamRGB] {
        let defaults = VoiceBeamPalettes.colors(for: configuration.colorVariant, theme: theme)
        return defaults.enumerated().map { index, fallback in
            index < configuration.colors.count ? configuration.colors[index] : fallback
        }
    }

    private var hue: Double { frame.hue + (theme == .light ? 5 : 0) }
    private var layerGlow: Double { configuration.strength * frame.glow }

    private func paintedRadius(in size: CGSize) -> Double {
        max(0, min(configuration.borderRadius, size.width / 2, size.height / 2))
    }

    private func drawSoftLayer(in context: GraphicsContext, size: CGSize, bloom: Bool) {
        let preset = bloom ? (theme == .dark ? 0.89 : 0.5) : (theme == .dark ? 0.47 : 0.85)
        let multiplier = bloom ? configuration.bloomOpacity : configuration.innerOpacity
        let mono = configuration.colorVariant == .mono ? 0.6 : 1
        let opacity = min(1, preset * multiplier * layerGlow * mono)
        guard opacity > 0.001 else { return }

        var composited = context
        composited.opacity = opacity
        composited.drawLayer { layer in
            if bloom {
                var softened = layer
                softened.addFilter(.blur(radius: max(0.5, 10 * configuration.glowSize * configuration.scale)))
                drawLobes(in: softened, size: size, layer: .bloom)
            } else {
                drawLobes(in: layer, size: size, layer: .inner)
            }
            var mask = layer
            mask.blendMode = .destinationIn
            drawEdgeMask(in: mask, size: size, bloom: bloom, inner: !bloom)
            if !bloom {
                var corners = layer
                corners.blendMode = .destinationIn
                drawInnerCornerMask(in: corners, size: size)
            }
        }
    }

    private func drawStroke(in context: GraphicsContext, size: CGSize) {
        let preset = theme == .dark ? 1.16 : 1.2
        let mono = configuration.colorVariant == .mono ? 0.6 : 1
        let opacity = min(1, preset * configuration.strokeOpacity * layerGlow * mono)
        guard opacity > 0.001 else { return }

        let bounds = CGRect(origin: .zero, size: size)
        let width = 1.0 // The source keeps its edge at one CSS px.
        var ring = Path(roundedRect: bounds, cornerRadius: paintedRadius(in: size))
        ring.addPath(Path(roundedRect: bounds.insetBy(dx: width, dy: width),
                          cornerRadius: max(0, paintedRadius(in: size) - width)))

        var composited = context
        composited.opacity = opacity
        composited.drawLayer { layer in
            var contents = layer
            contents.clip(to: ring, style: FillStyle(eoFill: true))
            drawLobes(in: contents, size: size, layer: .stroke)
            drawEdgeHighlight(in: contents, size: size)

            var mask = layer
            mask.blendMode = .destinationIn
            drawEdgeMask(in: mask, size: size, bloom: false, inner: false)
        }
    }

    private func drawLobes(in context: GraphicsContext, size: CGSize, layer: Layer) {
        let span = 252 * configuration.lobeSpacing * configuration.scale
        let reach = 30 * configuration.scale * frame.width
        let radius = paintedRadius(in: size)
        let fade = min(0.95, max(0.4, (70 * configuration.softness).rounded() / 100))
        let gradientFade = layer == .bloom ? min(0.95, fade + 0.02) : fade
        let lobeAlpha = layer == .inner ? 0.46 : layer == .bloom ? (theme == .dark ? 0.9 : 0.7) : 1
        let colors = palette

        // CSS puts the first background gradient on top, so paint backward.
        for index in Self.lobes.indices.reversed() {
            let spec = Self.lobes[index]
            let offset = wrapped(spec.x * configuration.lobeSpacing * configuration.scale + frame.phase,
                                 span: span)
            let envelope = max(0, 1 - pow(offset / (span / 2 + 4), 2))
            let bandLevel = [frame.low, frame.mid, frame.high][spec.band]
            let amplitude = (configuration.bands ? 0.6 + 0.7 * bandLevel : 1) * envelope
            guard amplitude > 0.001 else { continue }
            let x = size.width / 2 + (frame.center + offset * frame.gather) * frame.width
            let lift = cornerLift(at: x, width: size.width, radius: radius, influence: reach)
                * frame.processingMorph * configuration.cornerFollow
            let y = size.height + (layer == .stroke ? 2 * configuration.scale : 0) - lift
            let layerWidth: Double
            let layerHeight: Double
            switch layer {
            case .inner:
                layerWidth = 0.9 * configuration.innerScale
                layerHeight = 0.9 * configuration.innerScale * configuration.innerHeight
            case .stroke:
                layerWidth = configuration.strokeScale
                layerHeight = configuration.strokeScale
            case .bloom:
                layerWidth = 1.15 * configuration.bloomScale
                layerHeight = 1.5 * configuration.bloomScale * configuration.bloomHeight
            }
            let rx = spec.width * configuration.glowWidth * configuration.scale
                * layerWidth * frame.width
            let ry = spec.height * configuration.glowHeight * configuration.scale
                * layerHeight * frame.height * amplitude
            let color = colors[index].adjusted(saturation: configuration.saturation,
                                                brightness: configuration.brightness,
                                                hueDegrees: hue)
            drawEllipse(in: context, size: size, x: x, y: y, rx: rx, ry: ry,
                        stops: [
                            .init(color: color.opacity(lobeAlpha), location: 0),
                            .init(color: color.opacity(0), location: gradientFade),
                            .init(color: color.opacity(0), location: 1),
                        ])
        }
    }

    private func drawEdgeHighlight(in context: GraphicsContext, size: CGSize) {
        let dark = theme == .dark
        let color = dark ? Color.white : Color.black
        let centre = size.width / 2 + frame.center * frame.width
        let lift = cornerLift(at: centre, width: size.width, radius: paintedRadius(in: size),
                              influence: 42 * configuration.scale * frame.width)
            * frame.processingMorph * configuration.cornerFollow
        drawEllipse(in: context, size: size, x: centre,
                    y: size.height + 2 * configuration.scale - lift,
                    rx: (dark ? 30 : 40) * configuration.coreSize * configuration.scale * frame.width,
                    ry: 30 * configuration.coreSize * configuration.scale * frame.height,
                    stops: [
                        .init(color: color.opacity(dark ? 0.45 : 0.55), location: 0),
                        .init(color: color.opacity(dark ? 0.14 : 0.22), location: dark ? 0.3 : 0.35),
                        .init(color: color.opacity(0), location: dark ? 0.65 : 0.7),
                        .init(color: color.opacity(0), location: 1),
                    ])
    }

    private func drawEdgeMask(in context: GraphicsContext, size: CGSize,
                              bloom: Bool, inner: Bool) {
        let centre = size.width / 2 + frame.center * frame.width
        let lift = cornerLift(at: centre, width: size.width, radius: paintedRadius(in: size),
                              influence: 42 * configuration.scale * frame.width)
            * frame.processingMorph * configuration.cornerFollow
        let rx = (bloom ? 200 : 170) * configuration.rangeWidth * configuration.scale
            * frame.width * frame.maskWidth
        let ry = (bloom ? 130 : 64) * configuration.rangeHeight * configuration.scale
            * frame.height + configuration.bend * configuration.scale * frame.intensity
        var stops: [Gradient.Stop] = [
            .init(color: .white, location: 0),
            .init(color: .white.opacity(0.5), location: bloom ? 0.35 : 0.45),
        ]
        if inner { stops.append(.init(color: .white.opacity(0.3), location: 0.85)) }
        stops.append(.init(color: .white.opacity(0), location: 1))
        drawEllipse(in: context, size: size, x: centre, y: size.height - lift,
                    rx: rx, ry: ry, stops: stops, fillWholeCanvas: true)
    }

    /// The source's inner mask intersects its ellipse with the union of a
    /// vertical and horizontal edge fade. This keeps the inner layer along
    /// the host border rather than filling the entire lower phone screen.
    private func drawInnerCornerMask(in context: GraphicsContext, size: CGSize) {
        let fade = min(size.width / 2, size.height / 2, 28 * configuration.scale)
        guard fade > 0 else { return }
        let vertical = Gradient(stops: [
            .init(color: .white, location: 0),
            .init(color: .clear, location: fade / size.height),
            .init(color: .clear, location: 1 - fade / size.height),
            .init(color: .white, location: 1),
        ])
        let horizontal = Gradient(stops: [
            .init(color: .white, location: 0),
            .init(color: .clear, location: fade / size.width),
            .init(color: .clear, location: 1 - fade / size.width),
            .init(color: .white, location: 1),
        ])
        context.drawLayer { union in
            let box = Path(CGRect(origin: .zero, size: size))
            union.fill(box, with: .linearGradient(vertical, startPoint: .zero,
                                                 endPoint: CGPoint(x: 0, y: size.height)))
            union.fill(box, with: .linearGradient(horizontal, startPoint: .zero,
                                                 endPoint: CGPoint(x: size.width, y: 0)))
        }
    }

    private func drawEllipse(in context: GraphicsContext, size: CGSize,
                             x: Double, y: Double, rx: Double, ry: Double,
                             stops: [Gradient.Stop], fillWholeCanvas: Bool = false) {
        guard rx > 0.001, ry > 0.001 else { return }
        var local = context
        local.translateBy(x: x, y: y)
        let ratio = rx / ry
        local.scaleBy(x: ratio, y: 1)
        let rect = fillWholeCanvas
            ? CGRect(x: -x / ratio, y: -y, width: size.width / ratio, height: size.height)
            : CGRect(x: -ry, y: -ry, width: ry * 2, height: ry * 2)
        let shape = fillWholeCanvas ? Path(rect) : Path(ellipseIn: rect)
        local.fill(shape, with: .radialGradient(Gradient(stops: stops),
                                                center: .zero, startRadius: 0, endRadius: ry))
    }

    private func bandPath(in size: CGSize) -> Path {
        let centre = size.width / 2 + frame.center * frame.width
        let half = max(1, 170 * configuration.rangeWidth * configuration.scale
                       * frame.width * frame.maskWidth)
        let apex = min(size.height * 0.82 * min(1, configuration.scale),
                       (64 * configuration.rangeHeight * configuration.scale * frame.height
                        + configuration.bend * configuration.scale * frame.intensity)
                       * configuration.bandPosition)
        let blend = min(1, frame.processingMorph * 4)
        let tail = configuration.bandTail * (1 - blend * blend * (3 - 2 * blend))
        let over = tail > 0.001 ? configuration.bandTailOverflow * configuration.scale : 0
        let x0 = tail > 0.001 ? -over : centre - half
        let x1 = tail > 0.001 ? size.width + over : centre + half
        var path = Path()
        for index in 0...56 {
            let x = x0 + (x1 - x0) * Double(index) / 56
            let t = min(1, max(-1, (x - centre) / half))
            let skewed = max(0.05, configuration.bandSpread
                             * (t < 0 ? 1 - configuration.bandSkew : 1 + configuration.bandSkew))
            let exponent = max(0.3, configuration.bandCurve)
            let end = exp(-pow(1 / skewed, exponent))
            let bell = max(0, (exp(-pow(abs(t) / skewed, exponent)) - end) / max(0.001, 1 - end))
            let edge = (x < centre ? centre : size.width - centre) + over
            let start = edge * min(0.98, max(0, configuration.bandTailPosition))
            let u = min(1, max(0, (abs(x - centre) - start) / max(1, edge - start)))
            let tailLift = tail * pow(u, max(0.5, configuration.bandTailCurve))
            let arc = cornerLift(at: x, width: size.width, radius: paintedRadius(in: size))
                * frame.processingMorph
            let y = size.height - configuration.bandOffset * configuration.scale
                - apex * (bell + tailLift) - arc
            if index == 0 { path.move(to: CGPoint(x: x, y: y)) }
            else { path.addLine(to: CGPoint(x: x, y: y)) }
        }
        return path
    }

    private func drawBand(in context: GraphicsContext, path: Path) {
        let alpha = min(1, 0.6 * configuration.bandStrength * frame.intensity)
        guard alpha >= 0.005, configuration.bandWidth > 0 else { return }
        let colors = configuration.bandColors.resolved(for: theme)
        let bandWidth = configuration.bandWidth * configuration.scale
        let thickness = 14 * bandWidth * (1 + 0.35 * frame.level)
        let blur = 3.5 * bandWidth / 2
        let split = configuration.bandAberration * (0.35 + 0.65 * frame.level)
        let dx = 4 * split * configuration.scale
        let dy = (4 + 12 * split) * configuration.scale
        let base = (theme == .dark ? 0.42 : 0.4) * alpha * configuration.strength
        let bounds = path.boundingRect

        var halo = context
        halo.addFilter(.blur(radius: blur * 3))
        drawRidge(path, in: halo, color: colors.core, x0: bounds.minX, x1: bounds.maxX,
                  alpha: base * 0.3, width: thickness * 2.2)

        var ridge = context
        ridge.addFilter(.blur(radius: blur))
        let ramp: [(width: Double, alpha: Double)] = [(1, 0.16), (0.72, 0.2),
                                                       (0.46, 0.26), (0.22, 0.34)]
        let strands: [(color: BeamRGB, strength: Double, x: Double, y: Double)] = [
            (colors.above, 1, dx, -dy),
            (colors.mid, 0.55, dx * 0.35, -dy * 0.35),
            (colors.below, 1, -dx, dy),
            (colors.core, 0.9, 0, 0),
        ]
        for strand in strands {
            var shifted = ridge
            shifted.translateBy(x: strand.x, y: strand.y)
            for stop in ramp {
                drawRidge(path, in: shifted, color: strand.color, x0: bounds.minX,
                          x1: bounds.maxX, alpha: base * strand.strength * stop.alpha,
                          width: max(0.6, thickness * stop.width))
            }
        }
    }

    private func drawRidge(_ path: Path, in context: GraphicsContext,
                           color: BeamRGB, x0: Double, x1: Double,
                           alpha: Double, width: Double) {
        let fade = configuration.bandTail > 0 ? 0.015 : 0.18
        // The source draws raw band colours on canvas, then applies the
        // shared hue, brightness, and saturation filter to that canvas.
        let tinted = color.adjusted(saturation: configuration.saturation,
                                    brightness: configuration.brightness, hueDegrees: hue)
        let gradient = Gradient(stops: [
            .init(color: tinted.opacity(0), location: 0),
            .init(color: tinted.opacity(alpha), location: fade),
            .init(color: tinted.opacity(alpha), location: 1 - fade),
            .init(color: tinted.opacity(0), location: 1),
        ])
        context.stroke(path, with: .linearGradient(gradient,
                         startPoint: CGPoint(x: x0, y: 0), endPoint: CGPoint(x: x1, y: 0)),
                       style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
    }

    private func drawCoreLight(in context: GraphicsContext, size: CGSize, band: Path) {
        guard configuration.coreLight > 0 else { return }
        let power = min(3, configuration.coreLight)
        let boost = max(0, power - 1)
        let first = min(1, boost)
        let second = max(0, boost - 1)
        let grow = 1 + 0.3 * boost
        let solid = (45 * first + 27 * second) / 100
        let middle = (40 + 25 * first + 15 * second) / 100
        let end = (72 + 14 * first + 8 * second) / 100
        let opacity = min(1, frame.glow * min(1, power) * (1.6 + 1.4 * boost))
        var below = band
        below.addLine(to: CGPoint(x: size.width, y: size.height))
        below.addLine(to: CGPoint(x: 0, y: size.height))
        below.closeSubpath()
        var softened = context
        softened.opacity = opacity
        softened.addFilter(.blur(radius: max(0.5, 8 * configuration.glowSize * configuration.scale)))
        softened.drawLayer { layer in
            var clipped = layer
            clipped.clip(to: below)
            drawEllipse(in: clipped, size: size,
                        x: size.width / 2 + frame.center * frame.width, y: size.height,
                        rx: 120 * configuration.coreLightWidth * grow * configuration.scale * frame.width,
                        ry: 70 * configuration.coreLightHeight * grow * configuration.scale
                            * frame.height + configuration.bend * configuration.scale * frame.intensity,
                        stops: [
                            .init(color: .white, location: 0),
                            .init(color: .white, location: solid),
                            .init(color: .white.opacity(min(1, 0.55 + 0.35 * first + 0.1 * second)),
                                  location: middle),
                            .init(color: .white.opacity(0), location: end),
                            .init(color: .white.opacity(0), location: 1),
                        ])
        }
    }

    private func cornerLift(at x: Double, width: Double, radius: Double,
                            influence: Double = 0) -> Double {
        guard radius > 0 else { return 0 }
        let distance = min(x, width - x) - influence
        if distance >= radius { return 0 }
        if distance <= 0 { return radius }
        let dx = radius - distance
        return radius - sqrt(max(0, radius * radius - dx * dx))
    }

    private func wrapped(_ x: Double, span: Double) -> Double {
        guard span > 0 else { return 0 }
        let half = span / 2
        return ((x + half).truncatingRemainder(dividingBy: span) + span)
            .truncatingRemainder(dividingBy: span) - half
    }
}
