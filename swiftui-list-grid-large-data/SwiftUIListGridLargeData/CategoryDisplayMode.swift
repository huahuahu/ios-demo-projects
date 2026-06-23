import Foundation

enum CategoryDisplayMode: String, CaseIterable, Identifiable {
    case list
    case grid

    var id: Self { self }

    var title: String {
        switch self {
        case .list:
            "List"
        case .grid:
            "Grid"
        }
    }

    var systemImage: String {
        switch self {
        case .list:
            "list.bullet"
        case .grid:
            "square.grid.2x2"
        }
    }

    static func launchMode(from arguments: [String] = ProcessInfo.processInfo.arguments) -> CategoryDisplayMode? {
        guard let flagIndex = arguments.firstIndex(of: "--display-mode") else { return nil }
        let valueIndex = arguments.index(after: flagIndex)
        guard arguments.indices.contains(valueIndex) else { return nil }

        return CategoryDisplayMode(rawValue: arguments[valueIndex])
    }
}
