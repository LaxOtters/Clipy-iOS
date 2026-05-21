//
//  SessionBottomSheetView.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

import UIKit

/// Session 화면 위에서 Hidden / Peek / Expanded 상태를 렌더링하는 Bottom Sheet primitive입니다.
final class SessionBottomSheetView: UIView {
    private enum Layout {
        static let grabberWidth: CGFloat = 44
        static let grabberHeight: CGFloat = 5
        static let cornerRadius: CGFloat = 20
        static let expandedOffset: CGFloat = 0

        static func accessibilityValue(for state: SessionBottomSheetState) -> String {
            switch state {
            case .hidden:
                return "Hidden"
            case .peek:
                return "Peek"
            case .expanded:
                return "Expanded"
            }
        }
    }

    private let grabberView = UIView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let contentStackView = UIStackView()
    private var stateMachine = SessionBottomSheetStateMachine()
    private let layoutPolicy = SessionBottomSheetLayoutPolicy.standard
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
        render(state: stateMachine.currentState, animated: false)
    }

    private func configureHierarchy() {
        addSubview(grabberView)
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
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
        grabberView.isAccessibilityElement = true
        grabberView.accessibilityLabel = "Bottom sheet grabber"
        grabberView.accessibilityHint = "Drag up or down to change the sheet state."

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

    private func configureGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    private func configureLayout() {
        grabberView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            grabberView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            grabberView.centerXAnchor.constraint(equalTo: centerXAnchor),
            grabberView.widthAnchor.constraint(equalToConstant: Layout.grabberWidth),
            grabberView.heightAnchor.constraint(equalToConstant: Layout.grabberHeight),

            contentStackView.topAnchor.constraint(equalTo: grabberView.bottomAnchor, constant: 18),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    @objc
    private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            render(state: stateMachine.currentState, animated: false)
            dragStartOffset = currentOffset
        case .changed:
            let translationY = gesture.translation(in: self).y
            setOffset(dragStartOffset + translationY, animated: false)
        case .ended, .cancelled, .failed:
            let translationY = gesture.translation(in: self).y
            let velocityY = gesture.velocity(in: self).y
            let state = stateMachine.handle(.dragEnded(translationY: translationY, velocityY: velocityY))
            render(state: state, animated: true)
        case .possible:
            break
        @unknown default:
            render(state: stateMachine.currentState, animated: true)
        }
    }

    private func render(state: SessionBottomSheetState, animated: Bool) {
        grabberView.accessibilityValue = Layout.accessibilityValue(for: state)
        setOffset(layoutPolicy.offset(for: state, availableHeight: bounds.height), animated: animated)
    }

    private func setOffset(_ offset: CGFloat, animated: Bool) {
        let clampedOffset = min(max(offset, Layout.expandedOffset), hiddenOffset)
        currentOffset = clampedOffset
        updateContentVisibility(for: clampedOffset)

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

    private func updateContentVisibility(for offset: CGFloat) {
        let travelDistance = max(1, hiddenOffset - peekOffset)
        let visibleProgress = (hiddenOffset - offset) / travelDistance
        contentStackView.alpha = min(max(visibleProgress, 0), 1)
    }

    private var hiddenOffset: CGFloat {
        layoutPolicy.offset(for: .hidden, availableHeight: bounds.height)
    }

    private var peekOffset: CGFloat {
        layoutPolicy.offset(for: .peek, availableHeight: bounds.height)
    }
}
