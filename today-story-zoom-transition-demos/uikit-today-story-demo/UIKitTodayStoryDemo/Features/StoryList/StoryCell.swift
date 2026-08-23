import UIKit

final class StoryCell: UICollectionViewCell {
    static let reuseIdentifier = "StoryCell"

    private let cardView = GradientView()
    private let playerView = PlayerSurfaceView()
    private let videoScrimView = UIView()
    private let symbolImageView = UIImageView()
    private let eyebrowLabel = UILabel()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    var transitionSourceView: UIView { cardView }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViewHierarchy()
        configureAppearance()
        configureAccessibility()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        playerView.player = nil
        accessibilityIdentifier = nil
    }

    func configure(with story: Story, playbackStore: StoryPlaybackStore) {
        cardView.configure(paletteIndex: story.paletteIndex)
        playerView.player = playbackStore.player(for: story)
        playerView.isHidden = playerView.player == nil
        videoScrimView.isHidden = playerView.player == nil
        symbolImageView.image = UIImage(systemName: story.symbolName)
        symbolImageView.isHidden = playerView.player != nil
        eyebrowLabel.text = story.eyebrow.uppercased()
        titleLabel.text = story.title
        subtitleLabel.text = story.subtitle
        accessibilityLabel = "\(story.eyebrow)，\(story.title)，\(story.subtitle)"
        accessibilityHint = "打开 Story 详情"
        accessibilityIdentifier = "story.cell.\(story.id)"
    }

    private func configureViewHierarchy() {
        contentView.addSubview(cardView)
        [playerView, videoScrimView, symbolImageView, eyebrowLabel, titleLabel, subtitleLabel].forEach(cardView.addSubview)
        [cardView, playerView, videoScrimView, symbolImageView, eyebrowLabel, titleLabel, subtitleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            cardView.heightAnchor.constraint(greaterThanOrEqualToConstant: 300),

            playerView.topAnchor.constraint(equalTo: cardView.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            videoScrimView.topAnchor.constraint(equalTo: cardView.topAnchor),
            videoScrimView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            videoScrimView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),
            videoScrimView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor),

            symbolImageView.widthAnchor.constraint(equalToConstant: 130),
            symbolImageView.heightAnchor.constraint(equalTo: symbolImageView.widthAnchor),
            symbolImageView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 24),
            symbolImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            eyebrowLabel.topAnchor.constraint(greaterThanOrEqualTo: symbolImageView.bottomAnchor, constant: 12),
            eyebrowLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            eyebrowLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -24),

            titleLabel.topAnchor.constraint(equalTo: eyebrowLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: eyebrowLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: eyebrowLabel.trailingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: eyebrowLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: eyebrowLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -24)
        ])
    }

    private func configureAppearance() {
        cardView.layer.cornerRadius = 28
        cardView.layer.cornerCurve = .continuous
        cardView.layer.masksToBounds = true

        symbolImageView.tintColor = UIColor.white.withAlphaComponent(0.25)
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.isAccessibilityElement = false
        videoScrimView.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        videoScrimView.isUserInteractionEnabled = false
        videoScrimView.isAccessibilityElement = false

        eyebrowLabel.font = .preferredFont(forTextStyle: .subheadline)
        eyebrowLabel.adjustsFontForContentSizeCategory = true
        eyebrowLabel.textColor = .white
        eyebrowLabel.numberOfLines = 0

        titleLabel.font = .preferredFont(forTextStyle: .largeTitle).withTraits(.traitBold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0

        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .white
        subtitleLabel.numberOfLines = 0

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.18
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 9)
    }

    private func configureAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }
}

extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else { return self }
        return UIFont(descriptor: descriptor, size: 0)
    }
}
