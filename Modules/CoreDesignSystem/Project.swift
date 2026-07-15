//
//  Project.swift
//  Clipy
//
//  Created by 박민서 on 7/15/26.
//

import ProjectDescription
import ProjectDescriptionHelpers

let project = ClipyModuleFactory.makeCore(
    module: .coreDesignSystem,
    dependencies: ClipyDependencies.coreDesignSystem,
    resources: ["Resources/**"],
    synthesizesBundleAccessors: false,
    synthesizesResourceAccessors: false
)
