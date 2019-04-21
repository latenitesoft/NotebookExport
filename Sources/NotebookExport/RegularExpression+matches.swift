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
