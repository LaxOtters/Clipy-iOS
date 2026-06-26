//
//  SessionTopBarView.swift
//  Clipy
//
//  Created by 박민서 on 6/24/26.
//

import UIKit

import RxCocoa
import RxSwift

/// Session에서 Home, 제목, item 추가, 접기/펼치기를 담는 상단 floating bar입니다.
final class SessionTopBarView: UIView {
    private enum Layout {
        static let height: CGFloat = 56
        static let horizontalInset: CGFloat = 16
        static let itemSpacing: CGFloat = 12
        static let cornerRadius: CGFloat = 18
    }

    fileprivate let homeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let addItemButton = UIButton(type: .system)
    fileprivate let toggleButton = UIButton(type: .system)
    private let contentStackView = UIStackView()
    private var renderedState: SessionTopBarState = .unfolded

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureStyle()
        configureLayout()
        render(state: renderedState)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func configureHierarchy() {
        addSubview(contentStackView)

        contentStackView.addArrangedSubview(homeButton)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(addItemButton)
        contentStackView.addArrangedSubview(toggleButton)
    }

    private func configureStyle() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = Layout.cornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

        contentStackView.axis = .horizontal
        contentStackView.alignment = .center
        contentStackView.spacing = Layout.itemSpacing
        contentStackView.layoutMargins = UIEdgeInsets(
            top: 0,
            left: Layout.horizontalInset,
            bottom: 0,
            right: Layout.horizontalInset
        )
        contentStackView.isLayoutMarginsRelativeArrangement = true

        homeButton.setTitle("Home", for: .normal)
        homeButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)

        titleLabel.text = "Session"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        addItemButton.setTitle("Add Item", for: .normal)
        addItemButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)

        toggleButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)

        accessibilityIdentifier = "sessionTopBar"
        homeButton.accessibilityIdentifier = "sessionTopBar.home"
        titleLabel.accessibilityIdentifier = "sessionTopBar.title"
        addItemButton.accessibilityIdentifier = "sessionTopBar.addItem"
        toggleButton.accessibilityIdentifier = "sessionTopBar.toggle"
    }

    private func configureLayout() {
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Layout.height),

            contentStackView.topAnchor.constraint(equalTo: topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Interface

extension SessionTopBarView {
    /// 접힘 상태에 맞게 보일 control과 toggle title을 맞춥니다.
    func render(state: SessionTopBarState) {
        renderedState = state

        switch state {
        case .folded:
            homeButton.isHidden = true
            titleLabel.isHidden = true
            addItemButton.isHidden = true
            toggleButton.setTitle("Expand", for: .normal)
        case .unfolded:
            homeButton.isHidden = false
            titleLabel.isHidden = false
            addItemButton.isHidden = false
            toggleButton.setTitle("Collapse", for: .normal)
        }
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionTopBarView {
    var homeTap: ControlEvent<Void> {
        base.homeButton.rx.tap
    }

    var toggleTap: ControlEvent<Void> {
        base.toggleButton.rx.tap
    }
}
