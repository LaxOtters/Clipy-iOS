//
//  ClipyModuleFactory.swift
//  Clipy
//
//  Created by 박민서 on 4/28/26.
//

import ProjectDescription

public enum ClipyModuleFactory {
    /// App target과 shared scheme을 만들고, 필요하면 test target을 함께 구성합니다.
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

    /// Core framework를 만들고 필요하면 test target, resource, CoreData model을 함께 구성합니다.
    /// resource bundle을 직접 찾는 모듈은 Tuist의 Bundle/resource accessor 자동 생성을 끌 수 있습니다.
    public static func makeCore(
        module: CoreModule,
        dependencies: [CoreDependency] = [],
        hasTests: Bool = true,
        resources: ResourceFileElements? = nil,
        synthesizesBundleAccessors: Bool = true,
        synthesizesResourceAccessors: Bool = true,
        coreDataModels: [CoreDataModel] = []
    ) -> Project {
        makeFramework(
            module: module,
            dependencies: dependencies.map(\.targetDependency),
            hasTests: hasTests,
            resources: resources,
            synthesizesBundleAccessors: synthesizesBundleAccessors,
            synthesizesResourceAccessors: synthesizesResourceAccessors,
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
        resources: ResourceFileElements? = nil,
        synthesizesBundleAccessors: Bool = true,
        synthesizesResourceAccessors: Bool = true,
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
                resources: resources,
                dependencies: dependencies,
                coreDataModels: coreDataModels
            )
        ]

        if hasTests {
            targets.append(makeTestTarget(for: module))
        }

        return makeProject(
            module: module,
            targets: targets,
            hasTests: hasTests,
            synthesizesBundleAccessors: synthesizesBundleAccessors,
            synthesizesResourceAccessors: synthesizesResourceAccessors
        )
    }

    static func makeProject(
        module: some ClipyModuleIdentifiable,
        targets: [Target],
        hasTests: Bool,
        synthesizesBundleAccessors: Bool = true,
        synthesizesResourceAccessors: Bool = true
    ) -> Project {
        Project(
            name: module.name,
            options: .options(
                automaticSchemesOptions: .disabled,
                disableBundleAccessors: !synthesizesBundleAccessors,
                disableSynthesizedResourceAccessors: !synthesizesResourceAccessors
            ),
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
