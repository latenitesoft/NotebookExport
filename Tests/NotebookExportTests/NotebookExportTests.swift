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

    static var allTests = [
        ("testExtractInstallableSources", testExtractInstallableSources),
    ]
}
