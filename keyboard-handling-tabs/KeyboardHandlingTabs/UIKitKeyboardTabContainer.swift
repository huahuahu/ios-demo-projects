import SwiftUI
import UIKit

struct UIKitKeyboardTabContainer: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        UINavigationController(rootViewController: UIKitKeyboardViewController())
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {
        // No-op: demo state is maintained inside UIKitKeyboardViewController.
    }
}
