// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Segment-Adjust",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Segment-Adjust",
            targets: ["Segment-Adjust"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/segmentio/analytics-ios", from: "4.0.0"),
        .package(url: "https://github.com/adjust/ios_sdk", from: "4.0.0"),

    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Segment-Adjust",
            dependencies: [
                .product(name: "Segment", package: "analytics-ios"),
                .product(name: "Adjust", package: "ios_sdk"),
            ],
            path: "Pod/",
            sources: ["Classes"],
            publicHeadersPath: "Classes",
            cSettings: [
                .headerSearchPath("Classes")
            ]
        ),
    ]
)
