import SwiftUI
import UIKit

struct UIKitInterruptibleDemoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> InterruptibleUIKitViewController {
        InterruptibleUIKitViewController()
    }

    func updateUIViewController(_ uiViewController: InterruptibleUIKitViewController, context: Context) {
    }
}
