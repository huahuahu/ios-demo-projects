import UIKit

final class MainViewController: UIViewController {
    private enum Section {
        case main
    }

    private enum UpdateMode: Int, CaseIterable {
        case diffable
        case manual

        var title: String {
            switch self {
            case .diffable:
                "Diffable"
            case .manual:
                "Manual"
            }
        }
    }

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemGroupedBackground
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.alwaysBounceVertical = true
        collectionView.delegate = self
        return collectionView
    }()

    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.text = "演示策略：同一套更新队列，对比 diffable snapshot 和手写 performBatchUpdates。动画中只保留最新 pending；被合并掉的 enqueue 也会收到 coalesced completion。"
        return label
    }()

    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var modeControl: UISegmentedControl = {
        let control = UISegmentedControl(items: UpdateMode.allCases.map(\.title))
        control.selectedSegmentIndex = updateMode.rawValue
        control.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        return control
    }()

    private lazy var singleUpdateButton: UIButton = makeButton(
        title: "触发单次动画更新",
        action: #selector(runSingleUpdate)
    )

    private lazy var burstUpdateButton: UIButton = makeButton(
        title: "触发高频更新（15次）",
        action: #selector(runBurstUpdate)
    )

    private lazy var resetButton: UIButton = makeButton(
        title: "重置初始数据",
        action: #selector(resetData)
    )

    private lazy var forceSyncButton: UIButton = makeButton(
        title: "强制无动画对齐",
        action: #selector(forceSync)
    )

    private lazy var controlsStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            descriptionLabel,
            statusLabel,
            modeControl,
            singleUpdateButton,
            burstUpdateButton,
            resetButton,
            forceSyncButton
        ])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var diffableDataSource: UICollectionViewDiffableDataSource<Section, DemoItem.ID> = makeDiffableDataSource()

    private var itemByID: [DemoItem.ID: DemoItem] = [:]
    private var manualItems: [DemoItem] = []
    private var updateQueue: SnapshotUpdateQueue<[DemoItem]>!
    private var burstTask: Task<Void, Never>?
    private var updateMode = UpdateMode.diffable
    private var lastManualPlanSummary = "manual not used"
    private var mutationStep = 0
    private var enqueueCount = 0
    private var appliedCompletionCount = 0
    private var coalescedCompletionCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "CollectionView 动画更新"
        view.backgroundColor = .systemBackground
        collectionView.register(CollectionItemCell.self, forCellWithReuseIdentifier: CollectionItemCell.reuseIdentifier)
        setupLayout()
        resetToInitialState(reason: "初始加载")
    }

    @objc private func modeChanged() {
        guard let nextMode = UpdateMode(rawValue: modeControl.selectedSegmentIndex) else {
            return
        }

        guard !updateQueue.isBusy else {
            modeControl.selectedSegmentIndex = updateMode.rawValue
            updateStatus(reason: "动画进行中，暂不切换模式")
            return
        }

        cancelBurstUpdates()
        updateMode = nextMode
        let currentItems = updateQueue.currentState
        updateQueue = makeUpdateQueue(initialState: currentItems)
        applyCurrentMode(currentItems, animated: false, reason: "切换到 \(nextMode.title)")
    }

    @objc private func runSingleUpdate() {
        mutationStep += 1
        let nextItems = ItemMutationEngine.makeNextItems(from: updateQueue.currentState, step: mutationStep)
        enqueue(nextItems, reason: "单次动画更新")
    }

    @objc private func runBurstUpdate() {
        cancelBurstUpdates()

        burstTask = Task { @MainActor [weak self] in
            for _ in 0..<15 {
                try? await Task.sleep(nanoseconds: 120_000_000)
                guard !Task.isCancelled, let self else {
                    return
                }

                self.mutationStep += 1
                let nextItems = ItemMutationEngine.makeNextItems(from: self.updateQueue.currentState, step: self.mutationStep)
                self.enqueue(nextItems, reason: "高频变更写入")
            }

            self?.burstTask = nil
            self?.updateStatus(reason: "高频更新结束")
        }

        updateStatus(reason: "开始高频更新")
    }

    @objc private func resetData() {
        cancelBurstUpdates()
        mutationStep = 0
        resetToInitialState(reason: "重置完成")
    }

    @objc private func forceSync() {
        cancelBurstUpdates()
        mutationStep += 1
        let nextItems = ItemMutationEngine.makeNextItems(from: updateQueue.currentState, step: mutationStep)
        updateQueue = makeUpdateQueue(initialState: nextItems)
        applyCurrentMode(nextItems, animated: false, reason: "强制无动画对齐")
    }

    private func resetToInitialState(reason: String) {
        let items = ItemMutationEngine.makeInitialItems()
        updateQueue = makeUpdateQueue(initialState: items)
        enqueueCount = 0
        appliedCompletionCount = 0
        coalescedCompletionCount = 0
        applyCurrentMode(items, animated: false, reason: reason)
    }

    private func enqueue(_ items: [DemoItem], reason: String) {
        enqueueCount += 1
        let requestNumber = enqueueCount

        updateQueue.submit(
            items,
            onComplete: { [weak self] result in
                guard let self else {
                    return
                }

                switch result {
                case .applied:
                    self.appliedCompletionCount += 1
                case .coalesced:
                    self.coalescedCompletionCount += 1
                }

                self.updateStatus(reason: "enqueue #\(requestNumber) completion: \(result.label)")
            }
        )

        updateStatus(reason: "\(reason) 已入队")
    }

    private func makeUpdateQueue(initialState: [DemoItem]) -> SnapshotUpdateQueue<[DemoItem]> {
        SnapshotUpdateQueue(initialState: initialState) { [weak self] state in
            guard let self else {
                return
            }

            await self.applyCurrentModeAndWait(state, animated: true, reason: "动画 apply 完成")
        }
    }

    private func applyCurrentMode(
        _ items: [DemoItem],
        animated: Bool,
        reason: String
    ) {
        switch updateMode {
        case .diffable:
            applyDiffableSnapshot(items, animated: animated, reason: reason)
        case .manual:
            applyManualItems(items, reason: reason)
        }
    }

    private func applyCurrentModeAndWait(
        _ items: [DemoItem],
        animated: Bool,
        reason: String
    ) async {
        switch updateMode {
        case .diffable:
            await applyDiffableSnapshotAndWait(items, animated: animated, reason: reason)
        case .manual:
            await applyManualItemsAndWait(items, animated: animated, reason: reason)
        }
    }

    private func applyDiffableSnapshot(
        _ items: [DemoItem],
        animated: Bool,
        reason: String
    ) {
        collectionView.dataSource = diffableDataSource
        let snapshot = makeDiffableSnapshot(items)
        diffableDataSource.apply(snapshot, animatingDifferences: animated)
        updateStatus(reason: reason)
    }

    private func applyDiffableSnapshotAndWait(
        _ items: [DemoItem],
        animated: Bool,
        reason: String
    ) async {
        collectionView.dataSource = diffableDataSource
        let snapshot = makeDiffableSnapshot(items)
        await diffableDataSource.applySnapshotAndWait(snapshot, animatingDifferences: animated)
        updateStatus(reason: reason)
    }

    private func makeDiffableSnapshot(_ items: [DemoItem]) -> NSDiffableDataSourceSnapshot<Section, DemoItem.ID> {
        itemByID = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<Section, DemoItem.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(items.map(\.id), toSection: .main)
        return snapshot
    }

    private func applyManualItems(_ items: [DemoItem], reason: String) {
        collectionView.dataSource = self
        manualItems = items
        lastManualPlanSummary = "manual reloadData"
        collectionView.reloadData()
        updateStatus(reason: reason)
    }

    private func applyManualItemsAndWait(
        _ items: [DemoItem],
        animated: Bool,
        reason: String
    ) async {
        collectionView.dataSource = self

        guard animated else {
            applyManualItems(items, reason: reason)
            return
        }

        let plan = ManualBatchUpdatePlan.make(oldItems: manualItems, newItems: items)
        lastManualPlanSummary = plan.summary

        guard !plan.shouldReloadData else {
            manualItems = items
            collectionView.reloadData()
            updateStatus(reason: "\(reason) | \(plan.summary)")
            return
        }

        guard !plan.isNoOp else {
            manualItems = items
            updateStatus(reason: "\(reason) | manual no-op")
            return
        }

        let finished = await collectionView.performBatchUpdatesAndWait { [weak self] in
            guard let self else {
                return
            }

            self.manualItems = items
            self.collectionView.deleteItems(at: plan.deletes)
            self.collectionView.insertItems(at: plan.inserts)

            for move in plan.moves {
                self.collectionView.moveItem(at: move.from, to: move.to)
            }

            if !plan.reloads.isEmpty {
                self.collectionView.reloadItems(at: plan.reloads)
            }
        }

        updateStatus(reason: "\(reason) | \(plan.summary) | finished: \(finished)")
    }

    private func updateStatus(reason: String) {
        statusLabel.text = StatusFormatter.makeStatusText(
            reason: reason,
            mode: updateMode.title,
            itemCount: updateQueue.currentState.count,
            isApplying: updateQueue.isBusy,
            hasPending: updateQueue.hasPending,
            applyCount: updateQueue.applyCount,
            enqueueCount: enqueueCount,
            completionCount: appliedCompletionCount + coalescedCompletionCount,
            appliedCompletionCount: appliedCompletionCount,
            coalescedCompletionCount: coalescedCompletionCount,
            detail: updateMode == .manual ? lastManualPlanSummary : "diffable snapshot"
        )
    }

    private func cancelBurstUpdates() {
        burstTask?.cancel()
        burstTask = nil
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        var configuration = UIButton.Configuration.filled()
        configuration.title = title
        configuration.cornerStyle = .medium

        let button = UIButton(configuration: configuration)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func makeDiffableDataSource() -> UICollectionViewDiffableDataSource<Section, DemoItem.ID> {
        UICollectionViewDiffableDataSource<Section, DemoItem.ID>(
            collectionView: collectionView
        ) { [weak self] collectionView, indexPath, itemID in
            guard
                let self,
                let item = self.itemByID[itemID],
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: CollectionItemCell.reuseIdentifier,
                    for: indexPath
                ) as? CollectionItemCell
            else {
                return nil
            }

            cell.configure(with: item)
            return cell
        }
    }

    private func setupLayout() {
        view.addSubview(controlsStack)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            controlsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            controlsStack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            controlsStack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            collectionView.topAnchor.constraint(equalTo: controlsStack.bottomAnchor, constant: 12),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        manualItems.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: CollectionItemCell.reuseIdentifier,
                for: indexPath
            ) as? CollectionItemCell
        else {
            return UICollectionViewCell()
        }

        cell.configure(with: manualItems[indexPath.item])
        return cell
    }
}

private extension SnapshotUpdateCompletion {
    var label: String {
        switch self {
        case .applied:
            "applied"
        case .coalesced:
            "coalesced"
        }
    }
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let inset = 12.0 * 2.0
        let spacing = 10.0 * 2.0
        let availableWidth = collectionView.bounds.width - inset - spacing
        let width = floor(availableWidth / 3.0)
        return CGSize(width: max(72, width), height: 52)
    }
}
