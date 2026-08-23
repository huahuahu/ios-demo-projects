import UIKit

final class StoryHeroView: GradientView {
    init(story: Story, playbackStore: StoryPlaybackStore) {
        super.init(frame: .zero)
        configure(paletteIndex: story.paletteIndex)
        configureAppearance()
        configureContent(for: story, playbackStore: playbackStore)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureAppearance() {
        isAccessibilityElement = true
        accessibilityIdentifier = "story.detail.hero"
    }

    private func configureContent(for story: Story, playbackStore: StoryPlaybackStore) {
        let playerView = PlayerSurfaceView()
        playerView.player = playbackStore.player(for: story)
        playerView.isHidden = playerView.player == nil

        let videoScrimView = UIView()
        videoScrimView.backgroundColor = UIColor.black.withAlphaComponent(0.24)
        videoScrimView.isHidden = playerView.player == nil
        videoScrimView.isUserInteractionEnabled = false
        videoScrimView.isAccessibilityElement = false

        let symbolImageView = UIImageView(image: UIImage(systemName: story.symbolName))
        symbolImageView.tintColor = UIColor.white.withAlphaComponent(0.24)
        symbolImageView.contentMode = .scaleAspectFit
        symbolImageView.isAccessibilityElement = false
        symbolImageView.isHidden = playerView.player != nil

        let eyebrowLabel = UILabel()
        eyebrowLabel.font = .preferredFont(forTextStyle: .headline)
        eyebrowLabel.adjustsFontForContentSizeCategory = true
        eyebrowLabel.textColor = .white
        eyebrowLabel.text = story.eyebrow.uppercased()

        let titleLabel = UILabel()
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle).withTraits(.traitBold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 0
        titleLabel.text = story.title

        let subtitleLabel = UILabel()
        subtitleLabel.font = .preferredFont(forTextStyle: .title3)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = .white
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = story.subtitle

        let textStack = UIStackView(arrangedSubviews: [eyebrowLabel, titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 12

        [playerView, videoScrimView, symbolImageView, textStack].forEach(addSubview)
        playerView.translatesAutoresizingMaskIntoConstraints = false
        videoScrimView.translatesAutoresizingMaskIntoConstraints = false
        symbolImageView.translatesAutoresizingMaskIntoConstraints = false
        textStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: topAnchor),
            playerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: bottomAnchor),

            videoScrimView.topAnchor.constraint(equalTo: topAnchor),
            videoScrimView.leadingAnchor.constraint(equalTo: leadingAnchor),
            videoScrimView.trailingAnchor.constraint(equalTo: trailingAnchor),
            videoScrimView.bottomAnchor.constraint(equalTo: bottomAnchor),

            symbolImageView.widthAnchor.constraint(equalToConstant: 160),
            symbolImageView.heightAnchor.constraint(equalTo: symbolImageView.widthAnchor),
            symbolImageView.topAnchor.constraint(equalTo: topAnchor, constant: 36),
            symbolImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

            textStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            textStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            textStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -28)
        ])

        accessibilityLabel = "\(story.eyebrow)，\(story.title)，\(story.subtitle)"
    }
}
