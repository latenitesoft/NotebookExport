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
}

extension String {
    var quoted: String { return "\"\(self)\"" }
}
