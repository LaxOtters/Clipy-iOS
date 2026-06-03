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

/// Session 화면의 header와 browser 영역을 배치하는 root view입니다.
final class SessionView: UIView {
    fileprivate let homeButton = UIButton(type: .system)
    private let browserView = SessionWebView()
    fileprivate let bottomSheetView = SessionBottomSheetView()
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
        addSubview(bottomSheetView)

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
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false
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

            bottomSheetView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            bottomSheetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSheetView.bottomAnchor.constraint(equalTo: bottomAnchor),

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
    /// 초기 URL load command를 WebView wrapper로 넘깁니다.
    func load(url: URL) {
        browserView.load(url: url)
    }

    /// Bottom Sheet ViewModel state를 내부 sheet component에 전달합니다.
    func render(bottomSheetState: SessionBottomSheetState, animated: Bool) {
        bottomSheetView.render(state: bottomSheetState, animated: animated)
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionView {
    /// Home button tap을 화면 종료 input으로 엽니다.
    var homeTap: ControlEvent<Void> {
        base.homeButton.rx.tap
    }

    /// Bottom Sheet grabber drag 종료 action을 ViewModel input으로 엽니다.
    var bottomSheetDragEnded: Signal<SessionBottomSheetAction> {
        base.bottomSheetView.rx.dragEnded
    }
}
