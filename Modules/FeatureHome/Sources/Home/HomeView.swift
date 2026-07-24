//
//  HomeView.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import UIKit

import CoreDesignSystem

/// Figma First Use frame의 top bar, hero, 안내 카드를 safe area와 scroll view로 조립합니다.
final class HomeView: UIView {
    let beginComparisonButton = HomeHeroButton()

    private let topBarView = UIView()
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureHierarchy()
        configureStyle()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}

private extension HomeView {
    func configureHierarchy() {
        let titleLabel = UILabel()
        ClipyTypography.heading2.apply(
            to: titleLabel,
            text: "Clipy",
            color: ClipyColor.Foundation.primary500
        )
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        topBarView.addSubview(titleLabel)

        addSubview(topBarView)
        addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        let heroView = HomeHeroView(button: beginComparisonButton)
        contentStackView.addArrangedSubview(heroView)
        heroView.heightAnchor.constraint(equalToConstant: 202).isActive = true

        let howItWorksLabel = UILabel()
        ClipyTypography.heading3.apply(
            to: howItWorksLabel,
            text: "How Clipy Works",
            color: ClipyColor.Foundation.neutral900
        )

        let cardsStackView = UIStackView(arrangedSubviews: [
            HomeHowItWorksCard(
                title: "Browse",
                description: "Open the web and explore products.",
                illustration: .browse
            ),
            HomeHowItWorksCard(
                title: "Collect",
                description: "Save options into one comparison session.",
                illustration: .collect
            ),
            HomeHowItWorksCard(
                title: "Decide",
                description: "Return later, compare,\nand choose with context.",
                illustration: .decide
            )
        ])
        cardsStackView.axis = .vertical
        cardsStackView.spacing = 16

        let guideStackView = UIStackView(arrangedSubviews: [howItWorksLabel, cardsStackView])
        guideStackView.axis = .vertical
        guideStackView.spacing = 16
        contentStackView.addArrangedSubview(guideStackView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: topBarView.leadingAnchor, constant: 20),
            titleLabel.centerYAnchor.constraint(equalTo: topBarView.centerYAnchor)
        ])
    }

    func configureStyle() {
        backgroundColor = ClipyColor.Foundation.primary50
        topBarView.backgroundColor = ClipyColor.Foundation.primary50

        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false

        contentStackView.axis = .vertical
        contentStackView.spacing = 20
    }

    func configureLayout() {
        topBarView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            topBarView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            topBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            topBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
            topBarView.heightAnchor.constraint(equalToConstant: 60),

            scrollView.topAnchor.constraint(equalTo: topBarView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 30),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -20),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -40),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }
}
