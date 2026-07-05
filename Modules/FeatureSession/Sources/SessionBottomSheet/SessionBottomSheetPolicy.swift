//
//  SessionBottomSheetPolicy.swift
//  Clipy
//
//  Created by 박민서 on 6/1/26.
//

import CoreGraphics

/// Bottom Sheet에서 손을 뗀 순간을 detent 판단에 필요한 값으로 줄인 입력입니다.
struct SessionBottomSheetDragEndContext: Equatable {
    /// 시작점에서 손을 뗀 지점까지의 y축 이동량입니다.
    let translationY: CGFloat
    /// 손을 뗀 순간의 y축 속도입니다. 음수는 위로, 양수는 아래로 끄는 방향입니다.
    let velocityY: CGFloat
    /// 손을 뗀 위치를 sheet offset 기준으로 바꾼 값입니다.
    let endOffset: CGFloat
    /// 현재 sheet가 움직일 수 있는 container 높이입니다.
    let availableHeight: CGFloat
}

/// Bottom Sheet를 어디에 멈출지 판단할 때 쓰는 사용자 입력입니다.
enum SessionBottomSheetAction: Equatable {
    case dragEnded(SessionBottomSheetDragEndContext)
}

/// Bottom Sheet가 어디에 멈추고 content를 얼마나 보여줄지 계산합니다.
/// View는 손을 따라 움직이고, 최종 detent 판단은 여기로 모읍니다.
struct SessionBottomSheetPolicy: Equatable {
    private static let expandedOffset: CGFloat = 0

    static let standard = SessionBottomSheetPolicy(
        detents: .standard,
        velocityThreshold: 3000,
        retentionBand: 20
    )

    /// 각 상태가 화면 위에 남기는 기준 높이입니다.
    struct Detents: Equatable {
        static let standard = Detents(
            minimizedVisibleHeight: 120,
            hiddenVisibleHeight: 0,
            peekVisibleHeight: 286
        )

        /// Minimized에서 grabber와 URL bar가 들어갈 최소 chrome 높이입니다.
        let minimizedVisibleHeight: CGFloat
        /// Hidden에서 sheet를 화면 아래로 내리는 높이입니다.
        let hiddenVisibleHeight: CGFloat
        /// Peek에서 URL bar와 item preview가 같이 보이는 높이입니다.
        let peekVisibleHeight: CGFloat
    }

    /// Peek와 Expanded content가 겹치는 구간에서 어느 쪽을 얼마나 보여줄지 나타냅니다.
    struct ContentAlpha: Equatable {
        let peek: CGFloat
        let expanded: CGFloat
    }

    let detents: Detents
    let velocityThreshold: CGFloat
    let retentionBand: CGFloat
    var isContentFadeEnabled: Bool

    init(
        detents: Detents,
        velocityThreshold: CGFloat = 3000,
        retentionBand: CGFloat = 20,
        isContentFadeEnabled: Bool = true
    ) {
        self.detents = detents
        self.velocityThreshold = velocityThreshold
        self.retentionBand = retentionBand
        self.isContentFadeEnabled = isContentFadeEnabled
    }

    init(
        minimizedVisibleHeight: CGFloat,
        hiddenVisibleHeight: CGFloat,
        peekVisibleHeight: CGFloat,
        velocityThreshold: CGFloat = 3000,
        retentionBand: CGFloat = 20,
        isContentFadeEnabled: Bool = true
    ) {
        self.init(
            detents: Detents(
                minimizedVisibleHeight: minimizedVisibleHeight,
                hiddenVisibleHeight: hiddenVisibleHeight,
                peekVisibleHeight: peekVisibleHeight
            ),
            velocityThreshold: velocityThreshold,
            retentionBand: retentionBand,
            isContentFadeEnabled: isContentFadeEnabled
        )
    }

