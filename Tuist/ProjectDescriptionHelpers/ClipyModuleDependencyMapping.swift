//
//  ClipyModuleDependencyMapping.swift
//  Clipy
//
//  Created by 박민서 on 6/11/26.
//

import ProjectDescription

extension AppDependency {
    var targetDependency: TargetDependency {
        switch self {
        case let .core(module):
            return module.targetDependency
        case let .feature(module):
            return module.targetDependency
        case let .external(dependency):
            return dependency.targetDependency
        }
    }
}

extension CoreDependency {
    var targetDependency: TargetDependency {
        switch self {
        case let .core(module):
            return module.targetDependency
        case let .external(dependency):
            return dependency.targetDependency
        }
    }
}

extension FeatureDependency {
    var targetDependency: TargetDependency {
        switch self {
        case let .core(module):
            return module.targetDependency
        case let .external(dependency):
            return dependency.targetDependency
        }
    }
}

private extension ClipyModuleIdentifiable {
    var targetDependency: TargetDependency {
        .project(target: name, path: projectPath)
    }
}

private extension ExternalDependency {
    var targetDependency: TargetDependency {
        .external(name: packageName)
    }
}
