import UIKit

final class InterruptibleUIKitViewController: UIViewController {
    private let travelDistance: CGFloat = 260
    private var currentState: AnimationSnapState = .collapsed
    private var interactionStartState: AnimationSnapState = .collapsed
    private var animator: UIViewPropertyAnimator?

    private let titleLabel = UILabel()
    private let explanationLabel = UILabel()
    private let statusLabel = UILabel()
    private let trackView = UIView()
    private let cardView = UIView()
    private let cardTitleLabel = UILabel()
    private let cardBodyLabel = UILabel()
    private var cardCenterYConstraint: NSLayoutConstraint?

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureLabels()
        configureCard()
        configureLayout()
        configureGesture()
        updateStatus(progress: currentState.targetProgress, phase: "Ready")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cardCenterYConstraint?.constant = offset(for: currentState.targetProgress)
    }

    private func configureView() {
        view.backgroundColor = UIColor.systemGroupedBackground
    }

    private func configureLabels() {
        titleLabel.text = "UIKit: UIViewPropertyAnimator"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true

        explanationLabel.text = "Drag the card upward or downward. The pan gesture pauses the animator, writes into fractionComplete, then continues from the current progress on release."
        explanationLabel.font = .preferredFont(forTextStyle: .body)
        explanationLabel.textColor = .secondaryLabel
        explanationLabel.numberOfLines = 0
        explanationLabel.adjustsFontForContentSizeCategory = true

        statusLabel.font = .monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
    }

    private func configureCard() {
        trackView.backgroundColor = UIColor.secondarySystemGroupedBackground
        trackView.layer.cornerRadius = 28

        cardView.backgroundColor = UIColor.systemBlue
        cardView.layer.cornerRadius = 24
        cardView.layer.shadowColor = UIColor.black.cgColor
        cardView.layer.shadowOpacity = 0.18
        cardView.layer.shadowRadius = 14
        cardView.layer.shadowOffset = CGSize(width: 0, height: 8)

        cardTitleLabel.text = "Drag me"
        cardTitleLabel.font = .preferredFont(forTextStyle: .title3)
        cardTitleLabel.textColor = .white
        cardTitleLabel.adjustsFontForContentSizeCategory = true

        cardBodyLabel.text = "pauseAnimation → fractionComplete → continueAnimation"
        cardBodyLabel.font = .preferredFont(forTextStyle: .body)
        cardBodyLabel.textColor = .white.withAlphaComponent(0.86)
        cardBodyLabel.numberOfLines = 0
        cardBodyLabel.adjustsFontForContentSizeCategory = true
    }

    private func configureLayout() {
        let textStack = UIStackView(arrangedSubviews: [titleLabel, explanationLabel, statusLabel])
        textStack.axis = .vertical
        textStack.spacing = 12

        let cardTextStack = UIStackView(arrangedSubviews: [cardTitleLabel, cardBodyLabel])
        cardTextStack.axis = .vertical
        cardTextStack.spacing = 8
        cardTextStack.isUserInteractionEnabled = false

        [textStack, trackView, cardView, cardTextStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        view.addSubview(textStack)
        view.addSubview(trackView)
        trackView.addSubview(cardView)
        cardView.addSubview(cardTextStack)

        let cardCenterYConstraint = cardView.centerYAnchor.constraint(equalTo: trackView.centerYAnchor, constant: offset(for: currentState.targetProgress))
        self.cardCenterYConstraint = cardCenterYConstraint

        NSLayoutConstraint.activate([
            textStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            textStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            textStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            trackView.topAnchor.constraint(equalTo: textStack.bottomAnchor, constant: 24),
            trackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            trackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            trackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),

            cardView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: trackView.trailingAnchor, constant: -24),
            cardView.heightAnchor.constraint(equalToConstant: 150),
            cardCenterYConstraint,

            cardTextStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            cardTextStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            cardTextStack.centerYAnchor.constraint(equalTo: cardView.centerYAnchor)
        ])
    }

    private func configureGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        cardView.addGestureRecognizer(panGesture)
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            interactionStartState = currentState
            animator?.stopAnimation(true)
            animator = nil
            makeAnimator(to: currentState == .collapsed ? .expanded : .collapsed).pauseAnimation()
            updateStatus(progress: currentState.targetProgress, phase: "Paused")

        case .changed:
            let translation = gesture.translation(in: trackView).y
            let progress = AnimationProgressModel.progress(
                start: interactionStartState,
                translation: translation,
                travelDistance: travelDistance
            )
            animator?.fractionComplete = progress
            cardCenterYConstraint?.constant = offset(for: progress)
            updateStatus(progress: progress, phase: "Scrubbing")

        case .ended, .cancelled, .failed:
            let velocity = gesture.velocity(in: trackView).y
            let progress = animator?.fractionComplete ?? currentState.targetProgress
            let targetState = AnimationProgressModel.snapState(progress: progress, velocity: velocity)
            continueAnimation(to: targetState, from: progress)

        default:
            break
        }
    }

    private func makeAnimator(to targetState: AnimationSnapState) -> UIViewPropertyAnimator {
        let animator = UIViewPropertyAnimator(duration: 0.65, dampingRatio: 0.82) {
            self.cardCenterYConstraint?.constant = self.offset(for: targetState.targetProgress)
            self.view.layoutIfNeeded()
        }
        self.animator = animator
        return animator
    }

    private func continueAnimation(to targetState: AnimationSnapState, from progress: CGFloat) {
        currentState = targetState
        let animator = makeAnimator(to: targetState)
        animator.fractionComplete = progress
        animator.addCompletion { [weak self] _ in
            self?.updateStatus(progress: targetState.targetProgress, phase: "Completed: \(targetState.title)")
        }
        updateStatus(progress: progress, phase: "Continuing to \(targetState.title)")
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }

    private func offset(for progress: CGFloat) -> CGFloat {
        let clampedProgress = AnimationProgressModel.clampedProgress(progress)
        return travelDistance * (0.5 - clampedProgress)
    }

    private func updateStatus(progress: CGFloat, phase: String) {
        let percent = Int((AnimationProgressModel.clampedProgress(progress) * 100).rounded())
        statusLabel.text = "\(phase)\nprogress: \(percent)%"
    }
}
