//
//  AppOverlayHosting.swift
//  Clipy
//
//  Created by 박민서 on 8/21/26.
//

import UIKit

import CoreDesignSystem

enum AppOverlayMountResult: Equatable {
    case displayed
    case unavailable
    case occupied
}

/// Dialog와 Snackbar view를 root overlay에 붙이고 떼는 host입니다.
/// Coordinator는 completion을 기준으로 다음 상태를 고릅니다.
@MainActor
protocol AppOverlayHosting: AnyObject {
    /// 새 overlay를 받을 수 있도록 host view가 window에 붙어 있는지 알려줍니다.
    var isOverlayHostAvailable: Bool { get }

    /// Dialog를 붙이고, 진입 결과와 이미 사용 중인 slot인지를 구분해 알려줍니다.
    func mountDialog(
        configuration: ClipyDialog.Configuration,
        onSelection: @escaping (ClipyDialog.Selection, String?) -> Void,
        completion: @escaping (AppOverlayMountResult) -> Void
    )
    /// Dialog를 떼고 실제 view 제거가 끝난 뒤 completion을 부릅니다.
    func unmountDialog(animated: Bool, completion: @escaping () -> Void)

    /// Snackbar를 붙이고, 진입 결과와 이미 사용 중인 slot인지를 구분해 알려줍니다.
    func mountSnackbar(
        message: String,
        actionTitle: String?,
        onAction: (() -> Void)?,
        onDismiss: @escaping () -> Void,
        completion: @escaping (AppOverlayMountResult) -> Void
    )
    /// Snackbar를 떼고 실제 view 제거가 끝난 뒤 completion을 부릅니다.
    func unmountSnackbar(animated: Bool, completion: @escaping () -> Void)
    /// Host view가 window에서 떨어졌을 때 알립니다. nil이면 더 이상 알리지 않습니다.
    func setHostDetachHandler(_ handler: (() -> Void)?)
}
