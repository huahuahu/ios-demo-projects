# UIKit Attachment Panel Reveal Design

## Context

`keyboard-handling-tabs` compares SwiftUI and UIKit keyboard handling. The UIKit tab currently presents attachment sources through a hidden first responder with a custom `UIInputView`. That keeps the composer attached to UIKit's input surface, but tapping Attach while the text field is focused feels like an abrupt input-view replacement.

The desired interaction should feel closer to WeChat: tapping Attach makes the text field lose focus, the system keyboard slides down, and an app-owned attachment panel is gradually revealed from the bottom keyboard area.

## Goals

- Tapping Attach while the text field is focused must make the text field resign first responder.
- The system keyboard should animate downward instead of being replaced by another input view.
- The attachment panel should reveal smoothly as the keyboard moves down.
- The composer should stay visually attached to the active bottom input surface.
- Existing message, draft, Send, Emoji, Clear, Dismiss, and attachment token behavior should be preserved.
- The SwiftUI tab is out of scope.

## Recommended approach

Replace the UIKit tab's custom attachment `UIInputView` path with an app-owned `attachmentPanel` in the controller view hierarchy.

`UIKitKeyboardViewController` owns three related layout states:

1. **Keyboard mode:** `draftTextField` is first responder, the system keyboard is visible, and the composer follows `view.keyboardLayoutGuide.topAnchor`.
2. **Attachment mode:** `draftTextField` is not first responder, `attachmentPanel` occupies the bottom input area, and the composer sits above the panel.
3. **Dismissed mode:** no input surface is active, the attachment panel is hidden, and the composer returns to the bottom safe-area position.

The Attach action transitions from keyboard mode to attachment mode by showing the panel in a staged hidden position first, then resigning the text field so UIKit drives the keyboard dismissal animation. The panel and composer constraints animate with the keyboard notification's duration and curve so the keyboard descends while the panel is revealed.

## Components

### `attachmentPanel`

A normal `UIView` owned by `UIKitKeyboardViewController`.

- Renders the existing attachment source title and buttons.
- Reports selected `AttachmentSource` values through the same model path used today.
- Starts hidden or translated below the visible bottom area.
- Uses Auto Layout and a measured or fixed demo-appropriate height rather than `UIInputView` sizing.

### `UIKitKeyboardViewController`

The controller coordinates responder state and bottom layout.

- Removes `AttachmentInputHostView` and `AttachmentInputView` from the UIKit tab path.
- Tracks whether attachment mode is active.
- Handles Attach by setting attachment mode active and then calling `draftTextField.resignFirstResponder()`.
- Handles text-field editing by hiding attachment mode before `draftTextField` becomes first responder.
- Handles Dismiss by closing whichever input surface is active.
- Handles source selection by inserting the source token and dismissing the attachment panel, preserving the current source-selection semantics.

## Interaction flow

### Text field tap

If the attachment panel is visible, the controller hides it and lets `draftTextField` become first responder. UIKit raises the system keyboard and the composer follows `keyboardLayoutGuide`.

### Attach tap while keyboard is visible

The controller marks attachment mode active and prepares `attachmentPanel` below the keyboard area. It then calls `draftTextField.resignFirstResponder()`. As UIKit animates the keyboard down, the controller applies the same keyboard animation timing to move the panel into the bottom input area and keep the composer attached above it.

The text field must not remain first responder during this transition.

### Attach tap while keyboard is dismissed

The controller can show the attachment panel directly from the bottom safe-area position using the same panel reveal animation, without first showing the system keyboard.

### Text field tap while attachment is visible

The controller exits attachment mode, hides the panel, and lets the text field become first responder. The keyboard rises and the composer returns to following `keyboardLayoutGuide`.

### Dismiss tap

If attachment mode is active, the panel hides and the composer returns to the bottom safe area. Otherwise, the controller ends text-field editing.

## Testing

Add or update UIKit-focused tests to verify:

- The controller installs an app-owned attachment panel instead of relying on a custom attachment input host.
- Attach enters attachment mode and resigns `draftTextField` when it was focused.
- Beginning text-field editing exits attachment mode.
- Attachment source buttons still insert the expected `AttachmentSource.token`.
- Dismiss closes the active attachment panel or keyboard without changing unrelated draft behavior.

Manual validation should exercise `text field -> Attach -> text field` in the UIKit tab and confirm the keyboard moves down while the attachment panel gradually reveals, without an abrupt input-view swap.
