//
//  HomeViewModel.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import Foundation

import RxCocoa
import RxRelay
import RxSwift

/// First Use의 세션 시작 요청 상태와 결과 event를 화면이 구독할 output으로 만듭니다.
final class HomeViewModel {
    struct Input {
        let beginComparisonTap: Signal<Void>
    }

    struct Output {
        let isStartEnabled: Driver<Bool>
        let route: Signal<HomeFeatureRoute>
        let failureAlert: Signal<Void>
    }

    private let startNewSession: () async throws -> UUID
    private let disposeBag = DisposeBag()
    private let isStartEnabledRelay = BehaviorRelay(value: true)
    private let routeRelay = PublishRelay<HomeFeatureRoute>()
    private let failureAlertRelay = PublishRelay<Void>()
    private var isStarting = false

    init(startNewSession: @escaping () async throws -> UUID) {
        self.startNewSession = startNewSession
    }

    func transform(input: Input) -> Output {
        input.beginComparisonTap
            .emit(with: self) { viewModel, _ in
                viewModel.beginSession()
            }
            .disposed(by: disposeBag)

        return Output(
            isStartEnabled: isStartEnabledRelay.asDriver(),
            route: routeRelay.asSignal(),
            failureAlert: failureAlertRelay.asSignal()
        )
    }

    private func beginSession() {
        guard !isStarting else {
            return
        }

        isStarting = true
        isStartEnabledRelay.accept(false)
        let startNewSession = startNewSession

        Task { @MainActor [weak self] in
            do {
                let sessionID = try await startNewSession()
                self?.routeRelay.accept(.session(sessionID))
                self?.isStarting = false
                self?.isStartEnabledRelay.accept(true)
            } catch {
                self?.isStarting = false
                self?.isStartEnabledRelay.accept(true)
                self?.failureAlertRelay.accept(())
            }
        }
    }
}
