import UIKit

final class StoryDetailPageViewController: UIViewController {
    let story: Story

    private let playbackStore: StoryPlaybackStore
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    init(story: Story, playbackStore: StoryPlaybackStore) {
        self.story = story
        self.playbackStore = playbackStore
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureScrollView()
        configureContent()
    }

    private func configureScrollView() {
        scrollView.accessibilityIdentifier = "story.detail.scroll.\(story.id)"
        scrollView.alwaysBounceVertical = true
        scrollView.isDirectionalLockEnabled = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 24
        contentStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -48),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
    }

    private func configureContent() {
        let heroView = StoryHeroView(story: story, playbackStore: playbackStore)
        heroView.accessibilityIdentifier = "story.detail.hero.\(story.id)"
        contentStack.addArrangedSubview(heroView)
        heroView.heightAnchor.constraint(greaterThanOrEqualToConstant: 430).isActive = true

        StoryDetailContent.sections.forEach { section in
            let sectionStack = makeSection(title: section.title, body: section.body)
            contentStack.addArrangedSubview(sectionStack)
            sectionStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 24, bottom: 0, trailing: 24)
            sectionStack.isLayoutMarginsRelativeArrangement = true
        }
    }

    private func makeSection(title: String, body: String) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .title2).withTraits(.traitBold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.numberOfLines = 0
        titleLabel.text = title

        let bodyLabel = UILabel()
        bodyLabel.font = .preferredFont(forTextStyle: .body)
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.textColor = .secondaryLabel
        bodyLabel.numberOfLines = 0
        bodyLabel.text = body

        let stack = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }
}
