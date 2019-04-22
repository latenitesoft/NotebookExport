import XCTest
@testable import NotebookExport

final class NotebookExportTests: XCTestCase {
    func testExtractDependenciesFromLine() {
        let exporter = NotebookExport("/tmp/")
        
        var
        installLine = #"%install '.package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1")' Path"#
        XCTAssert(exporter.dependencyFromInstallLine(installLine).first?.name == "Path")
        
        installLine = #"%install '.package(url: "https://github.com/latenitesoft/NotebookExport", .branch("master"))' NotebookExport"#
        XCTAssert(exporter.dependencyFromInstallLine(installLine).first?.name == "NotebookExport")
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
        ("testExtractDependenciesFromLine", testExtractDependenciesFromLine),
        ("testExtractDependenciesFromContents", testExtractDependenciesFromContents),
    ]
}
