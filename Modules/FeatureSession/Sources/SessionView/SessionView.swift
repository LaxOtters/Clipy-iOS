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
    private let browserView = SessionWebView()
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

    /// 새 Session의 첫 화면에서 Top Bar가 어떤 모습으로 시작할지 반영합니다.
    func render(chromeState: SessionInitialChromeState) {
        topBarView.render(state: chromeState.topBarState)
    }

    /// Bottom Sheet ViewModel state를 내부 sheet component에 전달합니다.
    func render(bottomSheetState: SessionBottomSheetState, animated: Bool) {
        bottomSheetView.render(state: bottomSheetState, animated: animated)
    }
}

// MARK: - Reactive

extension Reactive where Base: SessionView {
    /// Top Bar의 Home tap을 화면 종료 input으로 엽니다.
    var homeTap: ControlEvent<Void> {
        base.topBarView.rx.homeTap
    }

    /// Bottom Sheet grabber drag 종료 action을 ViewModel input으로 엽니다.
    var bottomSheetDragEnded: Signal<SessionBottomSheetAction> {
        base.bottomSheetView.rx.dragEnded
    }
}
