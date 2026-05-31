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

/// Session 화면 위에서 Minimized / Hidden / Peek / Expanded 상태를 렌더링하는 Bottom Sheet primitive입니다.
final class SessionBottomSheetView: UIView {
    /// Bottom Sheet primitive의 고정 layout 수치입니다.
    private enum Layout {
        /// Grabber bar의 가로 길이입니다.
        static let grabberWidth: CGFloat = 44
        /// Grabber bar의 세로 높이입니다.
        static let grabberHeight: CGFloat = 5
        /// Drag gesture를 받을 grabber touch 영역 높이입니다.
        static let grabberHitAreaHeight: CGFloat = 32
        /// Sheet 상단 모서리 radius입니다.
        static let cornerRadius: CGFloat = 20
    }

    /// Grabber drag만 받기 위한 hit area입니다.
    private let grabberHitAreaView = UIView()
    /// 사용자가 끌어올릴 수 있음을 보여주는 시각적 grabber입니다.
    private let grabberView = UIView()
    /// CLIPY-44 primitive에서 content 영역을 확인하기 위한 임시 title입니다.
    private let titleLabel = UILabel()
    /// CLIPY-44 primitive에서 content 영역을 확인하기 위한 임시 설명입니다.
    private let descriptionLabel = UILabel()
    /// 현재 Bottom Sheet content placeholder를 담는 stack view입니다.
    private let contentStackView = UIStackView()
    /// UIKit pan gesture 종료를 ViewModel input으로 넘기는 event relay입니다.
    fileprivate let dragEndedRelay = PublishRelay<SessionBottomSheetAction>()
    /// Bottom Sheet 상태와 drag offset을 실제 화면 수치로 바꾸는 정책입니다.
    private let renderingPolicy = SessionBottomSheetRenderingPolicy.standard
    /// 마지막으로 렌더링한 Bottom Sheet 상태입니다.
    private var renderedState: SessionBottomSheetState = .peek
    /// 현재 transform에 반영된 y축 offset입니다.
    private var currentOffset: CGFloat = 0
    /// Drag 시작 시점의 y축 offset입니다.
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

    /// Bottom Sheet를 구성하는 subview hierarchy를 만듭니다.
    private func configureHierarchy() {
        addSubview(grabberHitAreaView)
        addSubview(contentStackView)

        grabberHitAreaView.addSubview(grabberView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
    }

    /// Bottom Sheet primitive의 기본 색상과 typography를 설정합니다.
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

        contentStackView.axis = .vertical
        contentStackView.alignment = .fill
        contentStackView.spacing = 8
        contentStackView.layoutMargins = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        contentStackView.isLayoutMarginsRelativeArrangement = true

        titleLabel.text = "Items"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textColor = .label

        descriptionLabel.text = "Drag to open the comparison area."
        descriptionLabel.font = .preferredFont(forTextStyle: .subheadline)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.numberOfLines = 0

        accessibilityIdentifier = "sessionBottomSheet"
    }

    /// Grabber hit area에 pan gesture를 연결합니다.
    private func configureGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        grabberHitAreaView.addGestureRecognizer(panGesture)
    }

    /// Bottom Sheet 내부 placeholder와 grabber layout을 고정합니다.
    private func configureLayout() {
        grabberHitAreaView.translatesAutoresizingMaskIntoConstraints = false
        grabberView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            grabberHitAreaView.topAnchor.constraint(equalTo: topAnchor),
            grabberHitAreaView.leadingAnchor.constraint(equalTo: leadingAnchor),
            grabberHitAreaView.trailingAnchor.constraint(equalTo: trailingAnchor),
            grabberHitAreaView.heightAnchor.constraint(equalToConstant: Layout.grabberHitAreaHeight),

            grabberView.centerXAnchor.constraint(equalTo: grabberHitAreaView.centerXAnchor),
            grabberView.centerYAnchor.constraint(equalTo: grabberHitAreaView.centerYAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: Layout.grabberWidth),
            grabberView.heightAnchor.constraint(equalToConstant: Layout.grabberHeight),

            contentStackView.topAnchor.constraint(equalTo: grabberHitAreaView.bottomAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    /// Pan gesture 단계에 따라 interactive offset을 반영하거나 종료 event를 내보냅니다.
    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            dragStartOffset = currentOffset
        case .changed:
            let translationY = gesture.translation(in: self).y
            setOffset(dragStartOffset + translationY, animated: false)
        case .ended, .cancelled, .failed:
            let translationY = gesture.translation(in: self).y
            let velocityY = gesture.velocity(in: self).y
            dragEndedRelay.accept(.dragEnded(translationY: translationY, velocityY: velocityY))
        case .possible:
            break
        @unknown default:
            break
        }
    }

    /// Sheet transform에 적용할 y축 offset을 범위 안으로 보정한 뒤 반영합니다.
    private func setOffset(_ offset: CGFloat, animated: Bool) {
        let clampedOffset = renderingPolicy.clampedOffset(offset, availableHeight: bounds.height)
        currentOffset = clampedOffset
        applyContentPresentation(for: renderedState, offset: clampedOffset)

        let updates = {
            self.transform = CGAffineTransform(translationX: 0, y: clampedOffset)
        }

        if animated {
            UIView.animate(
                withDuration: 0.24,
                delay: 0,
                usingSpringWithDamping: 0.86,
                initialSpringVelocity: 0.3,
                options: [.allowUserInteraction, .beginFromCurrentState],
                animations: updates
            )
        } else {
            updates()
        }
    }

    /// 현재 상태와 offset에 맞는 content 표시 정책을 View에 적용합니다.
    private func applyContentPresentation(for state: SessionBottomSheetState, offset: CGFloat) {
        contentStackView.alpha = renderingPolicy.contentAlpha(
            for: state,
            offset: offset,
            availableHeight: bounds.height
        )
    }
}

// MARK: - Interface

extension SessionBottomSheetView {
    /// ViewModel이 결정한 Bottom Sheet 상태를 실제 화면 위치로 렌더링합니다.
    func render(state: SessionBottomSheetState, animated: Bool) {
        renderedState = state
        setOffset(renderingPolicy.offset(for: state, availableHeight: bounds.height), animated: animated)
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionBottomSheetView {
    /// Grabber drag가 끝났을 때 ViewModel로 전달할 Bottom Sheet action입니다.
    var dragEnded: Signal<SessionBottomSheetAction> {
        base.dragEndedRelay.asSignal()
    }
}
