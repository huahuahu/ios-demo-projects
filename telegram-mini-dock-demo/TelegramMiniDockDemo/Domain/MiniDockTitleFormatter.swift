enum MiniDockTitleFormatter {
    static func collapsedTitle(
        titles: [String],
        maximumLastTitleLength: Int = 24
    ) -> String {
        guard let last = titles.last else { return "" }
        guard titles.count > 1 else { return last }

        let shortened = last.count > maximumLastTitleLength
            ? String(last.prefix(maximumLastTitleLength)) + "…"
            : last
        return "\(shortened) 及其他 \(titles.count - 1) 个"
    }
}
