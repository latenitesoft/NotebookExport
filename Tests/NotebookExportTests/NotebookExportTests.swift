import XCTest
@testable import NotebookExport

final class NotebookExportTests: XCTestCase {
    func testExtractInstallableSources() {
        //FIXME: Generate known test file by writing a string to /tmp
        let exporter = NotebookExport("/Users/pedro/code/s4tf/swift-jupyter/export_notebook/00_load_data.ipynb")
        var hasSource = false
        do {
            let sources = try exporter.extractInstallableSources()
            let lineCount = sources.first?.count ?? 0
            hasSource = lineCount == 6
        } catch {
            XCTFail()
        }
        XCTAssertEqual(hasSource, true)
    }

    func testExtractDependenciesFromContents() {
        let contents = """
        // swift-tools-version:4.0
        import PackageDescription
                                                                                  
        let package = Package(
            name: "FastaiNotebooks",
            products: [
                .library(name: "FastaiNotebooks", targets: ["FastaiNotebooks"]),
            ],
        dependencies: [
            .package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1"),
            .package(url: "https://github.com/JustHTTP/Just", from: "0.7.1"),
            .package(path: "some/local/Util.swift")
        ],
        targets: [
            .target(
                name: "FastaiNotebooks",
                dependencies: ["Just", "Path", "Util"]),
        ]
        )
        """
        let dependencies = DependencyDescription.fromPackageContents(contents)
        var hasPath = false
        var hasJust = false
        var hasUtil = false
        for dep in dependencies {
            if dep.name == "Path" { hasPath = true }
            if dep.name == "Just" { hasJust = true }
            if dep.name == "Util" { hasUtil = true }
        }
        XCTAssertEqual(hasPath && hasJust && hasUtil, true)
        //TODO: test package specs
    }

    static var allTests = [
        ("testExtractInstallableSources", testExtractInstallableSources),
    ]
}
