//
//  AppOverlayCoordinator.swift
//  Clipy
//
//  Created by 박민서 on 8/21/26.
//

import Foundation

import CoreDesignSystem

/// 한 scene에서 Dialog는 하나만, Snackbar는 들어온 순서대로 보여줍니다.
/// scene이나 host 상태가 바뀌면 진행 중인 overlay를 여기서 정리합니다.
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
        guard dialog == nil else {
            return .rejected(.dialogAlreadyPresented)
        }
        guard isSceneActive else {
            return .rejected(.sceneInactive)
        }
        guard !isShutdown, let host, host.isOverlayHostAvailable else {
            return .rejected(.hostUnavailable)
        }
        let token = UUID()
        dialog = DialogState(token: token, response: response, phase: .entering)
        host.mountDialog(
            configuration: configuration,
            onSelection: { [weak self] selection, promptText in
                self?.beginDialogDismissal(
                    token: token,
                    response: .selected(button: selection, promptText: promptText),
                    animated: true
                )
            },
            completion: { [weak self] result in
                self?.completeDialogEntry(token: token, result: result)
            }
        )
        return .accepted
    }

    @discardableResult
    func enqueueSnackbar(_ request: ClipySnackbar.Request) -> ClipySnackbar.EnqueueResult {
        guard isSceneActive else {
            return .unavailable(.sceneInactive)
        }
        guard !isShutdown, let host, host.isOverlayHostAvailable else {
            return .unavailable(.hostUnavailable)
        }
        let fingerprint = SnackbarFingerprint(
            message: request.message,
            actionTitle: request.action?.title
        )
        guard snackbarFingerprints.insert(fingerprint).inserted else {
            return .duplicateDropped
        }
        snackbarQueue.append(QueuedSnackbar(request: request, fingerprint: fingerprint))
        showNextSnackbarIfNeeded()
        return .accepted
    }

    func sceneDidBecomeActive() {
        guard !isShutdown else {
            return
        }
        isSceneActive = true
        showNextSnackbarIfNeeded()
    }

    func sceneWillResignActive() {
        isSceneActive = false
        cancelDialog(reason: .sceneInactive, removalHost: host)
        clearSnackbars(removalHost: host)
    }

    func hostDidDetach() {
        guard !isShutdown else {
            return
        }
        let detachedHost = host
        detachedHost?.setHostDetachHandler(nil)
        host = nil
        cancelDialog(reason: .hostUnavailable, removalHost: detachedHost)
        clearSnackbars(removalHost: detachedHost)
    }

    func shutdown() {
        guard !isShutdown else {
            return
        }
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
        case entering
        case visible
        case exiting(ClipyDialog.Response)
    }

    struct DialogState {
        let token: UUID
        let response: @MainActor (ClipyDialog.Response) -> Void
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
        case dismiss
        case action
    }
    enum SnackbarPhase {
        case entering
        case visible
        case exiting(SnackbarCompletion)
    }
    struct SnackbarState {
        let token: UUID
        let fingerprint: SnackbarFingerprint
        var action: (@MainActor () -> Void)?
        var scheduledTask: AppOverlayScheduledTask?
        var phase: SnackbarPhase
    }

    func completeDialogEntry(token: UUID, result: AppOverlayMountResult) {
        guard let current = dialog, current.token == token, case .entering = current.phase else {
            return
        }
        switch result {
        case .displayed:
            dialog?.phase = .visible
        case .unavailable, .occupied:
            let removalHost = result == .unavailable ? host : nil
            // 동기 실패에서도 .accepted를 먼저 반환하고, occupied host의 incumbent는 건드리지 않습니다.
            Task { @MainActor [self] in
                guard let current = dialog, current.token == token, case .entering = current.phase else {
                    return
                }
                dialog?.phase = .exiting(.cancelled(.displayFailed))
                requestDialogRemoval(token: token, animated: false, removalHost: removalHost)
            }
        }
    }

    func cancelDialog(reason: ClipyDialog.CancellationReason, removalHost: AppOverlayHosting?) {
        guard let current = dialog else {
            return
        }
        switch current.phase {
        case .entering, .visible:
            beginDialogDismissal(
                token: current.token,
                response: .cancelled(reason),
                animated: false,
                removalHost: removalHost
            )
        case .exiting:
            // 사용자가 이미 고른 결과는 뒤늦게 들어온 scene/host 종료로 덮지 않습니다.
            guard let removalHost else {
                return
            }
            requestDialogRemoval(token: current.token, animated: false, removalHost: removalHost)
        }
    }

    func beginDialogDismissal(
        token: UUID,
        response: ClipyDialog.Response,
        animated: Bool,
        removalHost: AppOverlayHosting? = nil
    ) {
        guard let current = dialog, current.token == token else {
            return
        }
        switch current.phase {
        case .entering, .visible:
            dialog?.phase = .exiting(response)
            requestDialogRemoval(
                token: token,
                animated: animated,
                removalHost: removalHost ?? host
            )
        case .exiting:
            return
        }
    }

    func requestDialogRemoval(
        token: UUID,
        animated: Bool,
        removalHost: AppOverlayHosting?
    ) {
        guard let removalHost else {
            completeDialogRemoval(token: token)
            return
        }
        removalHost.unmountDialog(animated: animated) { [self] in
            completeDialogRemoval(token: token)
        }
    }

    func completeDialogRemoval(token: UUID) {
        guard let current = dialog, current.token == token, case let .exiting(response) = current.phase else {
            return
        }
        // response 안에서 새 Dialog를 바로 띄울 수 있게, callback 전에 자리를 먼저 비웁니다.
        dialog = nil
        current.response(response)
    }

    func showNextSnackbarIfNeeded() {
        guard
            !isInvokingSnackbarAction,
            isSceneActive,
            !isShutdown,
            visibleSnackbar == nil,
            !snackbarQueue.isEmpty,
            let host,
            host.isOverlayHostAvailable
        else {
            return
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
        host.mountSnackbar(
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
        case .occupied:
            // Host의 incumbent는 그 view를 올린 coordinator만 내릴 수 있습니다.
            clearSnackbars(removalHost: nil)
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
        case .exiting(.action):
            wasExiting = true
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
