//
//  ClipyDialog.swift
//  Clipy
//
//  Created by 박민서 on 8/20/26.
//

import Foundation

/// Dialog를 요청하고 응답을 받을 때 쓰는 public 타입을 묶습니다.
public enum ClipyDialog {
    /// 수락된 Dialog 요청을 나중에 같은 coordinator에 전달해 취소할 때 쓰는 식별자입니다.
    public struct RequestID: Hashable {
        private let rawValue: UUID

        public init() {
            rawValue = UUID()
        }
    }

    public enum SemanticIcon: Equatable {
        case error
    }

    /// 제목과 본문 앞에 어떤 맥락을 보여줄지 정합니다.
    public enum Presentation: Equatable {
        case plain
        case semanticIcon(SemanticIcon)
        case websiteRequest(sourceText: String)
    }

    /// Dialog에 놓을 버튼 수와 title을 정합니다.
    /// dual은 secondary를 왼쪽, primary를 오른쪽에 둡니다.
    public enum ButtonConfiguration: Equatable {
        case single(title: String)
        case dual(primaryTitle: String, secondaryTitle: String)
    }

    /// Dialog에 필요한 문구, 표현 방식, 버튼 구성을 한 번에 담습니다.
    public enum Configuration: Equatable {
        case message(
            presentation: Presentation,
            title: String,
            body: String,
            buttons: ButtonConfiguration
        )
        case prompt(
            presentation: Presentation,
            title: String,
            body: String,
            initialText: String,
            placeholder: String?,
            primaryTitle: String,
            secondaryTitle: String
        )
    }

    /// 사용자가 고른 버튼의 위치입니다.
    /// 버튼마다 callback을 두지 않고 response 하나로 돌려줄 때 씁니다.
    public enum Selection: Equatable {
        case single
        case primary
        case secondary
    }

    /// 수락된 Dialog가 사용자 선택 없이 끝난 이유입니다.
    public enum CancellationReason: Equatable {
        case sceneInactive
        case hostUnavailable
        case displayFailed
        case sceneDisconnected
        case requestCancelled
    }

    /// 수락된 Dialog가 선택이나 cancellation으로 끝났을 때 한 번만 전달됩니다.
    public enum Response: Equatable {
        /// 사용자가 버튼을 눌렀습니다. message Dialog의 `promptText`는 nil입니다.
        case selected(button: Selection, promptText: String?)
        /// 사용자가 고르기 전에 Dialog가 더 이상 표시될 수 없게 됐습니다.
        case cancelled(CancellationReason)
    }

    /// Dialog 요청을 받지 않은 이유입니다. 거절한 요청의 callback은 저장하지 않습니다.
    public enum RequestRejection: Equatable {
        /// 기존 Dialog가 보이거나 내려가는 중입니다.
        case dialogAlreadyPresented
        case sceneInactive
        case hostUnavailable
    }

    /// Dialog 요청을 지금 맡았는지 바로 알려줍니다.
    /// `accepted` 뒤 실제 종료 결과는 response callback으로 옵니다.
    public enum RequestResult: Equatable {
        case accepted(RequestID)
        case rejected(RequestRejection)
    }
}
