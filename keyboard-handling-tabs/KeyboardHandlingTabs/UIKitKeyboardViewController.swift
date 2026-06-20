import UIKit

@MainActor
final class UIKitKeyboardViewController: UIViewController {
    private var state = KeyboardDemoState(platform: .uiKit)

    private let scrollView = UIScrollView()
    private let messagesStackView = UIStackView()
    private let composerContainer = UIView()
    private let actionButtonsStackView = UIStackView()
    private let draftTextField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let attachmentPanel = AttachmentPanelView()
    private var composerBottomToKeyboardConstraint: NSLayoutConstraint?
    private var composerBottomToBottomConstraint: NSLayoutConstraint?
    private var composerBottomToAttachmentPanelConstraint: NSLayoutConstraint?
    private var composerBottomAboveKeyboardDuringPanelCoverConstraint: NSLayoutConstraint?
    private var composerBottomAboveAttachmentDuringPanelCoverConstraint: NSLayoutConstraint?
    private var composerBottomPullDownDuringPanelCoverConstraint: NSLayoutConstraint?
    private var attachmentPanelBottomConstraint: NSLayoutConstraint?
    private var attachmentPanelHeightConstraint: NSLayoutConstraint?
    private var inputSurfaceState: InputSurfaceState = .idle {
        didSet {
            print("inputSurfaceState: \(oldValue) -> \(inputSurfaceState)")
        }
    }
    private var lastVisibleKeyboardHeight: CGFloat = 291

    private enum AttachmentPanelLayout {
        static let minimumHeight: CGFloat = 180
    }

