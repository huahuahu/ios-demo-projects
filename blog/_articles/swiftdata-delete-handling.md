---
title: SwiftData 删除后，SwiftUI 详情页为什么不能继续持有 @Bindable model
description: 用一个两入口 demo 复现 SwiftData model 被后台 context 删除后详情页不自动退出、旧实例状态不可靠、relationship fault 崩溃的问题，并记录 persistentModelID + @Query 的修复方案。
summary: SwiftData 详情页长期持有 @Bindable model 时，后台删除可能让页面继续触碰 invalidated object；更稳妥的做法是传 persistentModelID，再用 @Query 反查并在结果为空时 dismiss。
category: Investigation
tag: SwiftData
date: 2026-07-05
demo_url: https://github.com/huahuahu/ios-demo-projects/tree/main/swiftdata-delete-handling
---

## 问题从哪里来

这次实验想搞清楚一个 SwiftData + SwiftUI 导航里的坑：列表进入详情页时，如果详情页直接接收并持有 `@Bindable var book`，然后另一个 `ModelContext` 把这本书删掉并 `save()`，详情页会发生什么？

直觉上，我们可能会期待主 context 合并变更后，详情页发现这条数据没了，于是自动 pop 回列表。但实际并不一定。页面可能继续停留，顶部状态还显示：

```text
book.isDeleted: false
book.modelContext: attached
```

同时，用 fresh context 再查同一个 `persistentModelID`，已经查不到这条数据。也就是说，详情页手里的旧 model 实例和 store 的真实状态已经分叉了。

这个分叉很危险：普通字符串属性可能因为还在内存里缓存着，读起来“不崩”；但如果后续触碰尚未 materialize 的 relationship，或者用已删除 ID 重新制造 fault，再读取属性，就可能触发 SwiftData/CoreData 的 invalidated-object 崩溃。

## Demo 的结构

Demo 在 `swiftdata-delete-handling/`，用 XcodeGen 生成。第一屏只有两个入口：

1. **问题：详情页持有 `@Bindable var book`**
2. **解决：传 `persistentModelID` 后用 `@Query` 反查**

两个入口都用同一个后台删除器：

```swift
@ModelActor
actor BackgroundBookDeleter {
    func delete(bookID: PersistentIdentifier) throws -> Bool {
        guard let book = modelContext.model(for: bookID) as? Book else {
            return false
        }

        modelContext.delete(book)
        try modelContext.save()
        return true
    }
}
```

关键点是删除发生在另一个 `ModelContext` 里，而详情页还留在当前导航栈上。

## 为什么顶部状态没有变化

问题页的详情视图是这样接收数据的：

```swift
struct BindableProblemDetailView: View {
    @Bindable var book: Book
    let modelContainer: ModelContainer
}
```

删除后，页面顶部读取的是这个旧实例：

```swift
LabeledContent("book.isDeleted（旧实例）", value: book.isDeleted ? "true" : "false")
LabeledContent("book.modelContext（旧实例）", value: book.modelContext == nil ? "nil" : "attached")
```

这些值不是一次 fresh fetch。它们描述的是当前 context 中这个 model wrapper 的状态，不等价于“store 里是否还有这条 row”。所以我们额外加了一个 fresh context 检查：

```swift
let freshContext = ModelContext(modelContainer)
let existsInStore = try BookStore.containsBook(with: bookID, in: freshContext)
storeLookupStatus = existsInStore ? "仍能 fetch 到" : "nil（store 已删除）"
```

实验结果是：fresh context 已经查不到对象，但旧 `@Bindable` 实例仍可能显示 `isDeleted == false`、`modelContext != nil`。这就是误导 UI 继续使用旧对象的根源。

## 为什么普通属性不一定崩

一开始我尝试在删除后读：

```swift
let staleSnapshot = """
title: \(book.title)
author: \(book.author)
notes: \(book.notes)
"""

book.title = "dd"
```

这不一定触发系统 crash。原因是 `title`、`author`、`notes` 这些标量属性很可能已经 materialize 到当前实例里了。删除发生在另一个 context 后，旧实例还能读到内存里的旧值。这个行为本身已经说明状态不可靠，但它不保证立刻崩。

所以如果文章想说明“继续持有旧 model 很危险”，不能只靠普通 String 字段。更容易暴露问题的是 relationship 或 fault。

## 用未 materialize 的 relationship 复现崩溃

Demo 里给 `Book` 增加了一个 relationship：

```swift
@Model
final class Book {
    var title: String
    var author: String
    var notes: String
    var scenarioRawValue: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \BookCover.book)
    var cover: BookCover?
}

@Model
final class BookCover {
    var caption: String
    var colorName: String
    var book: Book?
}
```

问题页故意不提前展示 `cover`，只在删除之后提供一个“读取旧 `book.cover` 关系”的按钮：

```swift
private func readUnmaterializedRelationship() {
    DemoLog.interaction.info("About to read stale Book.cover relationship")
    let coverCaption = book.cover?.caption ?? "nil"
    relationshipReadStatus = "读取完成：book.cover?.caption = \(coverCaption)。"
}
```

这次触发了 SwiftData 的系统级崩溃：

```text
Problem detail background delete completed: true
About to read stale Book.cover relationship
data store (...) did not return a snapshot for:
PersistentIdentifier(... <x-coredata://.../BookCover/p10>)
SwiftData/BackingData.swift:1039: Fatal error:
This model instance was invalidated because its backing data could no longer be found the store.
```

注意崩溃对象是 `BookCover/p10`，不是 `Book` 本身。也就是说，旧 `Book` 还在页面里，但它的 relationship 需要去 store 里 fault 出 `BookCover`；因为后台删除用了 cascade，cover 也已经没了，于是 SwiftData 无法 fulfill fault。

