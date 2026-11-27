// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "JWDatePickerKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "JWDatePickerKit", targets: ["JWDatePickerKit"]),
        .library(name: "JWDatePickerKitSwiftUI", targets: ["JWDatePickerKitSwiftUI"])
    ],
    dependencies: [
        .package(
            url: "https://gitee.com/jw10126121/JWDialogManager.git",
            revision: "7df2749e898a83ea5b2c23853d9614682c70cf79"
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
    swiftLanguageModes: [.v6]
)