    private enum InputSurfaceState {
        case idle
        case keyboard
        case attachment
        case attachmentRevealingBehindKeyboard
        case keyboardPresentingOverAttachment
        case keyboardDismissing
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "UIKit"
        view.backgroundColor = .systemGroupedBackground
        configureComposer()
        configureAttachmentPanel()
        configureScrollView()
        observeKeyboardFrameChanges()
        applyState(scrollToBottom: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollMessagesToBottom(animated: false)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func configureComposer() {
        composerContainer.translatesAutoresizingMaskIntoConstraints = false
        composerContainer.backgroundColor = .secondarySystemBackground
        view.addSubview(composerContainer)

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .separator
        composerContainer.addSubview(divider)

        let composerStackView = UIStackView()
        composerStackView.translatesAutoresizingMaskIntoConstraints = false
        composerStackView.axis = .vertical
        composerStackView.spacing = 10
        composerStackView.alignment = .fill
        composerStackView.distribution = .fill
        composerContainer.addSubview(composerStackView)

        actionButtonsStackView.axis = .horizontal
        actionButtonsStackView.spacing = 8
        actionButtonsStackView.distribution = .fillEqually
        actionButtonsStackView.alignment = .fill

        for action in KeyboardAction.allCases {
            let button = UIButton(type: .system)
            button.tag = action.rawValue
            button.configuration = .tinted()
            button.configuration?.title = action.title
            button.configuration?.image = UIImage(systemName: action.symbolName)
            button.configuration?.imagePadding = 6
            button.addTarget(self, action: #selector(handleActionButtonTap(_:)), for: .touchUpInside)
            actionButtonsStackView.addArrangedSubview(button)
        }

        let inputRowStackView = UIStackView()
        inputRowStackView.axis = .horizontal
        inputRowStackView.spacing = 8
        inputRowStackView.alignment = .center

        draftTextField.borderStyle = .roundedRect
        draftTextField.placeholder = "Type a message"
        draftTextField.returnKeyType = .default
        draftTextField.delegate = self
        draftTextField.textContentType = .none
        draftTextField.addTarget(self, action: #selector(draftDidChange(_:)), for: .editingChanged)

        sendButton.configuration = .filled()
        sendButton.configuration?.title = "Send"
        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        sendButton.setContentHuggingPriority(.required, for: .horizontal)

        inputRowStackView.addArrangedSubview(draftTextField)
        inputRowStackView.addArrangedSubview(sendButton)

        composerStackView.addArrangedSubview(actionButtonsStackView)
        composerStackView.addArrangedSubview(inputRowStackView)

        // 直接跟随系统键盘布局引导：键盘出现时贴住键盘顶部，隐藏时回到底部安全区域。
        view.keyboardLayoutGuide.followsUndockedKeyboard = true
        let composerKeyboardConstraint = composerContainer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        let composerBottomConstraint = composerContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        composerBottomToKeyboardConstraint = composerKeyboardConstraint
        composerBottomToBottomConstraint = composerBottomConstraint
        composerKeyboardConstraint.isActive = false

        NSLayoutConstraint.activate([
            composerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composerBottomConstraint,

            divider.leadingAnchor.constraint(equalTo: composerContainer.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: composerContainer.trailingAnchor),
            divider.topAnchor.constraint(equalTo: composerContainer.topAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1 / max(view.traitCollection.displayScale, 1)),

            composerStackView.leadingAnchor.constraint(equalTo: composerContainer.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            composerStackView.trailingAnchor.constraint(equalTo: composerContainer.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            composerStackView.topAnchor.constraint(equalTo: composerContainer.topAnchor, constant: 10),
            composerStackView.bottomAnchor.constraint(equalTo: composerContainer.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            draftTextField.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
        ])
    }

    private func configureAttachmentPanel() {
        attachmentPanel.translatesAutoresizingMaskIntoConstraints = false
        attachmentPanel.selectSource = { [weak self] source in
            self?.selectAttachmentSource(source)
        }
        view.addSubview(attachmentPanel)

        let panelBottomConstraint = attachmentPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        let panelHeightConstraint = attachmentPanel.heightAnchor.constraint(equalToConstant: lastVisibleKeyboardHeight)
        let composerPanelConstraint = composerContainer.bottomAnchor.constraint(equalTo: attachmentPanel.topAnchor)
        let composerAboveKeyboardConstraint = composerContainer.bottomAnchor.constraint(lessThanOrEqualTo: view.keyboardLayoutGuide.topAnchor)
        let composerAbovePanelConstraint = composerContainer.bottomAnchor.constraint(lessThanOrEqualTo: attachmentPanel.topAnchor)
        let composerPullDownConstraint = composerContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        composerPullDownConstraint.priority = .defaultLow

        attachmentPanelBottomConstraint = panelBottomConstraint
        attachmentPanelHeightConstraint = panelHeightConstraint
        composerBottomToAttachmentPanelConstraint = composerPanelConstraint
        composerBottomAboveKeyboardDuringPanelCoverConstraint = composerAboveKeyboardConstraint
        composerBottomAboveAttachmentDuringPanelCoverConstraint = composerAbovePanelConstraint
        composerBottomPullDownDuringPanelCoverConstraint = composerPullDownConstraint
        composerPanelConstraint.isActive = false
        composerAboveKeyboardConstraint.isActive = false
        composerAbovePanelConstraint.isActive = false
        composerPullDownConstraint.isActive = false

        NSLayoutConstraint.activate([
            attachmentPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            attachmentPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panelBottomConstraint,
            panelHeightConstraint
        ])
    }

    private func observeKeyboardFrameChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardDidShow(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
    }

    private func configureScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        messagesStackView.translatesAutoresizingMaskIntoConstraints = false
        messagesStackView.axis = .vertical
        messagesStackView.spacing = 12
        messagesStackView.alignment = .fill
        scrollView.addSubview(messagesStackView)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: composerContainer.topAnchor),

            messagesStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            messagesStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            messagesStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            messagesStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -12),
            messagesStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])
    }

    @objc
    private func draftDidChange(_ sender: UITextField) {
        state.updateDraft(sender.text ?? "")
    }

    @objc
    private func handleActionButtonTap(_ sender: UIButton) {
        guard let action = KeyboardAction(rawValue: sender.tag) else {
            return
        }
        handle(action)
    }

    @objc
    private func sendButtonTapped() {
        let appended = state.sendDraft() != nil
        applyState(scrollToBottom: appended)
    }

    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard
            let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let window = view.window
        else {
            return
        }

        let convertedEndFrame = view.convert(endFrame, from: window.screen.coordinateSpace)
        let keyboardHeight = max(0, view.bounds.maxY - convertedEndFrame.minY - view.safeAreaInsets.bottom)
        if keyboardHeight > 0 {
            lastVisibleKeyboardHeight = keyboardHeight
            if !attachmentPanelIsVisible {
                attachmentPanelHeightConstraint?.constant = max(
                    AttachmentPanelLayout.minimumHeight,
                    keyboardHeight
                )
            }
        }
    }

