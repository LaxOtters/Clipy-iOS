//
//  Project.swift
//  Clipy
//
//  Created by 박민서 on 7/24/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = ClipyModuleFactory.makeFeature(
    module: .featureHome,
    dependencies: ClipyDependencies.featureHome,
    resources: ["Resources/**"],
    synthesizesBundleAccessors: false,
    synthesizesResourceAccessors: false
)
