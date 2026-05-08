//
//  Project.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = ClipyModuleFactory.makeFramework(
    name: "FeatureSession",
    bundleIdSuffix: "feature-session",
    dependencies: [
        .external(name: "RxSwift"),
        .external(name: "RxCocoa"),
        .external(name: "RxRelay"),
        .project(target: "CoreDomain", path: .relativeToRoot("Modules/CoreDomain"))
    ],
    hasTests: true
)
