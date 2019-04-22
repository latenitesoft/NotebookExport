import Foundation
import Path

struct DependencyDescription : Hashable {
    let name: String
    let rawSpec: String
    
    var description: String { return rawSpec }
}

extension DependencyDescription {
    /// "Parses" package for dependencies.
    /// Simple implementation - we run a regexp against .package() lines
    /// that must appear in separate lines.
    static func fromPackage(at packagePath: Path) -> [DependencyDescription] {
        do {
            let packageContents = try String(contentsOf: packagePath/"Package.swift")
            return self.fromPackageContents(packageContents)
        } catch {
            // Possibly the file doesn't exist
            return []
        }
    }
    
    static func fromPackageContents(_ packageContents: String) -> [DependencyDescription] {
        //  dependencies: [
        //     .package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1"),
        //     .package(url: "https://github.com/JustHTTP/Just", from: "0.7.1")
        //  ],
        let packageRegexp = NSRegularExpression(#"^\s*(.package\(\w+:\s*"([^"]*)"(.*)\)),?$"#)
        
        var dependencies: [DependencyDescription] = []
        for line in packageContents.split(separator: "\n").map({ String($0) }) {
            let range = NSRange(line.startIndex ..< line.endIndex, in: line)
            packageRegexp.enumerateMatches(in: line, options: [], range: range) { (match, _, _) in
                guard let match = match else { return }
                guard match.numberOfRanges == 4 else { return }
                guard let specRange = Range(match.range(at: 1), in: line),
                    let urlRange = Range(match.range(at: 2), in: line) else { return }
                
                let spec = String(line[specRange])
                let location = String(line[urlRange])
                let url = URL(string: location) ?? URL(fileURLWithPath: location)
                let name = url.deletingPathExtension().lastPathComponent
                dependencies.append(DependencyDescription(name: name, rawSpec: spec))
            }

        }
        return dependencies
    }
}