    /// 주어진 상태에서 화면 위에 남길 sheet 높이를 계산합니다.
    func visibleHeight(
        for state: SessionBottomSheetState,
        availableHeight: CGFloat
    ) -> CGFloat {
        let availableHeight = max(0, availableHeight)

        switch state {
        case .hidden:
            return min(detents.hiddenVisibleHeight, availableHeight)
        case .minimized:
            return min(detents.minimizedVisibleHeight, availableHeight)
        case .peek:
            return min(detents.peekVisibleHeight, availableHeight)
        case .expanded:
            return availableHeight
        }
    }

    /// 주어진 상태로 snap하기 위해 sheet를 아래로 내릴 거리를 계산합니다.
    func offset(
        for state: SessionBottomSheetState,
        availableHeight: CGFloat
    ) -> CGFloat {
        let availableHeight = max(0, availableHeight)
        return availableHeight - visibleHeight(for: state, availableHeight: availableHeight)
    }

    /// 사용자가 놓은 방향과 위치를 다음 Bottom Sheet 상태로 해석합니다.
    func nextState(
        from state: SessionBottomSheetState,
        action: SessionBottomSheetAction
    ) -> SessionBottomSheetState {
        switch action {
        case .dragEnded(let context):
            guard state != .hidden else {
                return .hidden
            }

            if let direction = fastDragDirection(velocityY: context.velocityY) {
                return fastTargetState(from: state, direction: direction)
            }

            return targetState(
                from: state,
                context: context
            )
        }
    }

    /// 빠른 flick가 아닐 때는 끝난 높이와 방향을 같이 보고 target을 고릅니다.
    private func targetState(
        from state: SessionBottomSheetState,
        context: SessionBottomSheetDragEndContext
    ) -> SessionBottomSheetState {
        guard state != .hidden else {
            return .hidden
        }

        let availableHeight = max(0, context.availableHeight)
        let visibleHeight = visibleHeight(
            forEndOffset: context.endOffset,
            availableHeight: context.availableHeight
        )
        let currentHeight = self.visibleHeight(for: state, availableHeight: availableHeight)

        guard let direction = dragDirection(
            translationY: context.translationY,
            currentVisibleHeight: currentHeight,
            endVisibleHeight: visibleHeight
        ) else {
            return state
        }

        return slowTargetState(
            from: state,
            direction: direction,
            endVisibleHeight: visibleHeight,
            availableHeight: availableHeight
        )
    }

    private func visibleHeight(
        forEndOffset endOffset: CGFloat,
        availableHeight: CGFloat
    ) -> CGFloat {
        let availableHeight = max(0, availableHeight)
        return min(max(availableHeight - endOffset, 0), availableHeight)
    }

    /// 손을 따라 움직이는 동안에도 sheet가 화면 밖으로 과하게 나가지 않게 잡아줍니다.
    func adjustedOffset(
        _ proposedOffset: CGFloat,
        availableHeight: CGFloat
    ) -> CGFloat {
        let hiddenOffset = offset(for: .hidden, availableHeight: availableHeight)
        return min(max(proposedOffset, Self.expandedOffset), hiddenOffset)
    }

    /// Peek에서 Expanded로 넘어가는 동안 두 content가 어색하게 겹치지 않게 alpha를 나눕니다.
    func contentAlpha(
        offset: CGFloat,
        availableHeight: CGFloat
    ) -> ContentAlpha {
        let endVisibleHeight = visibleHeight(
            forEndOffset: offset,
            availableHeight: availableHeight
        )
        let peekHeight = visibleHeight(for: .peek, availableHeight: availableHeight)
        let expandedHeight = visibleHeight(for: .expanded, availableHeight: availableHeight)

        guard isContentFadeEnabled else {
            if endVisibleHeight >= expandedHeight {
                return ContentAlpha(peek: 0, expanded: 1)
            }

            if endVisibleHeight >= peekHeight {
                return ContentAlpha(peek: 1, expanded: 0)
            }

            return ContentAlpha(peek: 0, expanded: 0)
        }

        guard endVisibleHeight >= peekHeight else {
            return ContentAlpha(peek: 0, expanded: 0)
        }

        let travelDistance = max(1, expandedHeight - peekHeight)
        let expandedProgress = min(max((endVisibleHeight - peekHeight) / travelDistance, 0), 1)
        return ContentAlpha(
            peek: 1 - expandedProgress,
            expanded: expandedProgress
        )
    }

