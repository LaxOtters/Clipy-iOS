//
//  ClipyRootViewController.swift
//  Clipy
//
//  Created by 박민서 on 4/28/26.
//

import UIKit

import FeatureSession

final class ClipyRootViewController: UIViewController {
    private let sampleSessionId = UUID()
    private let sessionSmokeURL = URL(string: "https://www.google.com")

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground

        let titleLabel = UILabel()
        titleLabel.text = AppMainBaseline.title
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = "UIKit baseline is ready."
        subtitleLabel.font = .preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center

        let openSessionButton = UIButton(type: .system)
        openSessionButton.setTitle("Open Session", for: .normal)
        openSessionButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        openSessionButton.addTarget(self, action: #selector(openSession), for: .touchUpInside)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, openSessionButton])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 12
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: view.layoutMarginsGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(lessThanOrEqualTo: view.layoutMarginsGuide.trailingAnchor)
        ])
    }

    @objc private func openSession() {
        let context = SessionLaunchContext(
            sessionId: sampleSessionId,
            initialURL: sessionSmokeURL
        )
        let viewController = SessionFeature.makeViewController(context: context)

        navigationController?.pushViewController(viewController, animated: true)
    }
}
