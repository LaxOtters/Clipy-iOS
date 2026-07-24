//
//  ClipyActionMenuView.swift
//  Clipy
//
//  Created by 박민서 on 7/23/26.
//

import UIKit

/// Action Menu 항목을 보여주고, 표시 상태와 항목 선택 action 실행을 맡습니다.
/// 표시·숨김 animation은 내부 surface에서만 수행해, 호출자가 root view에 적용한 배치 transform과 layer animation을 건드리지 않습니다.
/// 화면 안의 위치와 메뉴를 닫는 조건은 이 뷰를 사용하는 화면이 정합니다.
public final class ClipyActionMenuView: UIView {
    public override var intrinsicContentSize: CGSize {
        CGSize(width: 135, height: 8 + 40 * CGFloat(items.count))
    }

    private enum Endpoint: Equatable {
        case presented
        case dismissed
    }

    private let items: [ClipyActionMenuItem]
    private let animation: ClipyActionMenuAnimation
    private let surfaceView = UIView()
    private let stackView = UIStackView()
    private var targetEndpoint: Endpoint = .dismissed
    private var latestRequestID = 0

    /// items는 표시할 순서대로 전달하며, 빈 배열이면 메뉴를 만들지 않습니다.
    public init?(
        items: [ClipyActionMenuItem],
        animation: ClipyActionMenuAnimation = .standard
    ) {
        guard !items.isEmpty else {
            assertionFailure("ClipyActionMenuView requires at least one item.")

            return nil
        }

        self.items = items
        self.animation = animation
        super.init(frame: .zero)

        configureAppearance()
        configureRows()
        apply(endpoint: .dismissed)
    }

    /// 메뉴를 표시합니다. 숨김 전환과 겹치면 이 요청이 최종 상태를 정합니다.
    public func present(animated: Bool = true) {
        transition(to: .presented, animated: animated)
    }

    /// 메뉴를 숨깁니다. 표시 전환과 겹치면 이 요청이 최종 상태를 정합니다.
    public func dismiss(animated: Bool = true) {
        transition(to: .dismissed, animated: animated)
    }

    func performAction(at index: Int) {
        guard items.indices.contains(index) else {
            assertionFailure("ClipyActionMenuView action index is out of range.")

            return
        }

        items[index].action()
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ClipyActionMenuView {
    func configureAppearance() {
        surfaceView.backgroundColor = ClipyColor.Foundation.primary50
        surfaceView.layer.cornerRadius = 8
        surfaceView.layer.shadowColor = UIColor.black.cgColor
        surfaceView.layer.shadowOffset = CGSize(width: 3, height: 6)
        surfaceView.layer.shadowRadius = 20
        surfaceView.layer.shadowOpacity = 0.1
        surfaceView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(surfaceView)

        stackView.axis = .vertical
        stackView.spacing = 0
        stackView.translatesAutoresizingMaskIntoConstraints = false
        surfaceView.addSubview(stackView)

        NSLayoutConstraint.activate([
            surfaceView.leadingAnchor.constraint(equalTo: leadingAnchor),
            surfaceView.trailingAnchor.constraint(equalTo: trailingAnchor),
            surfaceView.topAnchor.constraint(equalTo: topAnchor),
            surfaceView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: surfaceView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: surfaceView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: surfaceView.topAnchor, constant: 4),
            stackView.bottomAnchor.constraint(equalTo: surfaceView.bottomAnchor, constant: -4)
        ])
    }

    func configureRows() {
        for (index, item) in items.enumerated() {
            let row = ClipyActionMenuRow(item: item)
            row.addAction(
                UIAction { [weak self] _ in
                    self?.performAction(at: index)
                },
                for: .touchUpInside
            )
            stackView.addArrangedSubview(row)
            row.heightAnchor.constraint(equalToConstant: 40).isActive = true
        }
    }

    private func transition(to endpoint: Endpoint, animated: Bool) {
        guard endpoint != targetEndpoint else {
            return
        }

        targetEndpoint = endpoint
        latestRequestID += 1
        let requestID = latestRequestID

        guard animated, animation.canAnimate, animation.duration > 0 else {
            apply(endpoint: endpoint)
            return
        }

        switch endpoint {
        case .presented:
            if isHidden {
                isHidden = false
                alpha = 1
                surfaceView.alpha = 0
                surfaceView.transform = transitionTransform
            }
            isUserInteractionEnabled = false
        case .dismissed:
            isHidden = false
            isUserInteractionEnabled = false
        }

        UIView.animate(
            withDuration: animation.duration,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut],
            animations: { [weak self] in
                guard let self else {
                    return
                }

                switch endpoint {
                case .presented:
                    self.surfaceView.alpha = 1
                    self.surfaceView.transform = .identity
                case .dismissed:
                    self.surfaceView.alpha = 0
                    self.surfaceView.transform = self.transitionTransform
                }
            },
            completion: { [weak self] _ in
                // 이전 animation completion이 최신 요청의 endpoint를 덮어쓰지 못하게 요청 번호도 확인합니다.
                guard let self, self.latestRequestID == requestID, self.targetEndpoint == endpoint else {
                    return
                }

                self.apply(endpoint: endpoint)
            }
        )
    }

    private func apply(endpoint: Endpoint) {
        surfaceView.layer.removeAllAnimations()
        surfaceView.transform = .identity

        switch endpoint {
        case .presented:
            isHidden = false
            alpha = 1
            surfaceView.alpha = 1
            isUserInteractionEnabled = true
        case .dismissed:
            isHidden = true
            alpha = 0
            surfaceView.alpha = 0
            isUserInteractionEnabled = false
        }
    }

    var transitionTransform: CGAffineTransform {
        switch animation.style {
        case .fadeAndScale:
            CGAffineTransform(scaleX: 0.96, y: 0.96)
        case .fade, .none:
            .identity
        }
    }
}
