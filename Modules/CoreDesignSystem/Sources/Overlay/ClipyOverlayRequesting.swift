//
//  ClipyOverlayRequesting.swift
//  Clipy
//
//  Created by 박민서 on 8/21/26.
//

import Foundation

/// Feature가 앱 공용 Dialog와 Snackbar를 요청할 때 쓰는 진입점입니다.
/// 표시 위치와 scene lifecycle은 caller가 직접 다루지 않습니다.
@MainActor
public protocol ClipyOverlayRequesting: AnyObject {
    /// Dialog는 한 번에 하나만 올리며, 거절한 요청의 response는 저장하지 않습니다.
    @discardableResult
    func presentDialog(
        _ configuration: ClipyDialog.Configuration,
        response: @escaping @MainActor (ClipyDialog.Response) -> Void
    ) -> ClipyDialog.RequestResult

    /// Snackbar는 scene 안에서 FIFO로 보여줍니다.
    /// message와 action title이 UTF-8 byte 단위로 같으면 중복으로 보고, 거절한 요청의 action은 저장하지 않습니다.
    @discardableResult
    func enqueueSnackbar(_ request: ClipySnackbar.Request) -> ClipySnackbar.EnqueueResult
}
