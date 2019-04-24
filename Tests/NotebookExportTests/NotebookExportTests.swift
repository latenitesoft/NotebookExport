import XCTest
import Path
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

    func testDependencyRelativeToPackage() {
        let exporter = NotebookExport(Path.from("test_01.ipynb"))
        
        let localInstallLine = #"%install '.package(path: "$cwd/ExportedNotebook_test_00")' ExportedNotebook_test_00"#
        guard let dependency = exporter.dependencyFromInstallLine(localInstallLine).first else {
            XCTFail()
            return
        }
        let packagePath = Path.from("ExportedNotebook_" + exporter.filepath.basename(dropExtension: true))
        let relativeSpec = dependency.spec(relativeTo: packagePath)
        XCTAssert(relativeSpec == #".package(path: "../ExportedNotebook_test_00")"#)
    }

    static var allTests = [
        ("testExtractDependenciesFromLine", testExtractDependenciesFromLine),
    ]
}
