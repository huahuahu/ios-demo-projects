# UIKit Keyboard Attachment Input View Design

## Context

`keyboard-handling-tabs` compares keyboard-safe composer behavior in SwiftUI and UIKit. The UIKit tab currently uses `keyboardLayoutGuide` for the system keyboard, but shows the attachment panel as a separate app-owned view with its own bottom constraint and a fixed height.

The target interaction should feel like WeChat:

1. Tapping the text field shows the system keyboard and allows typing.
2. Tapping Attach makes the text field lose focus and shows `attachmentPanel` in the keyboard area.
3. Tapping the text field again brings the system keyboard back.
4. The transition must not visibly flash, collapse the composer to the bottom, or briefly show an empty gap.

## Recommended approach

Use a hidden first-responder host with a custom `inputView` for the attachment panel.

The composer remains pinned to `view.keyboardLayoutGuide.topAnchor` in every input mode. The controller no longer switches the composer between a keyboard constraint and an attachment-panel constraint. Instead, UIKit owns the bottom input surface:

- The text field is first responder when the system keyboard is active.
- A hidden responder is first responder when the attachment panel is active.
- The hidden responder returns an attachment `UIInputView` from its `inputView`.
- Switching between text field and hidden responder lets UIKit replace the system keyboard with the custom input view in the same input area.

This avoids the current flicker-prone sequence where the text field resigns first responder, the keyboard starts dismissing, and a separate normal view then animates into place.

## Components

### `AttachmentInputHostView`

A small hidden `UIView` subclass owned by `UIKitKeyboardViewController`.

- Overrides `canBecomeFirstResponder` to return `true`.
- Exposes the attachment panel through `inputView`.
- Does not render visible content in the controller view hierarchy.

### `AttachmentInputView`

A custom `UIInputView` containing the existing attachment source UI.

- Uses Auto Layout for title, source buttons, and padding.
- Computes its height from its fitting size instead of using the current fixed `150pt` panel height.
- Keeps the existing source buttons and callbacks so selecting Photo Library, Camera, or Files still updates the draft with the same tokens.

### `UIKitKeyboardViewController`

The view controller keeps message state and composer layout responsibilities.

- Keeps `composerContainer.bottomAnchor == view.keyboardLayoutGuide.topAnchor` active at all times.
- Removes the separate app-owned attachment panel bottom constraint path.
- Handles Attach by making `AttachmentInputHostView` first responder.
- Handles text-field focus by letting the text field become first responder, replacing the custom input view with the system keyboard.
- Handles Dismiss by resigning whichever input surface is active.

## Interaction flow

### Text field tap

The text field becomes first responder. UIKit shows the system keyboard. Since the composer is pinned to `keyboardLayoutGuide`, it follows the keyboard top.

### Attach tap

The hidden attachment host becomes first responder. The text field loses focus as part of the responder switch. UIKit replaces the system keyboard with the attachment input view, and the composer continues to follow `keyboardLayoutGuide`.

### Text field tap while attachment is visible

The text field becomes first responder. UIKit replaces the attachment input view with the system keyboard. The composer does not switch constraints, so there is no intermediate bottom-safe-area layout.

### Dismiss tap

If the attachment host is first responder, it resigns. Otherwise, the controller ends text-field editing. This preserves the current "Dismiss closes the active input surface" behavior.

## Preserved behavior

- Message sending, trimming, and draft updates remain model-owned.
- Emoji and Clear continue mutating the draft without changing the active input surface.
- Attachment source selection continues inserting the same draft tokens.
- The SwiftUI tab is out of scope for this change.

## Validation

Implementation should be validated with the existing Xcode project workflow:

1. Build and run tests for `KeyboardHandlingTabs`.
2. In the UIKit tab, manually exercise `text field -> Attach -> text field`.
3. Confirm the composer stays attached to the active input surface without flashing, dropping to the safe-area bottom, or showing a temporary blank keyboard area.

