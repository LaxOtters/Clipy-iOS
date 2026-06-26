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

/// Session WebView 위에 Top Bar와 Bottom Sheet를 겹쳐 배치하는 root view입니다.
final class SessionView: UIView {
    fileprivate let topBarView = SessionTopBarView()
    fileprivate let browserView = SessionWebView()
    fileprivate let bottomSheetView = SessionBottomSheetView()

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
        addSubview(browserView)
        addSubview(topBarView)
        addSubview(bottomSheetView)
    }

    private func configureStyle() {
        backgroundColor = .systemBackground
    }

    private func configureLayout() {
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        browserView.translatesAutoresizingMaskIntoConstraints = false
        bottomSheetView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            browserView.topAnchor.constraint(equalTo: topAnchor),
            browserView.leadingAnchor.constraint(equalTo: leadingAnchor),
            browserView.trailingAnchor.constraint(equalTo: trailingAnchor),
            browserView.bottomAnchor.constraint(equalTo: bottomAnchor),

            topBarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            topBarView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),

            bottomSheetView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            bottomSheetView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomSheetView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomSheetView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}

// MARK: - Interface

extension SessionView {
    /// 초기 URL load command를 WebView wrapper로 넘깁니다.
    func load(url: URL) {
        browserView.load(url: url)
    }

    /// Chrome state를 Top Bar와 Bottom Sheet에 나눠 렌더링합니다.
    func render(chromeState: SessionChromeState) {
        topBarView.render(state: chromeState.topBarState)
        bottomSheetView.render(state: chromeState.bottomSheetState, animated: true)
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionView {
    var homeTap: ControlEvent<Void> {
        base.topBarView.rx.homeTap
    }

    var topBarToggleTap: ControlEvent<Void> {
        base.topBarView.rx.toggleTap
    }

    /// Chrome 전환에 쓰는 WebView root scroll event입니다.
    var webRootScroll: Signal<SessionWebRootScrollEvent> {
        base.browserView.rx.rootScroll
    }

    /// Chrome 복원 판단에 쓰는 WebView navigation finish event입니다.
    var browserNavigationFinished: Signal<Void> {
        base.browserView.rx.navigationFinished
    }

    var bottomSheetDragEnded: Signal<SessionBottomSheetAction> {
        base.bottomSheetView.rx.dragEnded
    }
}
