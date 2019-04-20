import XCTest
@testable import NotebookExport

final class NotebookExportTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(NotebookExport(filename: "/tmp/filename").filename, "/tmp/filename")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
