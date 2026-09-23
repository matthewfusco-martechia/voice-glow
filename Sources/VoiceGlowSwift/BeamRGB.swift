import SwiftUI

/// An RGB color used for palette and band overrides without a platform color dependency.
public struct BeamRGB: Hashable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    public init(_ red: Int, _ green: Int, _ blue: Int) {
        self.init(red: Double(red) / 255, green: Double(green) / 255, blue: Double(blue) / 255)
    }

    public init?(hex: String) {
        let value = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let expanded: String
        if value.count == 3 {
            expanded = value.map { "\($0)\($0)" }.joined()
        } else if value.count == 6 {
            expanded = value
        } else {
            return nil
        }
        guard let packed = Int(expanded, radix: 16) else { return nil }
        self.init((packed >> 16) & 255, (packed >> 8) & 255, packed & 255)
    }

    public var color: Color { Color(red: red, green: green, blue: blue) }

    func adjusted(saturation: Double, brightness: Double, hueDegrees: Double) -> Color {
        // CSS hue-rotate(), brightness(), saturate() are colour matrices,
        // not HSV operations. Keep their source order for closer parity.
        let angle = hueDegrees * .pi / 180
        let cosine = cos(angle)
        let sine = sin(angle)
        let hueRed = (0.213 + 0.787 * cosine - 0.213 * sine) * red
            + (0.715 - 0.715 * cosine - 0.715 * sine) * green
            + (0.072 - 0.072 * cosine + 0.928 * sine) * blue
        let hueGreen = (0.213 - 0.213 * cosine + 0.143 * sine) * red
            + (0.715 + 0.285 * cosine + 0.140 * sine) * green
            + (0.072 - 0.072 * cosine - 0.283 * sine) * blue
        let hueBlue = (0.213 - 0.213 * cosine - 0.787 * sine) * red
            + (0.715 - 0.715 * cosine + 0.715 * sine) * green
            + (0.072 + 0.928 * cosine + 0.072 * sine) * blue
        let r = hueRed * brightness
        let g = hueGreen * brightness
        let b = hueBlue * brightness
        let finalRed = (0.213 + 0.787 * saturation) * r
            + (0.715 - 0.715 * saturation) * g
            + (0.072 - 0.072 * saturation) * b
        let finalGreen = (0.213 - 0.213 * saturation) * r
            + (0.715 + 0.285 * saturation) * g
            + (0.072 - 0.072 * saturation) * b
        let finalBlue = (0.213 - 0.213 * saturation) * r
            + (0.715 - 0.715 * saturation) * g
            + (0.072 + 0.928 * saturation) * b
        return Color(red: min(1, max(0, finalRed)),
                     green: min(1, max(0, finalGreen)),
                     blue: min(1, max(0, finalBlue)))
    }
}
