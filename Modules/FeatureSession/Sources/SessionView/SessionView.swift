//
//  SessionView.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import Foundation
import UIKit

import RxCocoa
import RxSwift

final class SessionView: UIView {
    fileprivate let homeButton = UIButton(type: .system)
    private let browserView = SessionWebView()
    private let headerView = UIView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureStyle()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    private func configureHierarchy() {
        addSubview(headerView)
        addSubview(browserView)

        headerView.addSubview(homeButton)
        headerView.addSubview(titleLabel)
    }

    private func configureStyle() {
        backgroundColor = .systemBackground
        headerView.backgroundColor = .systemBackground

        homeButton.setTitle("Home", for: .normal)
        homeButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)

        titleLabel.text = "Session"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
    }

    private func configureLayout() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        browserView.translatesAutoresizingMaskIntoConstraints = false
        homeButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 56),

            browserView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            browserView.leadingAnchor.constraint(equalTo: leadingAnchor),
            browserView.trailingAnchor.constraint(equalTo: trailingAnchor),
            browserView.bottomAnchor.constraint(equalTo: bottomAnchor),

            homeButton.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.leadingAnchor),
            homeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: homeButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: headerView.layoutMarginsGuide.trailingAnchor)
        ])
    }
}

// MARK: - Interface

extension SessionView {
    func load(url: URL) {
        browserView.load(url: url)
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionView {
    var homeTap: ControlEvent<Void> {
        base.homeButton.rx.tap
    }
}
