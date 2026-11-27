// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "JWDatePickerKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "JWDatePickerKit", targets: ["JWDatePickerKit"]),
        .library(name: "JWDatePickerKitSwiftUI", targets: ["JWDatePickerKitSwiftUI"])
    ],
    targets: [
        .target(
            name: "JWDatePickerKit",
            path: "JWDatePickerKit",
            exclude: ["Classes/JWDatePickerViewController.swift", "Assets", "SwiftUI"],
            sources: [
                "Classes/Picker",
                "Classes/Content",
                "Classes/JWDatePickerMenuHeaderView.swift"
            ],
            resources: [.process("Resources")]
        ),
        .target(
            name: "JWDatePickerKitSwiftUI",
            dependencies: ["JWDatePickerKit"],
            path: "JWDatePickerKit/SwiftUI"
        )
    ],
    swiftLanguageVersions: [.v5]
)
