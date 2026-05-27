import SwiftUI

struct ContentView: View {
    @StateObject private var router = NavigationRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            InboxView(router: router)
                .navigationTitle("Navigation")
                .navigationDestination(for: NavigationRoute.self) { route in
                    destination(for: route)
                }
        }
    }

    @ViewBuilder
    private func destination(for route: NavigationRoute) -> some View {
        switch route {
        case .collection(let id):
            CollectionView(collectionID: id, router: router)
        case .message(let id):
            MessageDetailView(messageID: id, router: router)
        case .composer(let replyTo):
            ComposerView(replyTo: replyTo, router: router)
        }
    }
}

private struct InboxView: View {
    @ObservedObject var router: NavigationRouter

    var body: some View {
        List {
            if !router.path.isEmpty {
                RoutePathSection(path: router.path)
            }

            Section("Collections") {
                ForEach(DemoData.collections) { collection in
                    NavigationLink(value: NavigationRoute.collection(collection.id)) {
                        Label(collection.title, systemImage: collection.symbolName)
                    }
                }
            }

            Section("Messages") {
                ForEach(DemoData.messages.prefix(3)) { message in
                    MessageRow(message: message)
                }
            }

            Section("Actions") {
                if let first = DemoData.messages.first {
                    Button {
                        router.openDeepLink(to: first)
                    } label: {
                        Label("Open Deep Link", systemImage: "link")
                    }
                }

                Button {
                    router.compose()
                } label: {
                    Label("Compose", systemImage: "square.and.pencil")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !router.path.isEmpty {
                    Button("Root") {
                        router.popToRoot()
                    }
                }
            }
        }
    }
}

private struct CollectionView: View {
    let collectionID: String
    @ObservedObject var router: NavigationRouter

    private var collection: DemoCollection? {
        DemoData.collection(id: collectionID)
    }

    var body: some View {
        List {
            RoutePathSection(path: router.path)

            ForEach(DemoData.messages(in: collectionID)) { message in
                MessageRow(message: message)
            }
        }
        .navigationTitle(collection?.title ?? "Collection")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Back") {
                    router.pop()
                }

                Button("Root") {
                    router.popToRoot()
                }
            }
        }
    }
}

private struct MessageDetailView: View {
    let messageID: Int
    @ObservedObject var router: NavigationRouter

    private var message: DemoMessage? {
        DemoData.message(id: messageID)
    }

    var body: some View {
        List {
            RoutePathSection(path: router.path)

            if let message {
                Section("Message") {
                    LabeledContent("From", value: message.sender)
                    Text(message.preview)
                }

                Section("Actions") {
                    Button {
                        router.compose(replyTo: message)
                    } label: {
                        Label("Reply", systemImage: "arrowshape.turn.up.left")
                    }
                }
            } else {
                ContentUnavailableView("Message Not Found", systemImage: "envelope.badge")
            }
        }
        .navigationTitle(message?.title ?? "Message")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Root") {
                    router.popToRoot()
                }
            }
        }
    }
}

private struct ComposerView: View {
    let replyTo: Int?
    @ObservedObject var router: NavigationRouter

    private var message: DemoMessage? {
        replyTo.flatMap(DemoData.message(id:))
    }

    var body: some View {
        Form {
            RoutePathSection(path: router.path)

            Section("Compose") {
                TextField("Subject", text: .constant(message.map { "Re: \($0.title)" } ?? ""))
                TextEditor(text: .constant(""))
                    .frame(minHeight: 140)
            }

            Section("Actions") {
                Button {
                    router.popToRoot()
                } label: {
                    Label("Send and Return", systemImage: "paperplane")
                }
            }
        }
        .navigationTitle("Compose")
    }
}

private struct MessageRow: View {
    let message: DemoMessage

    var body: some View {
        NavigationLink(value: NavigationRoute.message(message.id)) {
            VStack(alignment: .leading, spacing: 4) {
                Text(message.title)
                    .font(.headline)
                Text(message.sender)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(message.preview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .padding(.vertical, 4)
        }
    }
}

private struct RoutePathSection: View {
    let path: [NavigationRoute]

    var body: some View {
        Section("Route Path") {
            if path.isEmpty {
                Text("Root")
                    .foregroundStyle(.secondary)
            } else {
                Text(path.map(\.title).joined(separator: " / "))
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ContentView()
}
