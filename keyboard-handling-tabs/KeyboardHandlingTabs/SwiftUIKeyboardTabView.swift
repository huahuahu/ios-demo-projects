import SwiftUI
import UIKit

struct SwiftUIKeyboardTabView: View {
    @State private var state = KeyboardDemoState(platform: .swiftUI)
    @State private var isSourceSheetPresented = false
    @FocusState private var isInputFocused: Bool
    private let bottomAnchorID = "swiftui-bottom-anchor"

    var body: some View {
            NavigationStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(state.messages) { message in
                                MessageBubbleView(message: message)
                            }
                            Color.clear
                                .frame(height: 1)
                                .id(bottomAnchorID)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .background(Color(.systemGroupedBackground))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .safeAreaInset(edge: .bottom, spacing: 0) {
                        composerBar(
                            sendAction: {
                                if state.sendDraft() != nil {
                                    scrollToBottom(proxy: proxy)
                                }
                            }
                        )
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                    .onChange(of: state.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .navigationTitle("SwiftUI")
                    .sheet(isPresented: $isSourceSheetPresented) {
                        AttachmentSourceSheetView { source in
                            state.selectAttachmentSource(source)
                            isSourceSheetPresented = false
                        }
                        .presentationDetents([.medium])
                        .presentationDragIndicator(.visible)
                    }
                }
            }
    }

    @ViewBuilder
    private func composerBar(sendAction: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(KeyboardAction.allCases, id: \.self) { action in
                    Button {
                        handle(action)
                    } label: {
                        Label(action.title, systemImage: action.symbolName)
                    }
                    .buttonStyle(.bordered)
                }
            }

            HStack(spacing: 8) {
                TextField(
                    "Type a message",
                    text: Binding(
                        get: { state.draft },
                        set: { state.updateDraft($0) }
                    ),
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(1 ... 3)
                .focused($isInputFocused)
                .submitLabel(.return)

                Button("Send") {
                    sendAction()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(12)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func handle(_ action: KeyboardAction) {
        switch action {
        case .attach:
            isInputFocused = false
            isSourceSheetPresented = true
        case .emoji, .clear:
            state.handleAction(action)
        case .dismissKeyboard:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = false
            }

//            isInputFocused = false
//            isSourceSheetPresented = false
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool = true) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        } else {
            proxy.scrollTo(bottomAnchorID, anchor: .bottom)
        }
    }


}

private struct AttachmentSourceSheetView: View {
    let selectSource: (AttachmentSource) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose attachment source")
                .font(.title2.bold())

            Text("SwiftUI keeps this as a presentation instead of trying to replace the system keyboard input view.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                ForEach(AttachmentSource.allCases, id: \.self) { source in
                    Button {
                        selectSource(source)
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: source.symbolName)
                                .font(.title2)
                            Text(source.rawValue)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                    }
                    .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .presentationBackground(.regularMaterial)
    }
}

private struct MessageBubbleView: View {
    let message: KeyboardMessage

    var body: some View {
        HStack {
            if message.isOutgoing {
                Spacer(minLength: 48)
            }

            Text(message.text)
                .foregroundStyle(message.isOutgoing ? Color.white : Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(message.isOutgoing ? Color.accentColor : Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if !message.isOutgoing {
                Spacer(minLength: 48)
            }
        }
    }
}
