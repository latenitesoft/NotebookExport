// DependencyDescription

import Foundation
import Path

struct DependencyDescription : Hashable {
    let name: String
    let rawSpec: String
    
    func spec(relativeTo path: Path) -> String {
        let localSpec = NSRegularExpression(#"^\s*.package\(path:\s*"([^"]*)"(.*)\)$"#)
        let range = NSRange(rawSpec.startIndex ..< rawSpec.endIndex, in: rawSpec)
        guard let match = localSpec.firstMatch(in: rawSpec, options: [], range: range) else { return rawSpec }
        guard match.numberOfRanges == 3 else { return rawSpec }
        guard let pathRange = Range(match.range(at: 1), in: rawSpec) else { return rawSpec }
        
        let absolutePath = Path.from(String(rawSpec[pathRange]))
        let relativePath = absolutePath.relative(to: path)
        return rawSpec.replacingCharacters(in: pathRange, with: relativePath)
    }
}
