import SwiftUI

struct ContentView: View {
    @State private var router = Router()

    var body: some View {
        RootView()
            .environment(router)
            .onAppear {
                router.openColdLaunchDeepLink(
                    DeepLinkParser.deepLink(from: ProcessInfo.processInfo.arguments)
                )
            }
            .onOpenURL { url in
                guard let deepLink = DeepLinkParser.deepLink(from: url) else { return }
                router.openDeepLink(deepLink)
            }
    }
}

private struct RootView: View {
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router

        TabView(selection: $router.selectedTab) {
            NavigationStack(path: router.binding(for: .inbox)) {
                InboxView()
                    .navigationTitle(AppTab.inbox.title)
                    .navigationDestination(for: Route.self) { route in
                        DestinationView(route: route)
                    }
            }
            .tabItem {
                Label(AppTab.inbox.title, systemImage: AppTab.inbox.symbolName)
            }
            .tag(AppTab.inbox)

            NavigationStack(path: router.binding(for: .settings)) {
                SettingsView()
                    .navigationTitle(AppTab.settings.title)
                    .navigationDestination(for: Route.self) { route in
                        DestinationView(route: route)
                    }
            }
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.symbolName)
            }
            .tag(AppTab.settings)
        }
        .sheet(item: $router.sheet, onDismiss: router.applyDeferredDeepLinkIfReady) { node in
            PresentationNodeView(node: node) {
                router.dismissSheet()
            }
                .environment(router)
        }
        .fullScreenCover(item: $router.fullScreen, onDismiss: router.applyDeferredDeepLinkIfReady) { node in
            PresentationNodeView(node: node) {
                router.dismissFullScreen()
            }
                .environment(router)
        }
    }
}

private struct InboxView: View {
    @Environment(Router.self) private var router

    var body: some View {
        List {
            RouterStateSection()

            Section("Collections") {
                ForEach(DemoData.collections) { collection in
                    NavigationLink(value: Route.collection(collection.id)) {
                        Label(collection.title, systemImage: collection.symbolName)
                    }
                }
            }

            Section("Messages") {
                ForEach(DemoData.messages.prefix(3)) { message in
                    MessageRow(message: message)
                }
            }

            Section("Present") {
                Button {
                    router.presentSheet(.composer(replyTo: nil))
                } label: {
                    Label("Compose Sheet", systemImage: "square.and.pencil")
                }

                Button {
                    router.presentSheet(.filters)
                } label: {
                    Label("Filter Sheet", systemImage: "line.3.horizontal.decrease.circle")
                }

                if let message = DemoData.messages.first {
                    Button {
                        router.presentFullScreen(.messagePreview(message.id))
                    } label: {
                        Label("Preview Cover", systemImage: "rectangle.fill.on.rectangle.fill")
                    }
                }
            }

            Section("Deep Links") {
                if let first = DemoData.messages.first {
                    Button {
                        router.openDeepLink(.message(first))
                    } label: {
                        Label("Hot Link to Message", systemImage: "link")
                    }
                }

                if let setting = DemoData.settings.last {
                    Button {
                        router.openDeepLink(.settingsDetail(setting))
                    } label: {
                        Label("Hot Link to Settings", systemImage: "gearshape.2")
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Root") {
                    router.popToRoot(on: .inbox)
                }
            }
        }
    }
}

private struct SettingsView: View {
    @Environment(Router.self) private var router

    var body: some View {
        List {
            RouterStateSection()

            Section("Settings") {
                ForEach(DemoData.settings) { setting in
                    NavigationLink(value: Route.settingsDetail(setting.id)) {
                        Label(setting.title, systemImage: "gearshape")
                    }
                }
            }

            Section("Global Presentation") {
                Button {
                    router.presentFullScreen(.onboarding)
                } label: {
                    Label("Show Onboarding", systemImage: "sparkles")
                }

                Button {
                    router.presentSheet(.filters)
                } label: {
                    Label("Show Filters", systemImage: "slider.horizontal.3")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Root") {
                    router.popToRoot(on: .settings)
                }
            }
        }
    }
}

private struct DestinationView: View {
    let route: Route

    var body: some View {
        switch route {
        case .collection(let id):
            CollectionView(collectionID: id)
        case .message(let id):
            MessageDetailView(messageID: id)
        case .composer(let replyTo):
            ComposerPushView(replyTo: replyTo)
        case .settingsDetail(let id):
            SettingsDetailView(settingID: id)
        }
    }
}

private struct CollectionView: View {
    @Environment(Router.self) private var router
    let collectionID: String

    private var collection: DemoCollection? {
        DemoData.collection(id: collectionID)
    }

    var body: some View {
        List {
            RouterStateSection()

            ForEach(DemoData.messages(in: collectionID)) { message in
                MessageRow(message: message)
            }
        }
        .navigationTitle(collection?.title ?? "Collection")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button("Back") {
                    router.pop(on: .inbox)
                }

                Button("Root") {
                    router.popToRoot(on: .inbox)
                }
            }
        }
    }
}

