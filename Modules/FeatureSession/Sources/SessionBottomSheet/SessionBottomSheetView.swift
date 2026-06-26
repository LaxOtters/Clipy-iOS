//
//  SessionBottomSheetView.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

import UIKit

import RxCocoa
import RxRelay
import RxSwift

/// Session WebView 위에서 grabber drag와 state render를 담당하는 Bottom Sheet view입니다.
final class SessionBottomSheetView: UIView {
    private enum Layout {
        static let grabberWidth: CGFloat = 44
        static let grabberHeight: CGFloat = 5
        /// 시각적 grabber보다 넓게 둔 drag 시작 영역입니다.
        static let grabberHitAreaHeight: CGFloat = 32
        static let cornerRadius: CGFloat = 20
    }

    private enum Animation {
        static let snapDuration: TimeInterval = 0.24
        static let snapDamping: CGFloat = 0.86
        static let snapInitialVelocity: CGFloat = 0.3
    }

    private let grabberHitAreaView = UIView()
    private let grabberView = UIView()
    private let browserControlRowStackView = UIStackView()
    private let previousButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let urlContainerView = UIView()
    private let urlLabel = UILabel()
    private let refreshButton = UIButton(type: .system)
    private let peekTitleLabel = UILabel()
    private let peekDescriptionLabel = UILabel()
    private let peekContentStackView = UIStackView()
    private let expandedTitleLabel = UILabel()
    private let expandedDescriptionLabel = UILabel()
    private let expandedContentStackView = UIStackView()
    fileprivate let dragEndedRelay = PublishRelay<SessionBottomSheetAction>()
    private var policy = SessionBottomSheetPolicy.standard
    private var renderedState: SessionBottomSheetState = .peek
    private var currentOffset: CGFloat = 0
    private var dragStartOffset: CGFloat = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureStyle()
        configureGesture()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        render(state: renderedState, animated: false)
    }

    private func configureHierarchy() {
        addSubview(grabberHitAreaView)
        addSubview(browserControlRowStackView)
        addSubview(peekContentStackView)
        addSubview(expandedContentStackView)

        grabberHitAreaView.addSubview(grabberView)
        browserControlRowStackView.addArrangedSubview(previousButton)
        browserControlRowStackView.addArrangedSubview(nextButton)
        browserControlRowStackView.addArrangedSubview(urlContainerView)
        browserControlRowStackView.addArrangedSubview(refreshButton)
        urlContainerView.addSubview(urlLabel)
        peekContentStackView.addArrangedSubview(peekTitleLabel)
        peekContentStackView.addArrangedSubview(peekDescriptionLabel)
        expandedContentStackView.addArrangedSubview(expandedTitleLabel)
        expandedContentStackView.addArrangedSubview(expandedDescriptionLabel)
    }

    private func configureStyle() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = Layout.cornerRadius
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 0, height: -4)

        grabberView.backgroundColor = .tertiaryLabel
        grabberView.layer.cornerRadius = Layout.grabberHeight / 2

        browserControlRowStackView.axis = .horizontal
        browserControlRowStackView.alignment = .center
        browserControlRowStackView.spacing = 8
        browserControlRowStackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        browserControlRowStackView.isLayoutMarginsRelativeArrangement = true

        previousButton.setTitle("‹", for: .normal)
        previousButton.titleLabel?.font = .preferredFont(forTextStyle: .title2)

        nextButton.setTitle("›", for: .normal)
        nextButton.titleLabel?.font = .preferredFont(forTextStyle: .title2)

        urlContainerView.backgroundColor = .tertiarySystemBackground
        urlContainerView.layer.cornerRadius = 12

        urlLabel.text = "Search or enter URL"
        urlLabel.font = .preferredFont(forTextStyle: .subheadline)
        urlLabel.textColor = .secondaryLabel
        urlLabel.lineBreakMode = .byTruncatingMiddle

        refreshButton.setTitle("↻", for: .normal)
        refreshButton.titleLabel?.font = .preferredFont(forTextStyle: .title3)

        [peekContentStackView, expandedContentStackView].forEach {
            $0.axis = .vertical
            $0.alignment = .fill
            $0.spacing = 8
            $0.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            $0.isLayoutMarginsRelativeArrangement = true
        }

        peekTitleLabel.text = "No items yet"
        peekTitleLabel.font = .preferredFont(forTextStyle: .headline)
        peekTitleLabel.textColor = .label

        peekDescriptionLabel.text = "Add an item from the Top Bar to start comparing."
        peekDescriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        peekDescriptionLabel.textColor = .secondaryLabel
        peekDescriptionLabel.numberOfLines = 0

        expandedTitleLabel.text = "Comparison"
        expandedTitleLabel.font = .preferredFont(forTextStyle: .headline)
        expandedTitleLabel.textColor = .label

        expandedDescriptionLabel.text = "Expanded placeholder"
        expandedDescriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        expandedDescriptionLabel.textColor = .secondaryLabel
        expandedDescriptionLabel.numberOfLines = 0

        accessibilityIdentifier = "sessionBottomSheet"
        browserControlRowStackView.accessibilityIdentifier = "sessionBottomSheet.browserControls"
        previousButton.accessibilityIdentifier = "sessionBottomSheet.browserControls.previous"
        nextButton.accessibilityIdentifier = "sessionBottomSheet.browserControls.next"
        urlLabel.accessibilityIdentifier = "sessionBottomSheet.browserControls.url"
        refreshButton.accessibilityIdentifier = "sessionBottomSheet.browserControls.refresh"
        peekContentStackView.accessibilityIdentifier = "sessionBottomSheet.peekEmptyState"
    }

    private func configureGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        grabberHitAreaView.addGestureRecognizer(panGesture)
    }

    private func configureLayout() {
        grabberHitAreaView.translatesAutoresizingMaskIntoConstraints = false
        grabberView.translatesAutoresizingMaskIntoConstraints = false
        browserControlRowStackView.translatesAutoresizingMaskIntoConstraints = false
        urlContainerView.translatesAutoresizingMaskIntoConstraints = false
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        peekContentStackView.translatesAutoresizingMaskIntoConstraints = false
        expandedContentStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            grabberHitAreaView.topAnchor.constraint(equalTo: topAnchor),
            grabberHitAreaView.leadingAnchor.constraint(equalTo: leadingAnchor),
            grabberHitAreaView.trailingAnchor.constraint(equalTo: trailingAnchor),
            grabberHitAreaView.heightAnchor.constraint(equalToConstant: Layout.grabberHitAreaHeight),

            grabberView.centerXAnchor.constraint(equalTo: grabberHitAreaView.centerXAnchor),
            grabberView.centerYAnchor.constraint(equalTo: grabberHitAreaView.centerYAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: Layout.grabberWidth),
            grabberView.heightAnchor.constraint(equalToConstant: Layout.grabberHeight),

            browserControlRowStackView.topAnchor.constraint(equalTo: grabberHitAreaView.bottomAnchor, constant: 4),
            browserControlRowStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            browserControlRowStackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            urlContainerView.heightAnchor.constraint(equalToConstant: 36),
            urlLabel.topAnchor.constraint(equalTo: urlContainerView.topAnchor, constant: 8),
            urlLabel.leadingAnchor.constraint(equalTo: urlContainerView.leadingAnchor, constant: 12),
            urlLabel.trailingAnchor.constraint(equalTo: urlContainerView.trailingAnchor, constant: -12),
            urlLabel.bottomAnchor.constraint(equalTo: urlContainerView.bottomAnchor, constant: -8),

            peekContentStackView.topAnchor.constraint(equalTo: browserControlRowStackView.bottomAnchor, constant: 12),
            peekContentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            peekContentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            expandedContentStackView.topAnchor.constraint(equalTo: grabberHitAreaView.bottomAnchor, constant: 8),
            expandedContentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            expandedContentStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    /// drag 중에는 손 위치를 따라가고, 손을 뗀 뒤에만 state 변경을 요청합니다.
    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            dragStartOffset = currentOffset
        case .changed:
            let translationY = gesture.translation(in: self).y
            setOffset(dragStartOffset + translationY, animated: false)
        case .ended, .cancelled, .failed:
            dragEndedRelay.accept(.dragEnded(dragEndContext(for: gesture)))
        case .possible:
            break
        @unknown default:
            break
        }
    }

    /// UIKit pan gesture를 Policy input으로 바꿉니다.
    private func dragEndContext(for gesture: UIPanGestureRecognizer) -> SessionBottomSheetDragEndContext {
        let translationY = gesture.translation(in: self).y
        let proposedEndOffset = dragStartOffset + translationY
        let availableHeight = bounds.height

        return SessionBottomSheetDragEndContext(
            translationY: translationY,
            velocityY: gesture.velocity(in: self).y,
            endOffset: policy.adjustedOffset(proposedEndOffset, availableHeight: availableHeight),
            availableHeight: availableHeight
        )
    }

    /// sheet offset과 content alpha를 한 번에 화면에 반영합니다.
    private func setOffset(_ offset: CGFloat, animated: Bool) {
        let adjustedOffset = policy.adjustedOffset(offset, availableHeight: bounds.height)
        currentOffset = adjustedOffset

        let contentAlpha = policy.contentAlpha(
            offset: adjustedOffset,
            availableHeight: bounds.height
        )
        peekContentStackView.alpha = contentAlpha.peek
        expandedContentStackView.alpha = contentAlpha.expanded

        let updates = {
            self.transform = CGAffineTransform(translationX: 0, y: adjustedOffset)
        }

        if animated {
            UIView.animate(
                withDuration: Animation.snapDuration,
                delay: 0,
                usingSpringWithDamping: Animation.snapDamping,
                initialSpringVelocity: Animation.snapInitialVelocity,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: updates
            )
        } else {
            updates()
        }
    }
}

// MARK: - Interface

extension SessionBottomSheetView {
    /// drag progress에 따른 Peek/Expanded content cross-fade를 켜거나 끕니다.
    var isContentFadeEnabled: Bool {
        get { policy.isContentFadeEnabled }
        set {
            policy.isContentFadeEnabled = newValue
            render(state: renderedState, animated: false)
        }
    }

    /// ViewModel state를 sheet 위치와 browser control row 노출 상태로 렌더링합니다.
    func render(state: SessionBottomSheetState, animated: Bool) {
        renderedState = state
        browserControlRowStackView.isHidden = !policy.isBrowserControlRowVisible(for: state)
        setOffset(policy.offset(for: state, availableHeight: bounds.height), animated: animated)
    }

    /// 현재 bounds에서 state가 가리는 실제 sheet 높이입니다.
    func visibleHeight(for state: SessionBottomSheetState) -> CGFloat {
        policy.visibleHeight(for: state, availableHeight: bounds.height)
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionBottomSheetView {
    /// grabber drag가 끝났을 때 ViewModel로 전달되는 action입니다.
    var dragEnded: Signal<SessionBottomSheetAction> {
        base.dragEndedRelay.asSignal()
    }
}
