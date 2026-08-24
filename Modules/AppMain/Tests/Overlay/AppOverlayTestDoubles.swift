//
//  AppOverlayTestDoubles.swift
//  Clipy
//
//  Created by 박민서 on 8/21/26.
//

import UIKit

import CoreDesignSystem
@testable import AppMain

@MainActor
let overlayDialogConfiguration = ClipyDialog.Configuration.message(
    presentation: .plain,
    title: "Title",
    body: "Body",
    buttons: .single(title: "OK")
)

@MainActor
func makeOverlayCoordinator(
    host: OverlayHostSpy,
    scheduler: OverlaySchedulerSpy? = nil
) -> AppOverlayCoordinator {
    AppOverlayCoordinator(
        host: host,
        isSceneActive: true,
        scheduler: scheduler ?? OverlaySchedulerSpy()
    )
}

@MainActor
final class OverlayHostSpy: AppOverlayHosting {
    struct SnackbarCallbacks {
        let onAction: (() -> Void)?
        let onDismiss: () -> Void
    }

    var isOverlayHostAvailable: Bool
    private(set) var mountedDialogCount = 0
    private(set) var mountedSnackbarCount = 0
    var dialogCallbacks: [(ClipyDialog.Selection, String?) -> Void] = []
    var snackbarMessages: [String] = []
    var snackbarCallbacks: [SnackbarCallbacks] = []
    var dialogUnmountAnimations: [Bool] = []
    var snackbarUnmountAnimations: [Bool] = []
    private(set) var events: [String] = []
    var onDialogUnmountRequested: (() -> Void)?
    var outsideTapHandler: (() -> Void)?
    var hostDetachHandler: (() -> Void)?

    private let dialogMountResult: AppOverlayMountResult?
    private let defersDialogUnmount: Bool
    private let defersSnackbarMount: Bool
    private let defersSnackbarUnmount: Bool
    private var dialogMountCompletions: [(AppOverlayMountResult) -> Void] = []
    private var dialogUnmountCompletions: [(() -> Void)?] = []
    private var snackbarMountCompletions: [(AppOverlayMountResult) -> Void] = []
    private var snackbarUnmountCompletions: [(() -> Void)?] = []

    init(
        isAvailable: Bool = true,
        dialogMountResult: AppOverlayMountResult? = .displayed,
        defersDialogUnmount: Bool = false,
        defersSnackbarMount: Bool = false,
        defersSnackbarUnmount: Bool = false
    ) {
        isOverlayHostAvailable = isAvailable
        self.dialogMountResult = dialogMountResult
        self.defersDialogUnmount = defersDialogUnmount
        self.defersSnackbarMount = defersSnackbarMount
        self.defersSnackbarUnmount = defersSnackbarUnmount
    }

    func mountDialog(
        configuration: ClipyDialog.Configuration,
        onSelection: @escaping (ClipyDialog.Selection, String?) -> Void,
        completion: @escaping (AppOverlayMountResult) -> Void
    ) -> AppOverlayMountAdmission {
        guard mountedDialogCount == 0 else {
            return .occupied
        }
        mountedDialogCount = 1
        events.append("dialogMounted")
        dialogCallbacks.append(onSelection)
        if let dialogMountResult {
            completion(dialogMountResult)
        } else {
            dialogMountCompletions.append(completion)
        }
        return .accepted
    }

    func unmountDialog(animated: Bool, completion: @escaping () -> Void) {
        mountedDialogCount = 0
        events.append("dialogUnmountRequested")
        dialogUnmountAnimations.append(animated)
        onDialogUnmountRequested?()
        if defersDialogUnmount {
            dialogUnmountCompletions.append(completion)
        } else {
            completion()
        }
    }

    func mountSnackbar(
        message: String,
        actionTitle: String?,
        onAction: (() -> Void)?,
        onDismiss: @escaping () -> Void,
        completion: @escaping (AppOverlayMountResult) -> Void
    ) -> AppOverlayMountAdmission {
        guard mountedSnackbarCount == 0 else {
            return .occupied
        }
        mountedSnackbarCount = 1
        snackbarMessages.append(message)
        events.append("snackbarMounted:\(message)")
        let callbacks = SnackbarCallbacks(onAction: onAction, onDismiss: onDismiss)
        snackbarCallbacks.append(callbacks)
        outsideTapHandler = onDismiss
        if defersSnackbarMount {
            snackbarMountCompletions.append(completion)
        } else {
            completion(.displayed)
        }
        return .accepted
    }

    func unmountSnackbar(animated: Bool, completion: @escaping () -> Void) {
        mountedSnackbarCount = 0
        outsideTapHandler = nil
        events.append("snackbarUnmountRequested")
        snackbarUnmountAnimations.append(animated)
        if defersSnackbarUnmount {
            snackbarUnmountCompletions.append(completion)
        } else {
            completion()
        }
    }

    func setHostDetachHandler(_ handler: (() -> Void)?) {
        hostDetachHandler = handler
    }

    func completeDialogMount(at index: Int, didDisplay: Bool) {
        dialogMountCompletions[index](didDisplay ? .displayed : .unavailable)
    }

    func completeDialogUnmount(at index: Int) {
        events.append("dialogUnmountCompleted")
        let completion = dialogUnmountCompletions[index]
        dialogUnmountCompletions[index] = nil
        completion?()
    }

    func completeSnackbarUnmount(at index: Int) {
        events.append("snackbarUnmountCompleted")
        let completion = snackbarUnmountCompletions[index]
        snackbarUnmountCompletions[index] = nil
        completion?()
    }

    func completeSnackbarMount(at index: Int, didDisplay: Bool) {
        snackbarMountCompletions[index](didDisplay ? .displayed : .unavailable)
    }

    func recordEvent(_ event: String) {
        events.append(event)
    }
}

@MainActor
final class OverlaySchedulerSpy: AppOverlayScheduling {
    var tasks: [ScheduledTaskSpy] = []
    var intervals: [TimeInterval] = []

    func schedule(after interval: TimeInterval, action: @escaping () -> Void) -> AppOverlayScheduledTask {
        let task = ScheduledTaskSpy(action: action)
        intervals.append(interval)
        tasks.append(task)
        return task
    }
}

@MainActor
final class ScheduledTaskSpy: AppOverlayScheduledTask {
    private let action: () -> Void
    private(set) var isCancelled = false

    init(action: @escaping () -> Void) {
        self.action = action
    }

    func cancel() {
        isCancelled = true
    }

    func fireEvenIfCancelled() {
        action()
    }
}

final class LifetimeSentinel {}