    @objc
    private func keyboardDidHide(_ notification: Notification) {
        if inputSurfaceState == .attachmentRevealingBehindKeyboard && attachmentPanelIsVisible {
            inputSurfaceState = .attachment
            pinComposerToAttachmentPanel()
            view.layoutIfNeeded()
            return
        }

        guard inputSurfaceState == .keyboardDismissing && !attachmentPanelIsVisible else {
            return
        }
        inputSurfaceState = .idle
        pinComposerToBottom()
        view.layoutIfNeeded()
    }

    @objc
    private func keyboardDidShow(_ notification: Notification) {
        guard inputSurfaceState == .keyboardPresentingOverAttachment else {
            return
        }
        inputSurfaceState = .keyboard
        hideAttachmentPanelWithoutMovingComposer()
    }

    private func handle(_ action: KeyboardAction) {
        switch action {
        case .attach:
            showAttachmentPanel()
        case .emoji, .clear:
            state.handleAction(action)
            applyState(scrollToBottom: false)
        case .dismissKeyboard:
            dismissActiveInputSurface()
        }
    }

    private func showAttachmentPanel() {
        if inputSurfaceState == .attachment {
            return
        }

        if inputSurfaceState == .keyboard || draftTextField.isFirstResponder {
            showAttachmentPanelAtKeyboardHeight()
            // keyboard -> attachment: 键盘下滑期间 composer 同时避开 keyboard 和 panel。
            inputSurfaceState = .attachmentRevealingBehindKeyboard
            pinComposerAboveKeyboardAndAttachmentPanel()
            view.layoutIfNeeded()
            draftTextField.resignFirstResponder()
        } else {
            // idle -> attachment: 没有系统键盘动画，panel 高度从 0 渐变到目标高度。
            inputSurfaceState = .attachment
            slideAttachmentPanelUpFromBottom()
        }
    }

    private func dismissActiveInputSurface() {
        // keyboard 正在覆盖 panel 时点击 Dismiss：先取消覆盖过渡，隐藏 panel，但 composer 继续跟键盘。
        if inputSurfaceState == .keyboardPresentingOverAttachment {
            inputSurfaceState = .keyboardDismissing
            hideAttachmentPanelWithoutMovingComposer()
            pinComposerToKeyboard()
            view.endEditing(true)
            return
        }

        if inputSurfaceState == .attachment {
            hideAttachmentPanel(animated: true)
        } else {
            inputSurfaceState = .keyboardDismissing
            view.endEditing(true)
        }
    }

    private func selectAttachmentSource(_ source: AttachmentSource) {
        state.selectAttachmentSource(source)
        // pending 期间 panel 只是“还可见”，active surface 已经是 keyboard，不能把 composer 切到底部。
        if inputSurfaceState == .keyboardPresentingOverAttachment || draftTextField.isFirstResponder {
            inputSurfaceState = .keyboard
            hideAttachmentPanelWithoutMovingComposer()
            pinComposerToKeyboard()
        } else {
            hideAttachmentPanel(animated: false)
        }
        applyState(scrollToBottom: false)
    }

    private func hideAttachmentPanel(animated: Bool) {
        guard attachmentPanelIsVisible else {
            return
        }

        if animated {
            slideAttachmentPanelDownToIdle()
        } else {
            inputSurfaceState = .idle
            attachmentPanelBottomConstraint?.constant = targetAttachmentPanelHeight
            pinComposerToBottom()
            attachmentPanel.alpha = 0
            attachmentPanel.isHidden = true
            attachmentPanelBottomConstraint?.constant = 0
        }
    }

    private var attachmentPanelIsVisible: Bool {
        !attachmentPanel.isHidden
    }

    private var targetAttachmentPanelHeight: CGFloat {
        max(AttachmentPanelLayout.minimumHeight, lastVisibleKeyboardHeight)
    }

