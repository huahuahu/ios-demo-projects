import UIKit

final class StoryDetailViewController: UIViewController {
    private(set) var currentStory: Story

    private weak var sourceListViewController: StoryListViewController?
    private let stories: [Story]
    private let playbackStore: StoryPlaybackStore
    private let pageViewController = UIPageViewController(
        transitionStyle: .scroll,
        navigationOrientation: .horizontal
    )
    private var didForceSourceOffscreen = false

    init(
        stories: [Story],
        initialStory: Story,
        sourceListViewController: StoryListViewController,
        playbackStore: StoryPlaybackStore
    ) {
        self.stories = stories
        currentStory = initialStory
        self.sourceListViewController = sourceListViewController
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
        navigationItem.largeTitleDisplayMode = .never
        configureCloseButton()
        configurePageViewController()
        updateNavigationTitle()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard
            !didForceSourceOffscreen,
            ProcessInfo.processInfo.arguments.contains("--force-source-offscreen")
        else { return }

        didForceSourceOffscreen = true
        sourceListViewController?.makeSourceCellTemporarilyInvisible(excluding: currentStory.id)
    }

    private func configureCloseButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.image = UIImage(systemName: "xmark")
        configuration.cornerStyle = .capsule
        configuration.baseForegroundColor = .label
        configuration.baseBackgroundColor = .secondarySystemBackground

        let button = UIButton(configuration: configuration, primaryAction: UIAction { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        button.accessibilityLabel = "关闭 Story"
        button.accessibilityIdentifier = "story.detail.close"
        button.widthAnchor.constraint(equalToConstant: 44).isActive = true
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: button)
    }

    private func configurePageViewController() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.view.accessibilityIdentifier = "story.detail.pager"

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pageViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        pageViewController.didMove(toParent: self)

        pageViewController.setViewControllers(
            [makePage(for: currentStory)],
            direction: .forward,
            animated: false
        )
    }

    private func makePage(for story: Story) -> StoryDetailPageViewController {
        StoryDetailPageViewController(story: story, playbackStore: playbackStore)
    }

    private func story(before story: Story) -> Story? {
        guard
            let index = stories.firstIndex(of: story),
            index > stories.startIndex
        else { return nil }
        return stories[stories.index(before: index)]
    }

    private func story(after story: Story) -> Story? {
        guard
            let index = stories.firstIndex(of: story),
            index < stories.index(before: stories.endIndex)
        else { return nil }
        return stories[stories.index(after: index)]
    }

    private func updateNavigationTitle() {
        title = currentStory.eyebrow
    }
}

extension StoryDetailViewController: UIPageViewControllerDataSource {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard
            let page = viewController as? StoryDetailPageViewController,
            let previousStory = story(before: page.story)
        else { return nil }
        return makePage(for: previousStory)
    }

    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard
            let page = viewController as? StoryDetailPageViewController,
            let nextStory = story(after: page.story)
        else { return nil }
        return makePage(for: nextStory)
    }

    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        stories.count
    }

    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        stories.firstIndex(of: currentStory) ?? 0
    }
}

extension StoryDetailViewController: UIPageViewControllerDelegate {
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard
            completed,
            let page = pageViewController.viewControllers?.first as? StoryDetailPageViewController
        else { return }

        currentStory = page.story
        updateNavigationTitle()
    }
}
