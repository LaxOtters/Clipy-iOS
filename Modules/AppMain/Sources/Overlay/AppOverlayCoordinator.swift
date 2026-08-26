//
//  AppOverlayCoordinator.swift
//  Clipy
//
//  Created by 박민서 on 8/21/26.
//

import Foundation

import CoreDesignSystem

/// 한 scene의 Dialog, Snackbar 순서와 scene/host 종료를 함께 관리합니다.
@MainActor
final class AppOverlayCoordinator: ClipyOverlayRequesting {
    private static let snackbarDuration: TimeInterval = 2
    private weak var host: AppOverlayHosting?
    private let scheduler: AppOverlayScheduling
    private var isSceneActive: Bool
    private var isShutdown = false
    private var dialog: DialogState?
    private var visibleSnackbar: SnackbarState?
    private var snackbarQueue: [QueuedSnackbar] = []
    private var snackbarFingerprints: Set<SnackbarFingerprint> = []
    private var isInvokingSnackbarAction = false

    convenience init(host: AppOverlayHosting, isSceneActive: Bool) {
        self.init(host: host, isSceneActive: isSceneActive, scheduler: AppOverlayScheduler())
    }

    init(
        host: AppOverlayHosting,
        isSceneActive: Bool,
        scheduler: AppOverlayScheduling
    ) {
        self.host = host
        self.isSceneActive = isSceneActive
        self.scheduler = scheduler
    }

    @discardableResult
    func presentDialog(
        _ configuration: ClipyDialog.Configuration,
        response: @escaping @MainActor (ClipyDialog.Response) -> Void
    ) -> ClipyDialog.RequestResult {
        // Dialog가 내려가는 중에도 아직 자리를 비운 게 아니므로, scene/host보다 중복 요청을 먼저 봅니다.
        guard dialog == nil else { return .rejected(.dialogAlreadyPresented) }
        guard isSceneActive else { return .rejected(.sceneInactive) }
        guard !isShutdown, let host, host.isOverlayHostAvailable else { return .rejected(.hostUnavailable) }
        let requestID = ClipyDialog.RequestID()
        dialog = DialogState(requestID: requestID, response: response, ownsHostedView: false, phase: .entering)
        let admission = host.mountDialog(
            configuration: configuration,
            onSelection: { [weak self] selection, promptText in
                self?.beginDialogDismissal(
                    requestID: requestID,
                    response: .selected(button: selection, promptText: promptText),
                    animated: true
                )
            },
            completion: { [weak self] result in
                self?.completeDialogEntry(requestID: requestID, result: result)
            }
        )
        guard admission == .accepted else {
            dialog = nil
            let rejection: ClipyDialog.RequestRejection = admission == .occupied ? .dialogAlreadyPresented : .hostUnavailable
            return .rejected(rejection)
        }
        dialog?.ownsHostedView = true
        return .accepted(requestID)
    }

    func cancelDialog(_ requestID: ClipyDialog.RequestID) {
        guard dialog?.requestID == requestID else { return }
        beginDialogDismissal(requestID: requestID, response: .cancelled(.requestCancelled), animated: false)
    }

    @discardableResult
    func enqueueSnackbar(_ request: ClipySnackbar.Request) -> ClipySnackbar.EnqueueResult {
        guard isSceneActive else { return .unavailable(.sceneInactive) }
        guard !isShutdown, let host, host.isOverlayHostAvailable else { return .unavailable(.hostUnavailable) }
        let fingerprint = SnackbarFingerprint(
            message: request.message,
            actionTitle: request.action?.title
        )
        guard snackbarFingerprints.insert(fingerprint).inserted else {
            return .duplicateDropped
        }
        snackbarQueue.append(QueuedSnackbar(request: request, fingerprint: fingerprint))
        if let admission = showNextSnackbarIfNeeded(), admission != .accepted {
            return .unavailable(.hostUnavailable)
        }
        return .accepted
    }

    func sceneDidBecomeActive() {
        guard !isShutdown else { return }
        isSceneActive = true
        showNextSnackbarIfNeeded()
    }

    func sceneWillResignActive() {
        isSceneActive = false
        cancelDialog(reason: .sceneInactive, removalHost: host)
        clearSnackbars(removalHost: host)
    }

    func hostDidDetach() {
        guard !isShutdown else { return }
        let detachedHost = host
        detachedHost?.setHostDetachHandler(nil)
        host = nil
        cancelDialog(reason: .hostUnavailable, removalHost: detachedHost)
        clearSnackbars(removalHost: detachedHost)
    }

