//
//  Project.swift
//  Clipy
//
//  Created by 박민서 on 5/5/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = ClipyModuleFactory.makeCore(
    module: .corePersistence,
    dependencies: ClipyDependencies.corePersistence,
    coreDataModels: [
        .coreDataModel("Resources/ClipyPersistence.xcdatamodeld")
    ]
)
