import Foundation

enum ItemMutationEngine {
    static func makeInitialItems(count: Int = 24) -> [DemoItem] {
        (1...count).map { DemoItem(title: "Item \($0)") }
    }

    static func makeNextItems(from current: [DemoItem], step: Int) -> [DemoItem] {
        var next = current

        if next.count > 8 {
            let removeCount = min(2, max(1, next.count / 6))
            for _ in 0..<removeCount where !next.isEmpty {
                let index = Int.random(in: 0..<next.count)
                next.remove(at: index)
            }
        }

        for insertion in 0..<2 {
            let item = DemoItem(title: "New \(step)-\(insertion + 1)")
            let index = next.isEmpty ? 0 : Int.random(in: 0...next.count)
            next.insert(item, at: index)
        }

        if next.count > 3 {
            let left = Int.random(in: 0..<next.count)
            let right = Int.random(in: 0..<next.count)
            next.swapAt(left, right)
        }

        return next
    }
}
