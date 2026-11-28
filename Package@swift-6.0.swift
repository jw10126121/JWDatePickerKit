// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JWDatePickerKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "JWDatePickerKit", targets: ["JWDatePickerKit"]),
        .library(name: "JWDatePickerKitSwiftUI", targets: ["JWDatePickerKitSwiftUI"]),
        .library(name: "JWDatePicker", targets: ["JWDatePickerKit"]),
        .library(name: "JWDatePickerSwiftUI", targets: ["JWDatePickerKitSwiftUI"])
    ],
    dependencies: [
        .package(
            url: "https://gitee.com/jw10126121/JWDialogManager.git",
            .upToNextMinor(from: "0.1.3")
        )
    ],
    targets: [
        .target(
            name: "JWDatePickerKit",
            dependencies: [
                .product(name: "JWDialogManager", package: "jwdialogmanager")
            ],
            path: "JWDatePickerKit",
            exclude: ["Assets", "SwiftUI"],
            sources: [
                "Classes/Picker",
                "Classes/Content",
                "Classes/JWDatePickerViewController.swift",
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
    swiftLanguageModes: [.v5, .v6]
)
