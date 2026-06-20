import Testing
@testable import KeyboardHandlingTabs

struct KeyboardDemoModelTests {
    @Test
    func sendDraftTrimsWhitespaceAndAppendsOutgoingMessage() {
        var state = KeyboardDemoState(platform: .swiftUI)
        let originalCount = state.messages.count

        state.updateDraft("   Hello keyboard   ")
        let sent = state.sendDraft()

        #expect(sent?.text == "Hello keyboard")
        #expect(sent?.isOutgoing == true)
        #expect(state.messages.count == originalCount + 1)
        #expect(state.messages.last?.text == "Hello keyboard")
        #expect(state.draft.isEmpty)
    }

    @Test
    func sendDraftIgnoresWhitespaceOnlyInput() {
        var state = KeyboardDemoState(platform: .uiKit)
        let originalCount = state.messages.count

        state.updateDraft(" \n\t ")
        let sent = state.sendDraft()

        #expect(sent == nil)
        #expect(state.messages.count == originalCount)
        #expect(state.draft == " \n\t ")
    }

    @Test
    func actionButtonsMutateDraftPredictably() {
        var state = KeyboardDemoState(platform: .swiftUI)

        state.selectAttachmentSource(.photoLibrary)
        state.handleAction(.emoji)
        #expect(state.draft == "[Photo] [Emoji]")

        state.handleAction(.clear)
        #expect(state.draft.isEmpty)
    }

    @Test
    func dismissKeyboardActionDoesNotMutateDraft() {
        var state = KeyboardDemoState(platform: .uiKit)

        state.updateDraft("Keep me")
        state.handleAction(.dismissKeyboard)

        #expect(state.draft == "Keep me")
    }

}