这解释了为什么“我读 `book.title` 没事”和“我读 `book.cover?.caption` 崩了”并不矛盾：前者可能读缓存，后者需要 fault。

## 用已删除 persistentModelID 复现更直接的 fault 崩溃

Demo 还保留了一个更强的按钮：用已删除的 `persistentModelID` 在新 context 里制造 fault，然后读取属性。

```swift
private func crashByReadingDeletedBookFault() {
    let bookID = book.persistentModelID
    let faultingContext = ModelContext(modelContainer)
    let deletedBookFault = faultingContext.model(for: bookID) as! Book

    DemoLog.interaction.info("About to read a deleted SwiftData Book fault: \(String(describing: bookID), privacy: .public)")
    _ = deletedBookFault.title
}
```

对应崩溃是：

```text
About to read a deleted SwiftData Book fault:
PersistentIdentifier(... <x-coredata://.../Book/p12>)
data store (...) did not return a snapshot for:
PersistentIdentifier(... <x-coredata://.../Book/p12>)
SwiftData/BackingData.swift:1039: Fatal error:
This model instance was invalidated because its backing data could no longer be found the store.
```

这说明 `persistentModelID` 只是对象身份，不是对象仍存在的证明。`model(for:)` 可以先返回一个 fault；真正读属性时，SwiftData 才需要从 store 取 snapshot。如果 row 已经被删除，fault fulfill 就会失败。

## 推荐修复：导航传 ID，详情页用 @Query 反查

解决入口不把 `Book` 直接传给详情页，而是传 `persistentModelID`：

```swift
NavigationLink {
    PersistentIDQueryFixDetailView(
        bookID: book.persistentModelID,
        modelContainer: modelContainer
    )
} label: {
    rowContent(isAvailable: true)
}
```

详情页内部用 `@Query` 根据 ID 反查：

```swift
struct PersistentIDQueryFixDetailView: View {
    let bookID: PersistentIdentifier
    let modelContainer: ModelContainer

    @Environment(\.dismiss) private var dismiss
    @Query private var books: [Book]

    private var book: Book? {
        books.first
    }

    init(bookID: PersistentIdentifier, modelContainer: ModelContainer) {
        self.bookID = bookID
        self.modelContainer = modelContainer
        _books = Query(filter: #Predicate<Book> { book in
            book.persistentModelID == bookID
        })
    }
}
```

当后台 context 删除并保存后，query 结果变空。页面不再继续访问旧 `Book`，而是 dismiss：

```swift
.onChange(of: books.isEmpty) { _, isEmpty in
    if isEmpty {
        dismiss()
    }
}
.task(id: books.isEmpty) {
    if books.isEmpty {
        dismiss()
    }
}
```

这比在详情页长期保存 `@Bindable var book` 更安全，因为 SwiftUI 的页面状态跟 SwiftData 查询结果绑定在一起：数据存在就展示，数据消失就退出。

## 另一个可选兜底：检测旧实例失效

如果暂时还不能改导航结构，也可以在继续持有 `@Bindable var book` 时加保护：

```swift
if book.isDeleted || book.modelContext == nil {
    // 停止访问 book 的业务属性，显示占位或 dismiss
}
```

但这只是兜底，不是我更推荐的主方案。本次实验里，跨 context 删除后旧实例的 `isDeleted` 和 `modelContext` 仍可能显示得很“正常”。所以真正可靠的边界还是 fresh query：以 store 当前查询结果为准，而不是相信旧 model wrapper。

## 可复现步骤

1. 打开 demo：`swiftdata-delete-handling/SwiftDataDeleteHandling.xcodeproj`。
2. 进入第一个入口“问题：详情页持有 `@Bindable var book`”。
3. 点击“用后台 context 删除这本书”。
4. 观察旧实例状态可能仍是 `book.isDeleted == false`、`book.modelContext == attached`，但 fresh context fetch 已经是 nil。
5. 点击“读取旧 `book.cover` 关系”，触发 relationship fault 崩溃。
6. 重启 app，进入第二个入口“解决：传 `persistentModelID` 后用 `@Query` 反查”。
7. 点击后台删除，详情页在 query 变空后自动 dismiss。

测试层面，`SwiftDataDeleteHandlingTests/Domain/BookStoreTests.swift` 覆盖了示例数据创建和后台 context 删除：

```swift
let didDelete = try await BackgroundBookDeleter(modelContainer: container)
    .delete(bookID: bookID)
let verificationContext = ModelContext(container)
let containsDeletedBook = try BookStore.containsBook(
    with: bookID,
    in: verificationContext
)

#expect(didDelete)
#expect(containsDeletedBook == false)
```

## 我学到的结论

- SwiftData model 实例不是“永远真实的数据库行”。跨 context 删除后，旧实例可能还在 UI 中存活。
- `book.isDeleted` 和 `book.modelContext == nil` 可以作为兜底信号，但不能替代 fresh query。
- 标量属性可能因为缓存而不崩；relationship 和 fault 更容易暴露 invalidated object。
- `persistentModelID` 是导航参数的好选择，但它不是存在性保证。需要配合 `@Query` 或 fetch 来确认对象仍存在。
- SwiftUI 详情页更安全的设计是：传 ID，查询当前数据，查不到就 dismiss，而不是长期持有 `@Bindable var book`。

## 后续可以补充

这篇文章目前还没有放截图。如果要发表，可以补一张两个入口的列表截图，以及一张问题页删除后 `fresh context fetch == nil` 但旧实例状态仍显示 attached 的截图。
