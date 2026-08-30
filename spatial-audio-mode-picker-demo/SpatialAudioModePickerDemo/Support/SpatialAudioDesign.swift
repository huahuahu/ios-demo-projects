import SwiftUI

enum SpatialAudioDesign {
    static let compactDiameter = 68.0
    static let controlHeight = 68.0
    static let expandedWidth = 300.0
    static let indicatorDiameter = 54.0
    static let slotWidth = 92.0
    static let labelHeight = 46.0

    static let expansionAnimation = Animation.spring(
        response: 0.34,
        dampingFraction: 0.82
    )

    static let selectionAnimation = Animation.spring(
        response: 0.24,
        dampingFraction: 0.86
    )

    static let labelAnimation = Animation.easeOut(duration: 0.16)
}
