//
//  SessionBottomSheetRenderingPolicy.swift
//  Clipy
//
//  Created by 박민서 on 5/21/26.
//

import CoreGraphics

/// Bottom Sheet 상태를 화면 수치와 content 표시 값으로 바꿉니다.
struct SessionBottomSheetRenderingPolicy: Equatable {
    /// Expanded 상태에서 적용하는 y축 offset입니다.
    private static let expandedOffset: CGFloat = 0

    /// 현재 디자인 기준에서 사용하는 기본 상태별 노출 높이입니다.
    static let standard = SessionBottomSheetRenderingPolicy(
        minimizedVisibleHeight: 60,
        hiddenVisibleHeight: 120,
        peekVisibleHeight: 286
    )

    /// Minimized 상태에서 화면 아래에 남기는 최소 chrome 높이입니다.
    let minimizedVisibleHeight: CGFloat
    /// Hidden 상태에서 URL bar 영역까지 보이도록 남기는 높이입니다.
    let hiddenVisibleHeight: CGFloat
    /// Peek 상태에서 item 가로 스크롤 영역까지 보이도록 남기는 높이입니다.
    let peekVisibleHeight: CGFloat

    /// 주어진 상태가 실제 화면에서 차지해야 하는 노출 높이를 반환합니다.
    func visibleHeight(
        for state: SessionBottomSheetState,
        availableHeight: CGFloat
    ) -> CGFloat {
        let availableHeight = max(0, availableHeight)

        switch state {
        case .minimized:
            return min(minimizedVisibleHeight, availableHeight)
        case .hidden:
            return min(hiddenVisibleHeight, availableHeight)
        case .peek:
            return min(peekVisibleHeight, availableHeight)
        case .expanded:
            return availableHeight
        }
    }

    /// Bottom Sheet를 해당 상태로 보이게 하기 위한 y축 offset을 반환합니다.
    func offset(
        for state: SessionBottomSheetState,
        availableHeight: CGFloat
    ) -> CGFloat {
        let availableHeight = max(0, availableHeight)
        return availableHeight - visibleHeight(for: state, availableHeight: availableHeight)
    }

    /// Drag 중 계산된 y축 offset을 화면에서 허용하는 범위 안으로 보정합니다.
    func clampedOffset(
        _ proposedOffset: CGFloat,
        availableHeight: CGFloat
    ) -> CGFloat {
        let minimizedOffset = offset(for: .minimized, availableHeight: availableHeight)
        return min(max(proposedOffset, Self.expandedOffset), minimizedOffset)
    }

    /// 현재 상태와 offset에서 Bottom Sheet content가 드러날 alpha를 계산합니다.
    func contentAlpha(
        for state: SessionBottomSheetState,
        offset: CGFloat,
        availableHeight: CGFloat
    ) -> CGFloat {
        switch state {
        case .minimized, .hidden, .peek, .expanded:
            let hiddenOffset = self.offset(for: .hidden, availableHeight: availableHeight)
            let peekOffset = self.offset(for: .peek, availableHeight: availableHeight)
            let travelDistance = max(1, hiddenOffset - peekOffset)
            let visibleProgress = (hiddenOffset - offset) / travelDistance
            return min(max(visibleProgress, 0), 1)
        }
    }
}
