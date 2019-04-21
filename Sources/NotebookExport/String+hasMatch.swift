extension String {
    func findFirst(pat: String) -> Range<String.Index>? {
        return range(of: pat, options: .regularExpression)
    }
    
    func hasMatch(pat: String) -> Bool {
        return findFirst(pat:pat) != nil
    }
}