private struct MessageDetailView: View {
    @Environment(Router.self) private var router
    let messageID: Int

    private var message: DemoMessage? {
        DemoData.message(id: messageID)
    }

    var body: some View {
        List {
            RouterStateSection()

            if let message {
                Section("Message") {
                    LabeledContent("From", value: message.sender)
                    Text(message.preview)
                }

                Section("Actions") {
                    Button {
                        router.push(.composer(replyTo: message.id), on: .inbox)
                    } label: {
                        Label("Push Reply", systemImage: "arrowshape.turn.up.left")
                    }

                    Button {
                        router.presentSheet(.composer(replyTo: message.id))
                    } label: {
                        Label("Sheet Reply", systemImage: "square.and.pencil")
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
                    router.popToRoot(on: .inbox)
                }
            }
        }
    }
}

private struct ComposerPushView: View {
    let replyTo: Int?

    var body: some View {
        ComposerForm(replyTo: replyTo, sendAction: nil)
            .navigationTitle("Compose")
    }
}

private struct SettingsDetailView: View {
    @Environment(Router.self) private var router
    let settingID: String

    private var setting: DemoSetting? {
        DemoData.setting(id: settingID)
    }

    var body: some View {
        List {
            RouterStateSection()

            if let setting {
                Section(setting.title) {
                    Text(setting.detail)
                }
            } else {
                ContentUnavailableView("Setting Not Found", systemImage: "gearshape")
            }

            Section("Actions") {
                Button {
                    router.presentSheet(.filters)
                } label: {
                    Label("Show Sheet", systemImage: "slider.horizontal.3")
                }
            }
        }
        .navigationTitle(setting?.title ?? "Settings")
    }
}

private struct PresentationNodeView: View {
    @Environment(Router.self) private var router
    @Bindable var node: PresentationNode
    let dismiss: () -> Void

    var body: some View {
        NavigationStack(path: $node.path) {
            PresentedRootView(node: node, dismiss: dismiss)
                .navigationDestination(for: Route.self) { route in
                    DestinationView(route: route)
                }
        }
        .sheet(item: $node.sheet) { child in
            PresentationNodeView(node: child) {
                node.dismissSheet()
            }
                .environment(router)
        }
        .fullScreenCover(item: $node.fullScreen) { child in
            PresentationNodeView(node: child) {
                node.dismissFullScreen()
            }
                .environment(router)
        }
    }
}

private struct PresentedRootView: View {
    @Bindable var node: PresentationNode
    let dismiss: () -> Void

    var body: some View {
        switch node.route {
        case .sheet(let route):
            switch route {
            case .composer(let replyTo):
                ComposerSheetView(node: node, replyTo: replyTo, dismiss: dismiss)
            case .filters:
                FiltersView(node: node, dismiss: dismiss)
            }
        case .fullScreen(let route):
            switch route {
            case .onboarding:
                OnboardingView(node: node, dismiss: dismiss)
            case .messagePreview(let id):
                MessagePreviewView(node: node, messageID: id, dismiss: dismiss)
            }
        }
    }
}

private struct ComposerSheetView: View {
    @Environment(Router.self) private var router
    @Bindable var node: PresentationNode
    let replyTo: Int?
    let dismiss: () -> Void

    var body: some View {
        ComposerForm(replyTo: replyTo) {
            dismiss()
        }
        .navigationTitle("Compose Sheet")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Push Inside") {
                        node.push(.composer(replyTo: replyTo))
                    }

                    Button("Present Sheet") {
                        node.presentSheet(.filters)
                    }

