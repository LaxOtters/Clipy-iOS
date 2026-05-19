//
//  Project.swift
//  Clipy
//
//  Created by 박민서 on 4/28/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = ClipyModuleFactory.makeApp(
    name: "AppMain",
    bundleIdSuffix: "app",
    dependencies: [
        .project(target: "FeatureSession", path: .relativeToRoot("Modules/FeatureSession")),
        .project(target: "CorePersistence", path: .relativeToRoot("Modules/CorePersistence"))
    ]
)
