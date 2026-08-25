//
//  ClipySnackbar.swift
//  Clipy
//
//  Created by 박민서 on 8/20/26.
//

import Foundation

/// Snackbar를 요청하고 queue 결과를 확인할 때 쓰는 public 타입을 묶습니다.
public enum ClipySnackbar {
    /// Snackbar 버튼의 title과 탭했을 때 실행할 action입니다.
    public struct Action {
        public let title: String
        public let handler: @MainActor () -> Void

        public init(title: String, handler: @escaping @MainActor () -> Void) {
            self.title = title
            self.handler = handler
        }
    }

    /// Snackbar 하나에 표시할 문구와 선택 action입니다.
    public struct Request {
        public let message: String
        public let action: Action?

        public init(message: String, action: Action? = nil) {
            self.message = message
            self.action = action
        }
    }

    /// scene이나 host 상태 때문에 overlay 요청을 받을 수 없는 이유입니다.
    public enum UnavailableReason: Equatable {
        case sceneInactive
        case hostUnavailable
    }

    /// Snackbar 요청을 queue에 넣었는지 바로 알려줍니다.
    public enum EnqueueResult: Equatable {
        /// 바로 표시하거나 FIFO에 저장했습니다.
        case accepted
        /// 같은 message와 action title이 이미 표시 중이거나 기다리고 있습니다.
        case duplicateDropped
        /// 현재 scene이나 host에서는 표시할 수 없습니다.
        case unavailable(UnavailableReason)
    }
}
