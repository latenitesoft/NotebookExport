// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NotebookExport",
    products: [
        .library(
        name: "NotebookExport",
        targets: ["NotebookExport"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1"),
    ],
    targets: [
        .target(
            name: "NotebookExport",
            dependencies: ["Path"]),
        .testTarget(
            name: "NotebookExportTests",
            dependencies: ["NotebookExport"]),
    ]
)
