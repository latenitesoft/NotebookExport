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
    
    static var allTests = [
        ("testExtractDependenciesFromLine", testExtractDependenciesFromLine),
    ]
}
