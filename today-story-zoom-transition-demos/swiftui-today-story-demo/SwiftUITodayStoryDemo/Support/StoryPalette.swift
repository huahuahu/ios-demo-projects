import SwiftUI

enum StoryPalette {
    static func gradient(for index: Int, colorScheme: ColorScheme) -> LinearGradient {
        let palettes: [[Color]]

        if colorScheme == .dark {
            palettes = [
                [Color(red: 0.10, green: 0.21, blue: 0.40), Color(red: 0.33, green: 0.16, blue: 0.42)],
                [Color(red: 0.42, green: 0.18, blue: 0.14), Color(red: 0.29, green: 0.24, blue: 0.10)],
                [Color(red: 0.08, green: 0.31, blue: 0.25), Color(red: 0.10, green: 0.18, blue: 0.35)],
                [Color(red: 0.15, green: 0.13, blue: 0.38), Color(red: 0.36, green: 0.12, blue: 0.31)],
                [Color(red: 0.08, green: 0.30, blue: 0.18), Color(red: 0.20, green: 0.28, blue: 0.08)],
                [Color(red: 0.11, green: 0.15, blue: 0.40), Color(red: 0.34, green: 0.13, blue: 0.45)]
            ]
        } else {
            palettes = [
                [Color(red: 0.20, green: 0.58, blue: 0.94), Color(red: 0.69, green: 0.35, blue: 0.86)],
                [Color(red: 0.98, green: 0.45, blue: 0.31), Color(red: 0.95, green: 0.73, blue: 0.24)],
                [Color(red: 0.18, green: 0.66, blue: 0.49), Color(red: 0.19, green: 0.47, blue: 0.84)],
                [Color(red: 0.35, green: 0.31, blue: 0.85), Color(red: 0.82, green: 0.29, blue: 0.63)],
                [Color(red: 0.19, green: 0.67, blue: 0.37), Color(red: 0.65, green: 0.73, blue: 0.22)],
                [Color(red: 0.24, green: 0.38, blue: 0.91), Color(red: 0.68, green: 0.28, blue: 0.88)]
            ]
        }

        let colors = palettes[index % palettes.count]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
