import UIKit

@MainActor
enum GlassFactory {
    static func effectView(
        style: UIGlassEffect.Style = .regular,
        interactive: Bool = false
    ) -> UIVisualEffectView {
        let effect = UIGlassEffect(style: style)
        effect.isInteractive = interactive
        let view = UIVisualEffectView(effect: effect)
        view.clipsToBounds = true
        view.layer.cornerCurve = .continuous
        return view
    }

    static func symbolButton(
        systemName: String,
        accessibilityLabel: String,
        action: UIAction
    ) -> UIButton {
        var configuration = UIButton.Configuration.glass()
        configuration.image = UIImage(systemName: systemName)
        configuration.baseForegroundColor = .label
        configuration.cornerStyle = .capsule

        let button = UIButton(configuration: configuration, primaryAction: action)
        button.accessibilityLabel = accessibilityLabel
        return button
    }
}