    func shutdown() {
        guard !isShutdown else { return }
        isShutdown = true
        isSceneActive = false
        let disconnectedHost = host
        disconnectedHost?.setHostDetachHandler(nil)
        host = nil
        cancelDialog(reason: .sceneDisconnected, removalHost: disconnectedHost)
        clearSnackbars(removalHost: disconnectedHost)
    }
}

private extension AppOverlayCoordinator {
    enum DialogPhase {
        case entering, visible
        case exiting(ClipyDialog.Response)
    }
    struct DialogState {
        let requestID: ClipyDialog.RequestID
        let response: @MainActor (ClipyDialog.Response) -> Void
        var ownsHostedView: Bool
        var phase: DialogPhase
    }
    struct SnackbarFingerprint: Hashable {
        let message: [UInt8]
        let actionTitle: [UInt8]?

        init(message: String, actionTitle: String?) {
            self.message = Array(message.utf8)
            self.actionTitle = actionTitle.map { Array($0.utf8) }
        }
    }

    struct QueuedSnackbar {
        let request: ClipySnackbar.Request
        let fingerprint: SnackbarFingerprint
    }

    enum SnackbarCompletion {
        case dismissed
        case action(@MainActor () -> Void)
    }

    enum SnackbarDismissal {
        case dismiss, action
    }

    enum SnackbarPhase {
        case entering, visible
        case exiting(SnackbarCompletion)
    }

    struct SnackbarState {
        let token: UUID
        let fingerprint: SnackbarFingerprint
        var action: (@MainActor () -> Void)?
        var scheduledTask: AppOverlayScheduledTask?
        var phase: SnackbarPhase
    }

    func completeDialogEntry(requestID: ClipyDialog.RequestID, result: AppOverlayMountResult) {
        guard let current = dialog, current.requestID == requestID, case .entering = current.phase else { return }
        switch result {
        case .displayed:
            dialog?.phase = .visible
        case .unavailable:
            failDialogEntry(requestID: requestID)
        }
    }
    func failDialogEntry(requestID: ClipyDialog.RequestID) {
        guard let current = dialog, current.requestID == requestID, case .entering = current.phase else { return }
        dialog?.ownsHostedView = true
        dialog?.phase = .exiting(.cancelled(.displayFailed))
        let removalHost = host
        // 동기 표시 실패에서도 .accepted를 먼저 반환한 뒤 response를 전달합니다.
        DispatchQueue.main.async { [self] in
            guard let current = dialog, current.requestID == requestID, case .exiting = current.phase else {
                return
            }
            requestDialogRemoval(requestID: requestID, animated: false, removalHost: removalHost)
        }
    }
    func cancelDialog(reason: ClipyDialog.CancellationReason, removalHost: AppOverlayHosting?) {
        guard let current = dialog else {
            return
        }
        switch current.phase {
        case .entering, .visible:
            beginDialogDismissal(
                requestID: current.requestID,
                response: .cancelled(reason),
                animated: false,
                removalHost: removalHost
            )
        case .exiting:
            // 사용자가 이미 고른 결과는 뒤늦게 들어온 scene/host 종료로 덮지 않습니다.
            guard current.ownsHostedView, let removalHost else { return }
            requestDialogRemoval(requestID: current.requestID, animated: false, removalHost: removalHost)
        }
    }

    func beginDialogDismissal(
        requestID: ClipyDialog.RequestID,
        response: ClipyDialog.Response,
        animated: Bool,
        removalHost: AppOverlayHosting? = nil
    ) {
        guard let current = dialog, current.requestID == requestID else {
            return
        }
        switch current.phase {
        case .entering, .visible:
            dialog?.phase = .exiting(response)
            requestDialogRemoval(
                requestID: requestID,
                animated: animated,
                removalHost: removalHost ?? host
            )
        case .exiting:
            return
        }
    }

    func requestDialogRemoval(
        requestID: ClipyDialog.RequestID,
        animated: Bool,
        removalHost: AppOverlayHosting?
    ) {
        guard let removalHost else {
            completeDialogRemoval(requestID: requestID)
            return
        }
        removalHost.unmountDialog(animated: animated) { [self] in
            completeDialogRemoval(requestID: requestID)
        }
    }
    func completeDialogRemoval(requestID: ClipyDialog.RequestID) {
        guard let current = dialog, current.requestID == requestID, case let .exiting(response) = current.phase else {
            return
        }
        // response 안에서 새 Dialog를 바로 띄울 수 있게, callback 전에 자리를 먼저 비웁니다.
        dialog = nil
        current.response(response)
    }

