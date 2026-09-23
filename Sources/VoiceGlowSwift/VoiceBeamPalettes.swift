import SwiftUI

public enum VoiceBeamPalettes {
    public static func colors(for variant: VoiceBeamColorVariant, theme: VoiceBeamTheme) -> [BeamRGB] {
        let light = theme == .light
        switch variant {
        case .colorful:
            return light ? [BeamRGB(255, 201, 21), BeamRGB(126, 196, 255), BeamRGB(180, 40, 230), BeamRGB(235, 100, 160), BeamRGB(255, 176, 122), BeamRGB(154, 160, 255), BeamRGB(127, 217, 238)] : [BeamRGB(255, 70, 120), BeamRGB(60, 190, 255), BeamRGB(175, 70, 255), BeamRGB(60, 220, 130), BeamRGB(255, 150, 40), BeamRGB(90, 100, 255), BeamRGB(40, 200, 190)]
        case .mono:
            return light ? [BeamRGB(60, 60, 60), BeamRGB(90, 90, 90), BeamRGB(85, 85, 85), BeamRGB(110, 110, 110), BeamRGB(105, 105, 105), BeamRGB(125, 125, 125), BeamRGB(120, 120, 120)] : [BeamRGB(215, 215, 215), BeamRGB(180, 180, 180), BeamRGB(190, 190, 190), BeamRGB(160, 160, 160), BeamRGB(170, 170, 170), BeamRGB(150, 150, 150), BeamRGB(155, 155, 155)]
        case .ocean:
            return light ? [BeamRGB(40, 100, 240), BeamRGB(20, 160, 200), BeamRGB(90, 60, 230), BeamRGB(20, 130, 180), BeamRGB(130, 50, 220), BeamRGB(40, 80, 230), BeamRGB(20, 150, 150)] : [BeamRGB(80, 140, 255), BeamRGB(40, 200, 230), BeamRGB(120, 90, 255), BeamRGB(30, 170, 210), BeamRGB(160, 80, 240), BeamRGB(60, 110, 255), BeamRGB(40, 190, 180)]
        case .sunset:
            return light ? [BeamRGB(235, 80, 30), BeamRGB(230, 150, 10), BeamRGB(230, 30, 70), BeamRGB(225, 175, 30), BeamRGB(215, 40, 110), BeamRGB(235, 110, 20), BeamRGB(205, 30, 90)] : [BeamRGB(255, 110, 60), BeamRGB(255, 180, 40), BeamRGB(255, 60, 90), BeamRGB(255, 210, 80), BeamRGB(240, 70, 140), BeamRGB(255, 140, 50), BeamRGB(230, 50, 110)]
        case .forest:
            return light ? [BeamRGB(30, 170, 80), BeamRGB(20, 150, 130), BeamRGB(90, 180, 30), BeamRGB(20, 130, 100), BeamRGB(130, 180, 20), BeamRGB(30, 150, 80), BeamRGB(20, 120, 90)] : [BeamRGB(70, 220, 120), BeamRGB(40, 200, 180), BeamRGB(140, 230, 80), BeamRGB(30, 170, 140), BeamRGB(190, 235, 70), BeamRGB(50, 190, 110), BeamRGB(30, 150, 120)]
        case .candy:
            return light ? [BeamRGB(235, 40, 140), BeamRGB(230, 70, 190), BeamRGB(180, 40, 230), BeamRGB(235, 100, 160), BeamRGB(150, 70, 230), BeamRGB(230, 30, 110), BeamRGB(200, 60, 210)] : [BeamRGB(255, 90, 170), BeamRGB(255, 120, 220), BeamRGB(210, 80, 255), BeamRGB(255, 150, 190), BeamRGB(180, 110, 255), BeamRGB(255, 70, 140), BeamRGB(230, 100, 240)]
        case .ice:
            return light ? [BeamRGB(30, 160, 220), BeamRGB(20, 130, 210), BeamRGB(60, 180, 230), BeamRGB(40, 120, 220), BeamRGB(50, 160, 220), BeamRGB(20, 110, 220), BeamRGB(70, 170, 230)] : [BeamRGB(150, 230, 255), BeamRGB(90, 200, 255), BeamRGB(190, 240, 255), BeamRGB(120, 190, 255), BeamRGB(160, 220, 250), BeamRGB(80, 170, 255), BeamRGB(200, 235, 255)]
        case .gold:
            return light ? [BeamRGB(200, 140, 10), BeamRGB(190, 120, 0), BeamRGB(210, 160, 30), BeamRGB(180, 110, 0), BeamRGB(205, 170, 40), BeamRGB(175, 115, 5), BeamRGB(195, 150, 20)] : [BeamRGB(255, 200, 70), BeamRGB(255, 170, 40), BeamRGB(255, 220, 110), BeamRGB(240, 150, 30), BeamRGB(255, 235, 140), BeamRGB(230, 160, 40), BeamRGB(250, 210, 90)]
        }
    }
}
