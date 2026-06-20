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
    private let attachmentPanel = UIView()
    private var composerBottomToKeyboardConstraint: NSLayoutConstraint?
    private var composerBottomToBottomConstraint: NSLayoutConstraint?
    private var composerBottomToAttachmentPanelConstraint: NSLayoutConstraint?
    private var attachmentPanelBottomConstraint: NSLayoutConstraint?
    private var attachmentPanelHeightConstraint: NSLayoutConstraint?
    private var isAttachmentPanelVisible = false
    private var isKeyboardDismissalPending = false
    private var lastVisibleKeyboardHeight: CGFloat = 291

    private enum AttachmentPanelLayout {
        static let minimumHeight: CGFloat = 180
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
        composerBottomConstraint.isActive = false

        NSLayoutConstraint.activate([
            composerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            composerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            composerKeyboardConstraint,

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
        attachmentPanel.accessibilityIdentifier = "UIKitAttachmentPanel"
        attachmentPanel.backgroundColor = .systemBackground
        attachmentPanel.isHidden = true
        attachmentPanel.alpha = 0
        view.addSubview(attachmentPanel)

        let divider = UIView()
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.backgroundColor = .separator
        attachmentPanel.addSubview(divider)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.accessibilityIdentifier = "UIKitAttachmentPanelTitle"
        titleLabel.text = "Choose attachment source"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.numberOfLines = 0
        attachmentPanel.addSubview(titleLabel)

        let optionsStackView = UIStackView()
        optionsStackView.translatesAutoresizingMaskIntoConstraints = false
        optionsStackView.accessibilityIdentifier = "UIKitAttachmentPanelOptions"
        optionsStackView.axis = .horizontal
        optionsStackView.spacing = 12
        optionsStackView.distribution = .fillEqually
        attachmentPanel.addSubview(optionsStackView)

        for source in AttachmentSource.allCases {
            let button = UIButton(type: .system)
            button.configuration = .tinted()
            button.configuration?.title = source.rawValue
            button.configuration?.image = UIImage(systemName: source.symbolName)
            button.configuration?.imagePadding = 8
            button.configuration?.imagePlacement = .top
            button.titleLabel?.numberOfLines = 0
            let selectedSource = source
            button.addAction(
                UIAction { [weak self] _ in
                    self?.selectAttachmentSource(selectedSource)
                },
                for: .touchUpInside
            )
            optionsStackView.addArrangedSubview(button)
        }

        let panelBottomConstraint = attachmentPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        let panelHeightConstraint = attachmentPanel.heightAnchor.constraint(equalToConstant: lastVisibleKeyboardHeight)
        let composerPanelConstraint = composerContainer.bottomAnchor.constraint(equalTo: attachmentPanel.topAnchor)

        attachmentPanelBottomConstraint = panelBottomConstraint
        attachmentPanelHeightConstraint = panelHeightConstraint
        composerBottomToAttachmentPanelConstraint = composerPanelConstraint
        composerPanelConstraint.isActive = false

        NSLayoutConstraint.activate([
            attachmentPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            attachmentPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            panelBottomConstraint,
            panelHeightConstraint,

            divider.leadingAnchor.constraint(equalTo: attachmentPanel.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: attachmentPanel.trailingAnchor),
            divider.topAnchor.constraint(equalTo: attachmentPanel.topAnchor),
            divider.heightAnchor.constraint(equalToConstant: 1 / max(view.traitCollection.displayScale, 1)),

            titleLabel.leadingAnchor.constraint(equalTo: attachmentPanel.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: attachmentPanel.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: attachmentPanel.topAnchor, constant: 16),

            optionsStackView.leadingAnchor.constraint(equalTo: attachmentPanel.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            optionsStackView.trailingAnchor.constraint(equalTo: attachmentPanel.safeAreaLayoutGuide.trailingAnchor, constant: -16),
            optionsStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 14),
            optionsStackView.heightAnchor.constraint(greaterThanOrEqualToConstant: 96),
            optionsStackView.bottomAnchor.constraint(lessThanOrEqualTo: attachmentPanel.safeAreaLayoutGuide.bottomAnchor, constant: -16)
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
            if !isAttachmentPanelVisible {
                attachmentPanelHeightConstraint?.constant = max(
                    AttachmentPanelLayout.minimumHeight,
                    keyboardHeight
                )
            }
        }
    }

    @objc
    private func keyboardDidHide(_ notification: Notification) {
        guard isKeyboardDismissalPending && !isAttachmentPanelVisible else {
            return
        }
        isKeyboardDismissalPending = false
        activateComposerBottomLayout()
        view.layoutIfNeeded()
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
        guard !isAttachmentPanelVisible else {
            return
        }

        isAttachmentPanelVisible = true
        attachmentPanelHeightConstraint?.constant = max(
            AttachmentPanelLayout.minimumHeight,
            lastVisibleKeyboardHeight
        )
        attachmentPanel.isHidden = false
        attachmentPanel.alpha = 1

        activateComposerAttachmentPanelLayout()
        view.layoutIfNeeded()

        if draftTextField.isFirstResponder {
            draftTextField.resignFirstResponder()
        }
    }

    private func dismissActiveInputSurface() {
        if isAttachmentPanelVisible {
            hideAttachmentPanel(animated: true)
        } else {
            isKeyboardDismissalPending = true
            view.endEditing(true)
        }
    }

    private func selectAttachmentSource(_ source: AttachmentSource) {
        state.selectAttachmentSource(source)
        hideAttachmentPanel(animated: false)
        applyState(scrollToBottom: false)
    }

    private func hideAttachmentPanel(animated: Bool) {
        guard isAttachmentPanelVisible else {
            return
        }
        isAttachmentPanelVisible = false
        isKeyboardDismissalPending = false
        activateComposerBottomLayout()

        let updates = {
            self.attachmentPanel.alpha = 0
            self.view.layoutIfNeeded()
        }
        let completion: (Bool) -> Void = { _ in
            self.attachmentPanel.isHidden = true
        }

        if animated {
            UIView.animate(
                withDuration: 0.25,
                delay: 0,
                options: [.curveEaseInOut, .beginFromCurrentState],
                animations: updates,
                completion: nil
            )
            completion(true)
        } else {
            updates()
            completion(true)
        }
    }

    private func activateComposerKeyboardLayout() {
        composerBottomToBottomConstraint?.isActive = false
        composerBottomToAttachmentPanelConstraint?.isActive = false
        composerBottomToKeyboardConstraint?.isActive = true
    }

    private func activateComposerAttachmentPanelLayout() {
        composerBottomToKeyboardConstraint?.isActive = false
        composerBottomToBottomConstraint?.isActive = false
        composerBottomToAttachmentPanelConstraint?.isActive = true
    }

    private func activateComposerBottomLayout() {
        composerBottomToKeyboardConstraint?.isActive = false
        composerBottomToAttachmentPanelConstraint?.isActive = false
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
        isKeyboardDismissalPending = false
        hideAttachmentPanel(animated: false)
        activateComposerKeyboardLayout()
        return true
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendButtonTapped()
        return false
    }
}
