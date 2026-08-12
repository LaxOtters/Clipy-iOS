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

/// Session 화면의 Top Bar, WebView, Bottom Sheet를 한 UIKit tree로 묶습니다.
/// 사용자의 입력을 밖으로 열고, 내려온 chrome state는 그대로 화면에 그립니다.
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
    func load(url: URL) {
        browserView.load(url: url)
    }

    func goBack() {
        browserView.goBack()
    }

    func goForward() {
        browserView.goForward()
    }

    func reload() {
        browserView.reload()
    }

    /// 하나의 chrome state를 Top Bar와 Bottom Sheet에 같이 그립니다.
    func render(chromeState: SessionChromeState, animated: Bool) {
        topBarView.render(state: chromeState.topBarState)
        bottomSheetView.render(state: chromeState.bottomSheetState, animated: animated)
    }

    func render(browserState: SessionBrowserState) {
        bottomSheetView.render(browserState: browserState)
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

    var webRootScroll: Signal<SessionWebRootScrollInput> {
        base.browserView.rx.rootScroll
    }

    var navigationFinished: Signal<Void> {
        base.browserView.rx.navigationFinished
    }

    var browserState: Driver<SessionBrowserState> {
        base.browserView.rx.browserState
    }

    var backTap: ControlEvent<Void> {
        base.bottomSheetView.rx.backTap
    }

    var forwardTap: ControlEvent<Void> {
        base.bottomSheetView.rx.forwardTap
    }

    var reloadTap: ControlEvent<Void> {
        base.bottomSheetView.rx.reloadTap
    }

    var bottomSheetDragEnded: Signal<SessionBottomSheetAction> {
        base.bottomSheetView.rx.dragEnded
    }
}