                    Button("Present Cover") {
                        node.presentFullScreen(.onboarding)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

private struct FiltersView: View {
    @Environment(Router.self) private var router
    @Bindable var node: PresentationNode
    let dismiss: () -> Void

    var body: some View {
        List {
            RouterStateSection()
            NodeStateSection(node: node)

            Section("Filters") {
                Toggle("Unread", isOn: .constant(true))
                Toggle("Flagged", isOn: .constant(false))
            }

            Section("Navigate While Presented") {
                if let message = DemoData.messages.last {
                    Button {
                        node.push(.message(message.id))
                    } label: {
                        Label("Push Inside This Sheet", systemImage: "arrow.right.circle")
                    }
                }

                Button {
                    node.presentSheet(.composer(replyTo: nil))
                } label: {
                    Label("Present Sheet From Sheet", systemImage: "rectangle.on.rectangle")
                }

                if let message = DemoData.messages.first {
                    Button {
                        node.presentFullScreen(.messagePreview(message.id))
                    } label: {
                        Label("Present Cover From Sheet", systemImage: "rectangle.fill.on.rectangle.fill")
                    }
                }

                if let message = DemoData.messages.last {
                    Button {
                        router.push(.message(message.id), on: .inbox)
                    } label: {
                        Label("Push Behind Sheet", systemImage: "arrow.down.forward.circle")
                    }
                }

                if let message = DemoData.messages.first {
                    Button {
                        router.openDeepLink(.message(message))
                    } label: {
                        Label("Deep Link While Sheet Is Open", systemImage: "link")
                    }
                }
            }
        }
        .navigationTitle("Filters")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

private struct OnboardingView: View {
    @Environment(Router.self) private var router
    @Bindable var node: PresentationNode
    let dismiss: () -> Void

    var body: some View {
        List {
            RouterStateSection()
            NodeStateSection(node: node)

            Section("Full Screen") {
                Text("This cover is a presentation node with its own path and child presentations.")
            }

            Section("Navigate While Presented") {
                if let setting = DemoData.settings.first {
                    Button {
                        node.push(.settingsDetail(setting.id))
                    } label: {
                        Label("Push Inside This Cover", systemImage: "arrow.right.circle")
                    }
                }

                Button {
                    node.presentSheet(.filters)
                } label: {
                    Label("Present Sheet From Cover", systemImage: "rectangle.on.rectangle")
                }

                Button {
                    node.presentFullScreen(.messagePreview(DemoData.messages[0].id))
                } label: {
                    Label("Present Cover From Cover", systemImage: "rectangle.fill.on.rectangle.fill")
                }

                if let setting = DemoData.settings.first {
                    Button {
                        router.openDeepLink(.settingsDetail(setting))
                    } label: {
                        Label("Deep Link to Settings", systemImage: "link")
                    }
                }
            }
        }
        .navigationTitle("Onboarding")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

private struct MessagePreviewView: View {
    @Environment(Router.self) private var router
    @Bindable var node: PresentationNode
    let messageID: Int
    let dismiss: () -> Void

    private var message: DemoMessage? {
        DemoData.message(id: messageID)
    }

    var body: some View {
        List {
            RouterStateSection()
            NodeStateSection(node: node)

            if let message {
                Section(message.title) {
                    Text(message.preview)
                }

                Section("Actions") {
                    Button {
                        node.push(.message(message.id))
                    } label: {
                        Label("Push Inside This Cover", systemImage: "arrow.right.circle")
                    }

                    Button {
                        node.presentSheet(.filters)
                    } label: {
                        Label("Present Sheet From Cover", systemImage: "rectangle.on.rectangle")
                    }

                    Button {
                        router.openDeepLink(.message(message))
                    } label: {
                        Label("Open Full Detail", systemImage: "link")
                    }
                }
            }
        }
        .navigationTitle("Preview")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Close") {
                    dismiss()
                }
            }
        }
    }
}

private struct ComposerForm: View {
    let replyTo: Int?
    let sendAction: (() -> Void)?

    private var message: DemoMessage? {
        replyTo.flatMap(DemoData.message(id:))
    }

    init(replyTo: Int?, sendAction: (() -> Void)? = nil) {
        self.replyTo = replyTo
        self.sendAction = sendAction
    }

    var body: some View {
        Form {
            RouterStateSection()

            Section("Compose") {
                TextField("Subject", text: .constant(message.map { "Re: \($0.title)" } ?? ""))
                TextEditor(text: .constant(""))
                    .frame(minHeight: 140)
            }

            if let sendAction {
                Section("Actions") {
                    Button {
                        sendAction()
                    } label: {
                        Label("Send", systemImage: "paperplane")
                    }
                }
            }
        }
    }
}

private struct MessageRow: View {
    let message: DemoMessage

    var body: some View {
        NavigationLink(value: Route.message(message.id)) {
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

private struct RouterStateSection: View {
    @Environment(Router.self) private var router

    var body: some View {
        Section("Router State") {
            LabeledContent("Tab", value: router.selectedTab.title)
            LabeledContent("Inbox Path", value: routeTitles(router.inboxPath))
            LabeledContent("Settings Path", value: routeTitles(router.settingsPath))
            LabeledContent("Root Sheet", value: router.sheet?.route.title ?? "None")
            LabeledContent("Root Cover", value: router.fullScreen?.route.title ?? "None")
            LabeledContent("Deferred Link", value: router.deferredDeepLink == nil ? "None" : "Waiting")
        }
        .font(.caption)
    }

    private func routeTitles(_ path: [Route]) -> String {
        guard !path.isEmpty else { return "Root" }
        return path.map(\.title).joined(separator: " / ")
    }
}

private struct NodeStateSection: View {
    @Bindable var node: PresentationNode

    var body: some View {
        Section("Current Presentation Node") {
            LabeledContent("Root", value: node.route.title)
            LabeledContent("Path", value: routeTitles(node.path))
            LabeledContent("Sheet", value: node.sheet?.route.title ?? "None")
            LabeledContent("Cover", value: node.fullScreen?.route.title ?? "None")
        }
        .font(.caption)
    }

    private func routeTitles(_ path: [Route]) -> String {
        guard !path.isEmpty else { return "Root" }
        return path.map(\.title).joined(separator: " / ")
    }
}

#Preview {
    ContentView()
}