    /// browser control row는 웹을 함께 보는 높이에서만 노출합니다.
    func isBrowserControlRowVisible(for state: SessionBottomSheetState) -> Bool {
        switch state {
        case .hidden:
            return false
        case .minimized, .peek:
            return true
        case .expanded:
            return false
        }
    }

    private enum DragDirection {
        case upward
        case downward
    }

    /// 충분히 빠른 flick만 위치보다 방향 의도가 강한 입력으로 봅니다.
    private func fastDragDirection(velocityY: CGFloat) -> DragDirection? {
        guard abs(velocityY) >= velocityThreshold else {
            return nil
        }

        return velocityY < 0 ? .upward : .downward
    }

    /// 빠른 flick는 중간 detent에 걸치지 않고 방향에 맞는 대표 상태로 보냅니다.
    private func fastTargetState(
        from state: SessionBottomSheetState,
        direction: DragDirection
    ) -> SessionBottomSheetState {
        switch (state, direction) {
        case (.hidden, _):
            return .hidden
        case (.minimized, .upward), (.peek, .upward):
            return .expanded
        case (.expanded, .upward):
            return .expanded
        case (.expanded, .downward), (.peek, .downward):
            return .minimized
        case (.minimized, .downward):
            return .hidden
        }
    }

    /// 느린 drag는 현재 detent 주변을 벗어난 뒤 끝난 위치가 속한 구간을 따릅니다.
    private func slowTargetState(
        from state: SessionBottomSheetState,
        direction: DragDirection,
        endVisibleHeight: CGFloat,
        availableHeight: CGFloat
    ) -> SessionBottomSheetState {
        let band = max(0, retentionBand)
        let currentHeight = visibleHeight(for: state, availableHeight: availableHeight)
        let expandedHeight = visibleHeight(for: .expanded, availableHeight: availableHeight)
        let minimizedHeight = visibleHeight(for: .minimized, availableHeight: availableHeight)

        switch (state, direction) {
        case (.hidden, _):
            return .hidden
        case (.expanded, .upward):
            return .expanded
        case (.expanded, .downward):
            guard endVisibleHeight < currentHeight - band else {
                return .expanded
            }

            if endVisibleHeight <= minimizedHeight + band {
                return .minimized
            }

            return .peek
        case (.peek, .upward):
            guard endVisibleHeight > currentHeight + band else {
                return .peek
            }

            return .expanded
        case (.peek, .downward):
            guard endVisibleHeight < currentHeight - band else {
                return .peek
            }

            return .minimized
        case (.minimized, .upward):
            guard endVisibleHeight > currentHeight + band else {
                return .minimized
            }

            if endVisibleHeight >= expandedHeight - band {
                return .expanded
            }

            return .peek
        case (.minimized, .downward):
            guard endVisibleHeight < currentHeight - band else {
                return .minimized
            }

            return .hidden
        }
    }

    /// 움직임이 거의 없는 gesture는 시작/종료 높이 차이로 방향을 보완합니다.
    private func dragDirection(
        translationY: CGFloat,
        currentVisibleHeight: CGFloat,
        endVisibleHeight: CGFloat
    ) -> DragDirection? {
        if translationY < 0 {
            return .upward
        }

        if translationY > 0 {
            return .downward
        }

        if endVisibleHeight > currentVisibleHeight {
            return .upward
        }

        if endVisibleHeight < currentVisibleHeight {
            return .downward
        }

        return nil
    }
}
