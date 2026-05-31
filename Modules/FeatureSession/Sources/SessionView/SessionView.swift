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
    /// Session을 닫고 Home으로 돌아가는 header button입니다.
    fileprivate let homeButton = UIButton(type: .system)
    /// Session 안에서 웹페이지를 표시하는 WebView wrapper입니다.
    private let browserView = SessionWebView()
    /// Browser 위에 겹쳐지는 Bottom Sheet primitive입니다.
    fileprivate let bottomSheetView = SessionBottomSheetView()
    /// Home button과 session title을 담는 상단 영역입니다.
    private let headerView = UIView()
    /// 현재 Session 이름을 표시할 placeholder title입니다.
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

    /// Session root view의 subview hierarchy를 구성합니다.
    private func configureHierarchy() {
        addSubview(headerView)
        addSubview(browserView)
        addSubview(bottomSheetView)

        headerView.addSubview(homeButton)
        headerView.addSubview(titleLabel)
    }

    /// CLIPY-44 기준의 임시 header와 title style을 적용합니다.
    private func configureStyle() {
        backgroundColor = .systemBackground
        headerView.backgroundColor = .systemBackground

        homeButton.setTitle("Home", for: .normal)
        homeButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)

        titleLabel.text = "Session"
        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.textAlignment = .center
    }

    /// Header, browser, Bottom Sheet가 한 화면에 겹치는 layout을 고정합니다.
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
    /// Browser 영역에 초기 URL load command를 전달합니다.
    func load(url: URL) {
        browserView.load(url: url)
    }

    /// Bottom Sheet 상태를 root view 내부 component에 렌더링합니다.
    func render(bottomSheetState: SessionBottomSheetState, animated: Bool) {
        bottomSheetView.render(state: bottomSheetState, animated: animated)
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionView {
    /// Home button tap을 ViewController input으로 전달합니다.
    var homeTap: ControlEvent<Void> {
        base.homeButton.rx.tap
    }

    /// Bottom Sheet grabber drag 종료 action을 ViewController input으로 전달합니다.
    var bottomSheetDragEnded: Signal<SessionBottomSheetAction> {
        base.bottomSheetView.rx.dragEnded
    }
}
