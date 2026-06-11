//
//  Project.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = ClipyModuleFactory.makeFeature(
    module: .featureSession,
    dependencies: ClipyDependencies.featureSession,
    hasTests: true
)
