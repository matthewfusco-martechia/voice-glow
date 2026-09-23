public struct VoiceBeamBandColors: Sendable {
    public var core: BeamRGB?
    public var above: BeamRGB?
    public var mid: BeamRGB?
    public var below: BeamRGB?

    public init(core: BeamRGB? = nil, above: BeamRGB? = nil, mid: BeamRGB? = nil, below: BeamRGB? = nil) {
        self.core = core
        self.above = above
        self.mid = mid
        self.below = below
    }

    func resolved(for theme: VoiceBeamTheme) -> (core: BeamRGB, above: BeamRGB, mid: BeamRGB, below: BeamRGB) {
        if theme == .light {
            return (core ?? BeamRGB(197, 139, 255), above ?? BeamRGB(255, 122, 182),
                    mid ?? BeamRGB(126, 196, 255), below ?? BeamRGB(45, 255, 171))
        }
        return (core ?? BeamRGB(255, 255, 255), above ?? BeamRGB(255, 70, 80),
                mid ?? BeamRGB(90, 255, 150), below ?? BeamRGB(80, 140, 255))
    }
}
