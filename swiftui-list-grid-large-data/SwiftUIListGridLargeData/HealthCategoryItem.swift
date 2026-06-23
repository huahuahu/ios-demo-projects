import Foundation

struct HealthCategoryItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let subtitle: String
    let symbolName: String
    let palette: CategoryPalette
    let sampleCount: Int

    static func generatedItems(count: Int) -> [HealthCategoryItem] {
        guard count > 0 else { return [] }

        let templates = Template.allCases

        return (0..<count).map { index in
            let template = templates[index % templates.count]
            let ordinal = index + 1

            return HealthCategoryItem(
                id: ordinal,
                title: "\(template.title) \(ordinal)",
                subtitle: "\(1_000 + (ordinal * 37) % 84_000) samples",
                symbolName: template.symbolName,
                palette: template.palette,
                sampleCount: 1_000 + (ordinal * 37) % 84_000
            )
        }
    }
}

private extension HealthCategoryItem {
    enum Template: CaseIterable {
        case activity
        case heart
        case nutrition
        case bodyMeasurements
        case medications
        case mentalWellbeing
        case mobility
        case sleep

        var title: String {
            switch self {
            case .activity:
                "Activity"
            case .heart:
                "Heart"
            case .nutrition:
                "Nutrition"
            case .bodyMeasurements:
                "Body Measurements"
            case .medications:
                "Medications"
            case .mentalWellbeing:
                "Mental Wellbeing"
            case .mobility:
                "Mobility"
            case .sleep:
                "Sleep"
            }
        }

        var symbolName: String {
            switch self {
            case .activity:
                "flame.fill"
            case .heart:
                "heart.fill"
            case .nutrition:
                "apple.logo"
            case .bodyMeasurements:
                "figure.arms.open"
            case .medications:
                "pills.fill"
            case .mentalWellbeing:
                "brain.head.profile"
            case .mobility:
                "arrow.left.and.right"
            case .sleep:
                "bed.double.fill"
            }
        }

        var palette: CategoryPalette {
            switch self {
            case .activity:
                .orange
            case .heart:
                .pink
            case .nutrition:
                .green
            case .bodyMeasurements:
                .purple
            case .medications:
                .cyan
            case .mentalWellbeing:
                .teal
            case .mobility:
                .orange
            case .sleep:
                .indigo
            }
        }
    }
}
