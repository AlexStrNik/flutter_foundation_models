// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "flutter_foundation_models",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .library(name: "flutter-foundation-models", targets: ["flutter_foundation_models"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_foundation_models",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