    // View 指令：只负责让 panel 以目标高度出现在底部，不决定 composer 贴谁。
    private func showAttachmentPanelAtKeyboardHeight() {
        attachmentPanelHeightConstraint?.constant = targetAttachmentPanelHeight
        attachmentPanelBottomConstraint?.constant = 0
        attachmentPanel.isHidden = false
        attachmentPanel.alpha = 1
    }

    // View 指令：idle -> attachment 时，整块 panel 从屏幕底部向上移动，内部内容不被拉伸。
    private func slideAttachmentPanelUpFromBottom() {
        attachmentPanelHeightConstraint?.constant = targetAttachmentPanelHeight
        attachmentPanelBottomConstraint?.constant = targetAttachmentPanelHeight
        attachmentPanel.isHidden = false
        attachmentPanel.alpha = 1
        pinComposerToAttachmentPanel()
        view.layoutIfNeeded()

        attachmentPanelBottomConstraint?.constant = 0
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.view.layoutIfNeeded()
            }
        )
    }

    // View 指令：attachment -> idle 时，整块 panel 下移到屏幕底部外，composer 跟着 panel.top 下移。
    private func slideAttachmentPanelDownToIdle() {
        inputSurfaceState = .idle
        attachmentPanelHeightConstraint?.constant = targetAttachmentPanelHeight
        attachmentPanelBottomConstraint?.constant = 0
        pinComposerToAttachmentPanel()
        view.layoutIfNeeded()

        attachmentPanelBottomConstraint?.constant = targetAttachmentPanelHeight
        UIView.animate(
            withDuration: 0.25,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: {
                self.view.layoutIfNeeded()
            },
            completion: { _ in
                self.attachmentPanel.alpha = 0
                self.attachmentPanel.isHidden = true
                self.attachmentPanelBottomConstraint?.constant = 0
                self.pinComposerToBottom()
                self.view.layoutIfNeeded()
            }
        )
    }

    // View 指令：只隐藏 panel，不移动 composer；用于“键盘覆盖 panel”完成后的收尾。
    private func hideAttachmentPanelWithoutMovingComposer() {
        guard attachmentPanelIsVisible else {
            return
        }
        attachmentPanel.alpha = 0
        attachmentPanel.isHidden = true
    }

    // Layout 指令：keyboard active 时 composer 贴系统键盘顶部。
    private func pinComposerToKeyboard() {
        composerBottomToBottomConstraint?.isActive = false
        composerBottomToAttachmentPanelConstraint?.isActive = false
        composerBottomAboveKeyboardDuringPanelCoverConstraint?.isActive = false
        composerBottomAboveAttachmentDuringPanelCoverConstraint?.isActive = false
        composerBottomPullDownDuringPanelCoverConstraint?.isActive = false
        composerBottomToKeyboardConstraint?.isActive = true
    }

    // Layout 指令：attachment active 时 composer.bottom == attachmentPanel.top。
    private func pinComposerToAttachmentPanel() {
        composerBottomToKeyboardConstraint?.isActive = false
        composerBottomToBottomConstraint?.isActive = false
        composerBottomAboveKeyboardDuringPanelCoverConstraint?.isActive = false
        composerBottomAboveAttachmentDuringPanelCoverConstraint?.isActive = false
        composerBottomPullDownDuringPanelCoverConstraint?.isActive = false
        composerBottomToAttachmentPanelConstraint?.isActive = true
    }

    // Layout 指令：attachment/keyboard 过渡时，composer 在 keyboard/panel 中更高的 surface 上方。
    // 原理：前两个 required 约束提供上界：composer.bottom 不能低于 keyboard.top 和 panel.top。
    // 第三个 pull-down 是低优先级等式，表示“尽量贴近 view.bottom”。Auto Layout 会先满足 required，
    // 再在可行范围内尽量满足低优先级等式，所以 composer.bottom 会落在两个上界中更靠上的那个位置。
    private func pinComposerAboveKeyboardAndAttachmentPanel() {
        composerBottomToKeyboardConstraint?.isActive = false
        composerBottomToBottomConstraint?.isActive = false
        composerBottomToAttachmentPanelConstraint?.isActive = false
        composerBottomAboveKeyboardDuringPanelCoverConstraint?.isActive = true
        composerBottomAboveAttachmentDuringPanelCoverConstraint?.isActive = true
        composerBottomPullDownDuringPanelCoverConstraint?.isActive = true
    }

    // Layout 指令：没有 active input surface 时 composer 回到底部 safe area。
    private func pinComposerToBottom() {
        composerBottomToKeyboardConstraint?.isActive = false
        composerBottomToAttachmentPanelConstraint?.isActive = false
        composerBottomAboveKeyboardDuringPanelCoverConstraint?.isActive = false
        composerBottomAboveAttachmentDuringPanelCoverConstraint?.isActive = false
        composerBottomPullDownDuringPanelCoverConstraint?.isActive = false
        composerBottomToBottomConstraint?.isActive = true
    }

    private func animateLayoutChanges(with notification: Notification) {
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRawValue = notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt ?? 0
        let options = UIView.AnimationOptions(rawValue: curveRawValue << 16)
            .union(.beginFromCurrentState)
        UIView.animate(
            withDuration: duration,
            delay: 0,
            options: options,
            animations: {
                self.view.layoutIfNeeded()
            }
        )
    }

    private func applyState(scrollToBottom: Bool) {
        if draftTextField.text != state.draft {
            draftTextField.text = state.draft
        }
        reloadMessageRows()
        if scrollToBottom {
            scrollMessagesToBottom(animated: true)
        }
    }

    private func reloadMessageRows() {
        messagesStackView.arrangedSubviews.forEach { row in
            messagesStackView.removeArrangedSubview(row)
            row.removeFromSuperview()
        }

        for message in state.messages {
            messagesStackView.addArrangedSubview(makeRow(for: message))
        }
    }

    private func makeRow(for message: KeyboardMessage) -> UIView {
        let rowView = UIView()
        rowView.translatesAutoresizingMaskIntoConstraints = false

        let bubbleView = UIView()
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.layer.cornerRadius = 14
        bubbleView.layer.cornerCurve = .continuous
        bubbleView.backgroundColor = message.isOutgoing ? .systemBlue : .secondarySystemBackground
        bubbleView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.text = message.text
        label.textColor = message.isOutgoing ? .white : .label

        bubbleView.addSubview(label)
        rowView.addSubview(bubbleView)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.trailingAnchor),
            label.topAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: bubbleView.layoutMarginsGuide.bottomAnchor),
            bubbleView.topAnchor.constraint(equalTo: rowView.topAnchor),
            bubbleView.bottomAnchor.constraint(equalTo: rowView.bottomAnchor)
        ])

        if message.isOutgoing {
            NSLayoutConstraint.activate([
                bubbleView.trailingAnchor.constraint(equalTo: rowView.trailingAnchor),
                bubbleView.leadingAnchor.constraint(greaterThanOrEqualTo: rowView.leadingAnchor, constant: 48)
            ])
        } else {
            NSLayoutConstraint.activate([
                bubbleView.leadingAnchor.constraint(equalTo: rowView.leadingAnchor),
                bubbleView.trailingAnchor.constraint(lessThanOrEqualTo: rowView.trailingAnchor, constant: -48)
            ])
        }

        return rowView
    }

    private func scrollMessagesToBottom(animated: Bool) {
        view.layoutIfNeeded()
        // 使用 adjustedContentInset 计算目标位置，避免最后一条消息被安全区或 composer 遮住。
        let targetOffsetY = max(
            -scrollView.adjustedContentInset.top,
            scrollView.contentSize.height - scrollView.bounds.height + scrollView.adjustedContentInset.bottom
        )
        scrollView.setContentOffset(CGPoint(x: 0, y: targetOffsetY), animated: animated)
    }
}

extension UIKitKeyboardViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if attachmentPanelIsVisible {
            // attachment -> keyboard: panel 先保持可见，composer 贴住 keyboard/panel 中更高的 surface。
            inputSurfaceState = .keyboardPresentingOverAttachment
            pinComposerAboveKeyboardAndAttachmentPanel()
            return true
        } else {
            inputSurfaceState = .keyboard
        }
        pinComposerToKeyboard()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonTapped()
        return false
    }
}
