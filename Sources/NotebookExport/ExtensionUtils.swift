import Path

extension String {
    func findFirst(matching pattern: String) -> Range<String.Index>? {
        return range(of: pattern, options: .regularExpression)
    }
    
    func matches(pattern: String) -> Bool {
        return findFirst(matching: pattern) != nil
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

    func firstMatch(in string: String?, options: NSRegularExpression.MatchingOptions = []) -> NSTextCheckingResult? {
        guard let string = string else { return nil }
        let range = NSRange(location: 0, length: string.utf16.count)
        return firstMatch(in: string, options: options, range: range)
    }

    func matches(_ string: String?, options: NSRegularExpression.MatchingOptions = []) -> Bool {
        return firstMatch(in: string, options: options) != nil
    }
    
    func groupsOfFirstMatch(in string: String?, options: NSRegularExpression.MatchingOptions = []) -> [String]? {
        guard let string = string else { return nil }
        guard let match = self.firstMatch(in: string, options: options) else { return nil }
        var groups: [String] = []
        for i in 1..<match.numberOfRanges {
            guard let range = Range(match.range(at: i), in: string) else { continue }
            let group = String(string[range])
            groups.append(group)
        }
        return groups
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