    @discardableResult
    func showNextSnackbarIfNeeded() -> AppOverlayMountAdmission? {
        guard
            !isInvokingSnackbarAction,
            isSceneActive,
            !isShutdown,
            visibleSnackbar == nil,
            !snackbarQueue.isEmpty,
            let host,
            host.isOverlayHostAvailable
        else {
            return nil
        }
        let pending = snackbarQueue.removeFirst()
        let token = UUID()
        visibleSnackbar = SnackbarState(
            token: token,
            fingerprint: pending.fingerprint,
            action: pending.request.action?.handler,
            scheduledTask: nil,
            phase: .entering
        )
        let admission = host.mountSnackbar(
            message: pending.request.message,
            actionTitle: pending.request.action?.title,
            onAction: pending.request.action == nil ? nil : { [weak self] in
                self?.beginSnackbarDismissal(token: token, dismissal: .action)
            },
            onDismiss: { [weak self] in
                self?.beginSnackbarDismissal(token: token, dismissal: .dismiss)
            },
            completion: { [weak self] result in
                self?.completeSnackbarEntry(token: token, result: result)
            }
        )
        switch admission {
        case .accepted:
            return .accepted
        case .unavailable, .occupied:
            clearSnackbars(removalHost: nil)
            return admission
        }
    }

    func completeSnackbarEntry(token: UUID, result: AppOverlayMountResult) {
        guard let current = visibleSnackbar, current.token == token, case .entering = current.phase else {
            return
        }
        switch result {
        case .displayed:
            visibleSnackbar?.phase = .visible
            visibleSnackbar?.scheduledTask = scheduler.schedule(after: Self.snackbarDuration) { [weak self] in
                self?.beginSnackbarDismissal(token: token, dismissal: .dismiss)
            }
        case .unavailable:
            clearSnackbars(removalHost: host)
        }
    }

    func beginSnackbarDismissal(token: UUID, dismissal: SnackbarDismissal) {
        guard let current = visibleSnackbar, current.token == token else {
            return
        }
        switch current.phase {
        case .entering, .visible:
            current.scheduledTask?.cancel()
            let completion: SnackbarCompletion
            switch dismissal {
            case .dismiss:
                completion = .dismissed
                visibleSnackbar?.action = nil
            case .action:
                guard let action = current.action else {
                    return
                }
                completion = .action(action)
                visibleSnackbar?.action = nil
            }
            visibleSnackbar?.phase = .exiting(completion)
            requestSnackbarRemoval(token: token, animated: true, removalHost: host)
        case .exiting:
            return
        }
    }

    func clearSnackbars(removalHost: AppOverlayHosting?) {
        visibleSnackbar?.scheduledTask?.cancel()
        snackbarQueue.removeAll()
        guard let current = visibleSnackbar else {
            snackbarFingerprints.removeAll()
            return
        }
        snackbarFingerprints = [current.fingerprint]
        let wasExiting: Bool
        switch current.phase {
        case .entering, .visible:
            wasExiting = false
            // 아직 누르지 않은 action은 scene 정리와 함께 버립니다.
            visibleSnackbar?.phase = .exiting(.dismissed)
        case .exiting:
            wasExiting = true
        }
        visibleSnackbar?.action = nil
        // host가 사라진 뒤 들어온 lifecycle event는 이미 요청한 removal completion을 기다립니다.
        guard removalHost != nil || !wasExiting else {
            return
        }
        requestSnackbarRemoval(token: current.token, animated: false, removalHost: removalHost)
    }

    func requestSnackbarRemoval(
        token: UUID,
        animated: Bool,
        removalHost: AppOverlayHosting?
    ) {
        guard let removalHost else {
            completeSnackbarRemoval(token: token)
            return
        }
        removalHost.unmountSnackbar(animated: animated) { [self] in
            completeSnackbarRemoval(token: token)
        }
    }

    func completeSnackbarRemoval(token: UUID) {
        guard let current = visibleSnackbar, current.token == token, case let .exiting(completion) = current.phase else {
            return
        }
        snackbarFingerprints.remove(current.fingerprint)
        visibleSnackbar = nil
        if case let .action(action) = completion {
            // 먼저 view를 내린 뒤 action을 실행해야 callback 안의 enqueue가 기존 Snackbar와 엉키지 않습니다.
            isInvokingSnackbarAction = true
            action()
            isInvokingSnackbarAction = false
        }
        showNextSnackbarIfNeeded()
    }
}
