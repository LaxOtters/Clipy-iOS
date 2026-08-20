//
//  AppOverlayScheduling.swift
//  Clipy
//
//  Created by 박민서 on 8/21/26.
//

import Foundation

@MainActor
protocol AppOverlayScheduledTask: AnyObject {
    func cancel()
}

@MainActor
protocol AppOverlayScheduling {
    func schedule(after interval: TimeInterval, action: @escaping () -> Void) -> AppOverlayScheduledTask
}

@MainActor
struct AppOverlayScheduler: AppOverlayScheduling {
    func schedule(after interval: TimeInterval, action: @escaping () -> Void) -> AppOverlayScheduledTask {
        let task = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: task)
        return task
    }
}

extension DispatchWorkItem: AppOverlayScheduledTask {}
