//
//  AppSplashViewController.swift
//  Clipy
//
//  Created by 박민서 on 7/25/26.
//

import UIKit

import Lottie

final class AppSplashViewController: UIViewController {
    private let backgroundImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "SplashBackground"))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleToFill
        return imageView
    }()

    private let animationView: LottieAnimationView?

    var isAnimationAvailable: Bool {
        animationView != nil
    }

    init() {
        animationView = Self.makeAnimationView()
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(
            red: 64 / 255,
            green: 81 / 255,
            blue: 224 / 255,
            alpha: 1
        )
        view.addSubview(backgroundImageView)
        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        guard let animationView else {
            return
        }

        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .playOnce
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animationView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            animationView.widthAnchor.constraint(equalToConstant: 176),
            animationView.heightAnchor.constraint(equalToConstant: 176)
        ])
    }

    func startPlayback(completion: @escaping LottieCompletionBlock) {
        animationView?.play(completion: completion)
    }

    func stopPlayback() {
        animationView?.stop()
    }

    private static func makeAnimationView() -> LottieAnimationView? {
        guard let animation = LottieAnimation.named("clipy_logo_animation", bundle: .main) else {
            #if DEBUG
                NSLog("Unable to load Splash animation resource: clipy_logo_animation")
            #endif

            return nil
        }

        return LottieAnimationView(animation: animation)
    }
}
