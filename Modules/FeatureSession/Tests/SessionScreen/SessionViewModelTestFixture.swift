//
//  SessionViewModelTestFixture.swift
//  Clipy
//
//  Created by 박민서 on 7/5/26.
//

import Foundation

import RxCocoa

@testable import FeatureSession

enum SessionViewModelTestFixture {
    static func makeOutput(
        context: SessionLaunchContext = SessionLaunchContext(sessionId: UUID()),
        viewDidLoad: Signal<Void> = Signal.empty(),
        homeTap: Signal<Void> = Signal.empty(),
        topBarToggleTap: Signal<Void> = Signal.empty(),
        webRootScroll: Signal<SessionWebRootScrollInput> = Signal.empty(),
        browserNavigationFinished: Signal<Void> = Signal.empty(),
        bottomSheetDragEnded: Signal<SessionBottomSheetAction> = Signal.empty()
    ) -> SessionViewModel.Output {
        let viewModel = SessionViewModel(context: context)
        return viewModel.transform(
            input: SessionViewModel.Input(
                viewDidLoad: viewDidLoad,
                homeTap: homeTap,
                topBarToggleTap: topBarToggleTap,
                webRootScroll: webRootScroll,
                browserNavigationFinished: browserNavigationFinished,
                bottomSheetDragEnded: bottomSheetDragEnded
            )
        )
    }

    static func snapshot(
        offsetY: CGFloat,
        contentHeight: CGFloat = 1_200,
        viewportHeight: CGFloat = 800,
        adjustedContentInsetTop: CGFloat = 0,
        adjustedContentInsetBottom: CGFloat = 0
    ) -> SessionWebRootScrollSnapshot {
        SessionWebRootScrollSnapshot(
            offsetY: offsetY,
            contentHeight: contentHeight,
            viewportHeight: viewportHeight,
            adjustedContentInsetTop: adjustedContentInsetTop,
            adjustedContentInsetBottom: adjustedContentInsetBottom
        )
    }

    static func dragEnded(
        endVisibleHeight: CGFloat,
        translationY: CGFloat,
        velocityY: CGFloat = 0,
        availableHeight: CGFloat = 760
    ) -> SessionBottomSheetAction {
        .dragEnded(
            SessionBottomSheetDragEndContext(
                translationY: translationY,
                velocityY: velocityY,
                endOffset: availableHeight - endVisibleHeight,
                availableHeight: availableHeight
            )
        )
    }
}
