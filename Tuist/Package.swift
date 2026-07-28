// swift-tools-version: 5.9

//
//  Package.swift
//  Clipy
//
//  Created by 박민서 on 5/9/26.
//

import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(
    productTypes: [
        "RxSwift": .framework,
        "RxCocoa": .framework,
        "RxRelay": .framework,
        "RxCocoaRuntime": .framework
    ]
)
#endif

let package = Package(
    name: "ClipyDependencies",
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.10.2")
    ]
)
