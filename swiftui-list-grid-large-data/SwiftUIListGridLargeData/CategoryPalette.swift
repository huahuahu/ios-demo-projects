import SwiftUI

enum CategoryPalette: Int, CaseIterable, Sendable {
    case orange
    case pink
    case green
    case purple
    case cyan
    case teal
    case blue
    case indigo

    var colors: [Color] {
        switch self {
        case .orange:
            [Color(red: 1.0, green: 0.22, blue: 0.02), Color(red: 1.0, green: 0.58, blue: 0.34)]
        case .pink:
            [Color(red: 0.97, green: 0.10, blue: 0.32), Color(red: 1.0, green: 0.39, blue: 0.46)]
        case .green:
            [Color(red: 0.10, green: 0.76, blue: 0.30), Color(red: 0.43, green: 0.84, blue: 0.46)]
        case .purple:
            [Color(red: 0.70, green: 0.12, blue: 0.88), Color(red: 0.86, green: 0.34, blue: 0.88)]
        case .cyan:
            [Color(red: 0.06, green: 0.69, blue: 0.82), Color(red: 0.39, green: 0.82, blue: 0.89)]
        case .teal:
            [Color(red: 0.03, green: 0.73, blue: 0.64), Color(red: 0.39, green: 0.82, blue: 0.72)]
        case .blue:
            [Color(red: 0.02, green: 0.53, blue: 0.96), Color(red: 0.33, green: 0.66, blue: 0.96)]
        case .indigo:
            [Color(red: 0.32, green: 0.28, blue: 0.91), Color(red: 0.45, green: 0.48, blue: 0.95)]
        }
    }
}
