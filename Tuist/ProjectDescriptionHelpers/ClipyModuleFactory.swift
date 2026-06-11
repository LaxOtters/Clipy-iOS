//
//  ClipyModuleFactory.swift
//  Clipy
//
//  Created by 박민서 on 4/28/26.
//

import ProjectDescription

public enum ClipyModuleFactory {
    /// App target과 test target, shared scheme을 함께 만듭니다.
    public static func makeApp(
        module: AppModule,
        dependencies: [AppDependency] = [],
        hasTests: Bool = true
    ) -> Project {
        var targets: [Target] = [
            .target(
                name: module.name,
                destinations: ClipyProjectConfig.defaultDestinations,
                product: .app,
                bundleId: "\(ClipyProjectConfig.bundleIdPrefix).\(module.bundleIdSuffix)",
                deploymentTargets: ClipyProjectConfig.deploymentTargets,
                infoPlist: .extendingDefault(with: ClipyProjectConfig.baseInfoPlist),
                sources: ["\(ClipyProjectConfig.sourcesDirectory)/**"],
                dependencies: dependencies.map(\.targetDependency)
            )
        ]

        if hasTests {
            targets.append(makeTestTarget(for: module))
        }

        return makeProject(module: module, targets: targets, hasTests: hasTests)
    }

    /// Core framework target을 만듭니다. CoreData model은 persistence module처럼 필요한 Core에서만 넘깁니다.
    public static func makeCore(
        module: CoreModule,
        dependencies: [CoreDependency] = [],
        hasTests: Bool = true,
        coreDataModels: [CoreDataModel] = []
    ) -> Project {
        makeFramework(
            module: module,
            dependencies: dependencies.map(\.targetDependency),
            hasTests: hasTests,
            coreDataModels: coreDataModels
        )
    }

    /// Feature framework target을 만듭니다. Feature끼리 직접 연결하지 않는 dependency shape를 받습니다.
    public static func makeFeature(
        module: FeatureModule,
        dependencies: [FeatureDependency] = [],
        hasTests: Bool = true
    ) -> Project {
        makeFramework(
            module: module,
            dependencies: dependencies.map(\.targetDependency),
            hasTests: hasTests
        )
    }
}

private extension ClipyModuleFactory {

    static func makeFramework(
        module: some ClipyModuleIdentifiable,
        dependencies: [TargetDependency],
        hasTests: Bool = true,
        coreDataModels: [CoreDataModel] = []
    ) -> Project {
        var targets: [Target] = [
            .target(
                name: module.name,
                destinations: ClipyProjectConfig.defaultDestinations,
                product: .framework,
                bundleId: "\(ClipyProjectConfig.bundleIdPrefix).\(module.bundleIdSuffix)",
                deploymentTargets: ClipyProjectConfig.deploymentTargets,
                infoPlist: .default,
                sources: ["\(ClipyProjectConfig.sourcesDirectory)/**"],
                dependencies: dependencies,
                coreDataModels: coreDataModels
            )
        ]

        if hasTests {
            targets.append(makeTestTarget(for: module))
        }

        return makeProject(module: module, targets: targets, hasTests: hasTests)
    }

    static func makeProject(
        module: some ClipyModuleIdentifiable,
        targets: [Target],
        hasTests: Bool
    ) -> Project {
        Project(
            name: module.name,
            options: .options(automaticSchemesOptions: .disabled),
            targets: targets,
            schemes: [makeScheme(name: module.name, hasTests: hasTests)]
        )
    }

    static func makeTestTarget(for module: some ClipyModuleIdentifiable) -> Target {
        .target(
            name: "\(module.name)Tests",
            destinations: ClipyProjectConfig.defaultDestinations,
            product: .unitTests,
            bundleId: "\(ClipyProjectConfig.bundleIdPrefix).\(module.bundleIdSuffix).tests",
            deploymentTargets: ClipyProjectConfig.deploymentTargets,
            infoPlist: .default,
            sources: ["\(ClipyProjectConfig.testsDirectory)/**"],
            dependencies: [.target(name: module.name)]
        )
    }

    static func makeScheme(name: String, hasTests: Bool) -> Scheme {
        Scheme.scheme(
            name: name,
            shared: true,
            buildAction: .buildAction(targets: [.init(stringLiteral: name)]),
            testAction: hasTests ? .targets([.init(stringLiteral: "\(name)Tests")]) : nil,
            runAction: .runAction(executable: .init(stringLiteral: name))
        )
    }
}