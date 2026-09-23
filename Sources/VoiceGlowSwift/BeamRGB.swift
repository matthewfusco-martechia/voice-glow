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
        let high = max(red, green, blue)
        let low = min(red, green, blue)
        let delta = high - low
        let sourceSaturation = high == 0 ? 0 : delta / high
        let hue: Double
        if delta == 0 {
            hue = 0
        } else if high == red {
            hue = (green - blue) / delta / 6
        } else if high == green {
            hue = ((blue - red) / delta + 2) / 6
        } else {
            hue = ((red - green) / delta + 4) / 6
        }
        let shifted = (hue + hueDegrees / 360).truncatingRemainder(dividingBy: 1)
        return Color(
            hue: shifted < 0 ? shifted + 1 : shifted,
            saturation: min(1, max(0, sourceSaturation * saturation)),
            brightness: min(1, max(0, high * brightness))
        )
    }
}
