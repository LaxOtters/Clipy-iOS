//
//  ClipyProjectConfig.swift
//  Clipy
//
//  Created by 박민서 on 4/28/26.
//

import ProjectDescription

public enum ClipyProjectConfig {
    public static let bundleIdPrefix = "com.laxotters.clipy"
    public static let defaultDestinations: Destinations = [.iPhone]
    public static let modulesRoot = "Modules"
    public static let deploymentTargets: DeploymentTargets = .iOS("16.0")
    public static let sourcesDirectory = "Sources"
    public static let testsDirectory = "Tests"

    public static let baseInfoPlist: [String: Plist.Value] = [
        "CFBundleDevelopmentRegion": "en",
        "CFBundleDisplayName": "Clipy",
        "UIApplicationSceneManifest": [
            "UIApplicationSupportsMultipleScenes": false,
            "UISceneConfigurations": [
                "UIWindowSceneSessionRoleApplication": [
                    [
                        "UISceneConfigurationName": "Default Configuration",
                        "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate"
                    ]
                ]
            ]
        ],
        "UILaunchScreen": [:],
        "UISupportedInterfaceOrientations": [
            "UIInterfaceOrientationPortrait"
        ]
    ]
}
