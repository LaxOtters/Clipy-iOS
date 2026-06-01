//
//  SessionBottomSheetPolicy.swift
//  Clipy
//
//  Created by 박민서 on 6/1/26.
//

import CoreGraphics

/// 손을 뗀 순간의 위치와 속도를 Policy가 읽을 수 있게 정규화한 입력입니다.
struct SessionBottomSheetDragEndContext: Equatable {
    /// drag 시작점에서 손을 뗀 지점까지의 y축 이동량입니다.
    let translationY: CGFloat
    /// 손을 뗀 순간의 y축 속도입니다. 음수는 위로, 양수는 아래로 끄는 방향입니다.
    let velocityY: CGFloat
    /// 손을 뗀 위치를 sheet y축 offset 기준으로 바꾼 값입니다.
    let endOffset: CGFloat
    /// detent 계산에 사용할 현재 sheet container 높이입니다.
    let availableHeight: CGFloat
}

/// ViewModel이 Policy에 넘기는 Bottom Sheet 상태 변경 입력입니다.
enum SessionBottomSheetAction: Equatable {
    /// grabber drag가 끝났을 때의 위치와 속도 입력입니다.
    case dragEnded(SessionBottomSheetDragEndContext)
}

/// drag 속도, 종료 위치, detent 높이로 Bottom Sheet의 snap state와 content 노출을 정합니다.
struct SessionBottomSheetPolicy: Equatable {
    private static let expandedOffset: CGFloat = 0

    static let standard = SessionBottomSheetPolicy(
        detents: .standard,
        velocityThreshold: 3000,
        retentionBand: 20
    )

    /// Bottom Sheet가 각 state에서 화면에 남기는 높이 묶음입니다.
    struct Detents: Equatable {
        static let standard = Detents(
            minimizedVisibleHeight: 120,
            hiddenVisibleHeight: 0,
            peekVisibleHeight: 286
        )

        /// Minimized에서 grabber와 URL bar가 들어갈 최소 chrome 높이입니다.
        let minimizedVisibleHeight: CGFloat
        /// Hidden에서 WebView 집중을 위해 sheet를 완전히 내리는 높이입니다.
        let hiddenVisibleHeight: CGFloat
        /// Peek에서 기본 탐색 컨텐츠가 보이는 노출 높이입니다.
        let peekVisibleHeight: CGFloat
    }

    /// Expanded를 제외한 state별 sheet 높이입니다.
    let detents: Detents
    /// endpoint보다 방향 의도를 우선할 fast drag 속도 기준입니다.
    let velocityThreshold: CGFloat
    /// 현재 detent 주변에서 snap-back으로 볼 상하 허용 범위입니다.
    let retentionBand: CGFloat
    init(
        detents: Detents,
        velocityThreshold: CGFloat = 3000,
        retentionBand: CGFloat = 20
    ) {
        self.detents = detents
        self.velocityThreshold = velocityThreshold
        self.retentionBand = retentionBand
    }

    init(
        minimizedVisibleHeight: CGFloat,
        hiddenVisibleHeight: CGFloat,
        peekVisibleHeight: CGFloat,
        velocityThreshold: CGFloat = 3000,
        retentionBand: CGFloat = 20
    ) {
        self.init(
            detents: Detents(
                minimizedVisibleHeight: minimizedVisibleHeight,
                hiddenVisibleHeight: hiddenVisibleHeight,
                peekVisibleHeight: peekVisibleHeight
            ),
            velocityThreshold: velocityThreshold,
            retentionBand: retentionBand
        )
    }

    /// state가 화면 위에 남겨야 하는 실제 sheet 높이를 계산합니다.
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

    /// state에 snap하기 위해 적용할 y축 offset을 계산합니다.
    func offset(
        for state: SessionBottomSheetState,
        availableHeight: CGFloat
    ) -> CGFloat {
        let availableHeight = max(0, availableHeight)
        return availableHeight - visibleHeight(for: state, availableHeight: availableHeight)
    }

    /// drag action을 현재 state에서의 다음 snap state로 해석합니다.
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

    /// 느린 drag의 종료 높이와 방향으로 target state를 고릅니다.
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

    /// gesture 종료 offset을 snap zone 비교용 노출 높이로 바꿉니다.
    private func visibleHeight(
        forEndOffset endOffset: CGFloat,
        availableHeight: CGFloat
    ) -> CGFloat {
        let availableHeight = max(0, availableHeight)
        return min(max(availableHeight - endOffset, 0), availableHeight)
    }

    /// drag 중인 offset을 sheet가 움직일 수 있는 범위 안으로 보정합니다.
    func adjustedOffset(
        _ proposedOffset: CGFloat,
        availableHeight: CGFloat
    ) -> CGFloat {
        let hiddenOffset = offset(for: .hidden, availableHeight: availableHeight)
        return min(max(proposedOffset, Self.expandedOffset), hiddenOffset)
    }

    private enum DragDirection {
        case upward
        case downward
    }

    /// velocity가 threshold를 넘을 때만 endpoint보다 방향 의도를 우선합니다.
    private func fastDragDirection(velocityY: CGFloat) -> DragDirection? {
        guard abs(velocityY) >= velocityThreshold else {
            return nil
        }

        return velocityY < 0 ? .upward : .downward
    }

    /// fast drag는 인접 state 대신 방향에 맞는 대표 target으로 보냅니다.
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

    /// slow drag는 현재 detent의 보류 영역을 벗어난 뒤 endpoint가 속한 snap zone을 따릅니다.
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

    /// translation이 거의 없으면 종료 높이 변화로 drag 방향을 보완합니다.
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
