//
//  SessionBottomSheetLayoutPolicy.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

import CoreGraphics

/// Bottom Sheet 상태별 노출 높이를 계산합니다.
struct SessionBottomSheetLayoutPolicy: Equatable {
    static let standard = SessionBottomSheetLayoutPolicy(
        hiddenVisibleHeight: 48,
        peekVisibleHeight: 160
    )

    let hiddenVisibleHeight: CGFloat
    let peekVisibleHeight: CGFloat

    func visibleHeight(
        for state: SessionBottomSheetState,
        availableHeight: CGFloat
    ) -> CGFloat {
        let availableHeight = max(0, availableHeight)

        switch state {
        case .hidden:
            return min(hiddenVisibleHeight, availableHeight)
        case .peek:
            return min(peekVisibleHeight, availableHeight)
        case .expanded:
            return availableHeight
        }
    }

    func offset(
        for state: SessionBottomSheetState,
        availableHeight: CGFloat
    ) -> CGFloat {
        let availableHeight = max(0, availableHeight)
        return availableHeight - visibleHeight(for: state, availableHeight: availableHeight)
    }
}
