import UIKit

final class StoryListViewController: UIViewController {
    private let playbackStore: StoryPlaybackStore
    private let stories = Story.samples
    private lazy var storiesByID = Dictionary(uniqueKeysWithValues: stories.map { ($0.id, $0) })
    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private lazy var dataSource = makeDataSource()

    init(playbackStore: StoryPlaybackStore) {
        self.playbackStore = playbackStore
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Today"
        navigationItem.largeTitleDisplayMode = .always
        view.backgroundColor = .systemGroupedBackground
        configureCollectionView()
        applySnapshot()
    }

    func transitionSourceView(for storyID: Story.ID) -> UIView? {
        guard let indexPath = dataSource.indexPath(for: storyID) else { return nil }

        if
            collectionView.indexPathsForVisibleItems.contains(indexPath),
            let cell = collectionView.cellForItem(at: indexPath) as? StoryCell
        {
            return cell.transitionSourceView
        }

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        collectionView.layoutIfNeeded()
        guard collectionView.indexPathsForVisibleItems.contains(indexPath) else { return nil }
        return (collectionView.cellForItem(at: indexPath) as? StoryCell)?.transitionSourceView
    }

    func makeSourceCellTemporarilyInvisible(excluding storyID: Story.ID) {
        guard
            let sourceIndex = stories.firstIndex(where: { $0.id == storyID })
        else { return }

        let farthestStory = sourceIndex < stories.count / 2 ? stories.last : stories.first
        guard
            let otherID = farthestStory?.id,
            otherID != storyID,
            let indexPath = dataSource.indexPath(for: otherID)
        else { return }

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        collectionView.layoutIfNeeded()
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "story.collection"
        collectionView.register(StoryCell.self, forCellWithReuseIdentifier: StoryCell.reuseIdentifier)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(320)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 24
        section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 32, trailing: 16)
        return UICollectionViewCompositionalLayout(section: section)
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<StorySection, Story.ID> {
        UICollectionViewDiffableDataSource<StorySection, Story.ID>(collectionView: collectionView) { [weak self] collectionView, indexPath, storyID in
            guard
                let self,
                let story = storiesByID[storyID],
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: StoryCell.reuseIdentifier,
                    for: indexPath
                ) as? StoryCell
            else { return nil }

            cell.configure(with: story, playbackStore: playbackStore)
            return cell
        }
    }

    private func applySnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<StorySection, Story.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(stories.map(\.id))
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func showDetail(for story: Story) {
        let detailViewController = StoryDetailViewController(
            stories: stories,
            initialStory: story,
            sourceListViewController: self,
            playbackStore: playbackStore
        )

        if UIAccessibility.isReduceMotionEnabled {
            detailViewController.preferredTransition = .crossDissolve
        } else {
            detailViewController.preferredTransition = .zoom { [weak self] context in
                guard
                    let self,
                    let detail = context.zoomedViewController as? StoryDetailViewController
                else { return nil }

                return self.transitionSourceView(for: detail.currentStory.id)
            }
        }

        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

extension StoryListViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let storyID = dataSource.itemIdentifier(for: indexPath),
            let story = storiesByID[storyID]
        else { return }

        showDetail(for: story)
    }
}
