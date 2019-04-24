import Path

extension String {
    func findFirst(pat: String) -> Range<String.Index>? {
        return range(of: pat, options: .regularExpression)
    }
    
    func hasMatch(pat: String) -> Bool {
        return findFirst(pat:pat) != nil
    }
}
import Foundation

extension NSRegularExpression {
    convenience init(_ pattern: String) {
        do {
            try self.init(pattern: pattern)
        } catch {
            preconditionFailure("Illegal regular expression: \(pattern).")
        }
    }
    
    func matches(_ string: String?, options: NSRegularExpression.MatchingOptions = []) -> Bool {
        guard let string = string else { return false }
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: options, range: range) != nil
    }
}

extension Path {
    /// Always succeeds - prepends 'cwd' to the path if necessary
    static func from(_ path: String) -> Path {
        return Path(path) ?? Path.cwd/path
    }
    
    /* Copied from symlink implementation at https://github.com/mxcl/Path.swift/blob/master/Sources/Path%2BFileManager.swift */
    
    /**
     Creates a hardlink of this file at `as`.
     - Note: If `self` does not exist, is **not** an error.
     */
    @discardableResult
    func link(as: Path) throws -> Path {
        try FileManager.default.linkItem(atPath: string, toPath: `as`.string)
        return `as`
    }
    
    /**
     Creates a symlink of this file with the same filename in the `into` directory.
     - Note: If into does not exist, creates the directory with intermediate directories if necessary.
     */
    @discardableResult
    func link(into dir: Path) throws -> Path {
        switch dir.kind {
        case nil, .symlink?:
            try dir.mkdir(.p)
            fallthrough
        case .directory?:
            return try link(as: dir/basename())
        case .file?:
            throw CocoaError.error(.fileWriteFileExists)
        }
    }

}

extension String {
    var quoted: String { return "\"\(self)\"" }
}
