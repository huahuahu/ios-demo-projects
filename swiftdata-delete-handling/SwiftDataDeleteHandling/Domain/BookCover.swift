import SwiftData

@Model
final class BookCover {
    var caption: String
    var colorName: String
    var book: Book?

    init(caption: String, colorName: String, book: Book? = nil) {
        self.caption = caption
        self.colorName = colorName
        self.book = book
    }
}
