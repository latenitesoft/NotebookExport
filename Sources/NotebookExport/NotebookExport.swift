import Foundation
import Path

public struct NotebookExport {
    let filepath: Path
    
    struct DependencyDescription : Hashable {
        let name: String
        let rawSpec: String
        
        var description: String { return rawSpec }
    }
    
    public enum NotebookExportError: Error {
        case unexpectedNotebookFormat
    }
    
    let exportRegexp = NSRegularExpression(#"^\s*//\s*export\s*$"#)                 // Swift 5 raw String
    
    // %install '.package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1")' Path
    let installRegexp = NSRegularExpression(#"^\s*%install '(.*)'\s(.*)$"#)         // Swift 5 raw String

    /// Parse the notebook and selects the cells of interest,
    /// returning the content filtered and transformed by the supplied closure.
    /// Parsed data is not cached, so multiple calls will read from the document again.
    func processCells(contentTransform: (_ cellSource: [String]) -> [String]?) throws -> [[String]] {
        let data = try Data(contentsOf: filepath)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        
        guard let jsonDictionary = json as? [String: Any] else {
            //TODO: Accept the payload if it's an array with a single dictionary inside
            throw NotebookExportError.unexpectedNotebookFormat
        }
        
        guard let cells = jsonDictionary["cells"] as? [[String: Any]] else {
            throw NotebookExportError.unexpectedNotebookFormat
        }
        
        // Use compactMap to combine the filter and map we need
        let selectedSources: [[String]] = cells.compactMap { cell in
            guard let source = cell["source"] as? [String] else { return nil }
            return contentTransform(source)     // nil to ignore this cell
        }
        
        return selectedSources
    }

    /// Parse the notebook and extract the source of the exportable cells (minus the comment line).
    /// Parsed data is not cached.
    func extractExportableSources() throws -> [[String]] {
        return try processCells { source in
            guard exportRegexp.matches(source.first) else { return nil }
            return Array(source[1...])
        }
    }

    /// Parse the notebook and extract the source of the install cells.
    /// Parsed data is not cached.
    func extractInstallableSources() throws -> [[String]] {
        return try processCells { source in
            for line in source {
                if installRegexp.matches(line) { return source }
            }
            return nil
        }
    }
    
    func dependencyFromInstallLine(_ line: String) -> [DependencyDescription] {
        //TODO: is there anything we can do about %install-swiftpm-flags?
        // %install '.package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1")' Path
        let lineRange = NSRange(line.startIndex..<line.endIndex, in: line)
        var dependencies: [DependencyDescription] = []
        installRegexp.enumerateMatches(in: line, options: [], range: lineRange) { (match, _, _) in
            guard let match = match else { return }
            guard match.numberOfRanges == 3 else { return }
            guard let specRange = Range(match.range(at: 1), in: line),
                let nameRange = Range(match.range(at: 2), in: line) else { return }
            
            let name = String(line[nameRange])
            let spec = String(line[specRange]).replacingOccurrences(of: "$cwd", with: Path.cwd.string)
            dependencies.append(DependencyDescription(name: name, rawSpec: spec))
        }
        return dependencies
    }
    
    /// Extract dependencies from %install cells
    func extractDependencies() throws -> [DependencyDescription] {
        var dependencies: [DependencyDescription] = []
        for cellSource in try extractInstallableSources() {
            for line in cellSource {
                dependencies.append(contentsOf: dependencyFromInstallLine(line))
            }
        }
        return dependencies
    }

    /// Update global Package.swift
    func updatePackageSpec(at path: Path, packageName: String, dependencies: [DependencyDescription]) throws {
        let dependencyPackages = (dependencies.map { return $0.description }).joined(separator: ",\n    ")
        let dependencyNames = (dependencies.map { return "\($0.name.quoted)" }).joined(separator: ", ")
        let manifest = """
        // swift-tools-version:4.2
        import PackageDescription

        let package = Package(
            name: "\(packageName)",
            products: [
                .library(name: "\(packageName)", targets: ["\(packageName)"]),
            ],
        dependencies: [
            \(dependencyPackages)
        ],
        targets: [
            .target(
                name: "\(packageName)",
                dependencies: [\(dependencyNames)]),
            ]
        )
        """
        try manifest.write(to: path/"Package.swift")
    }
    
    public enum ExportResult {
        case success
        case failure(reason: String)
    }
    
    /// Export as an additional source inside the specified package path
    /// If mergingDependencies is true and a Package.swift file already exists
    /// at the package location, merge the detected dependencies with the ones
    /// already in the package.
    @discardableResult
    func toScript(inside packagePath: Path) -> ExportResult {
        let newname = filepath.basename(dropExtension: true) + ".swift"
        let packageName = packagePath.basename()
        let destination = packagePath/"Sources"/packageName/newname
        do {
            var module = """
            /*
            THIS FILE WAS AUTOGENERATED! DO NOT EDIT!
            file to edit: \(filepath.basename())
            
            */
            
            """
            for cellSource in try extractExportableSources() {
                module.append("\n" + cellSource.joined() + "\n")
            }
            
            try destination.parent.mkdir(.p)
            try module.write(to: destination, encoding: .utf8)
            
            let packageDependencies = try extractDependencies()
            try updatePackageSpec(at: packagePath, packageName: packageName, dependencies: packageDependencies)
            
            return .success
        } catch {
            return .failure(reason: "Can't export \(filepath)")
        }
    }
    
    /// Hardlink sources from previously exported notebooks this one explicitly depends on.
    func unwrapSourcesFromLocalDependencies(withPrefix prefix: String, inside packagePath: Path) -> ExportResult {
        var result: ExportResult = .success
        do {
            // Parse dependencies again and copy sources from local (i.e., path:) ones
            // with the same prefix in the same parent directory.
            let localSpec = NSRegularExpression(#"^\s*.package\(path:\s*"([^"]*)"(.*)\)$"#)
            try extractDependencies().forEach { dependency in
                guard dependency.name.hasPrefix(prefix) else { return }
                let spec = dependency.rawSpec
                let range = NSRange(spec.startIndex ..< spec.endIndex, in: spec)
                localSpec.enumerateMatches(in: spec, options: [], range: range) { (match, _, _) in
                    guard let match = match else { return }
                    guard match.numberOfRanges == 3 else { return }
                    guard let pathRange = Range(match.range(at: 1), in: spec) else { return }
                    
                    let path = Path.from(String(spec[pathRange]))
                    guard path.parent == packagePath.parent else { return }
                    
                    // Do copy files
                    do {
                        let packageName = packagePath.basename()
                        let destination = packagePath/"Sources"/packageName
                        for entry in try (path/"Sources"/dependency.name).ls() where entry.kind == .file {
                            try entry.path.link(into: destination)
                        }
                    } catch let e {
                        result = .failure(reason: e.localizedDescription)
                    }
                }
            }
        } catch let e {
            result = .failure(reason: e.localizedDescription)
        }
        return result
    }

}

// Public API
public extension NotebookExport {
    // Using different names than fastai's Python version to avoid conflicts for now
    static let defaultPackagePrefix = "ExportedNotebook_"
    
    /// Export as an independent package, prepending the specified prefix to the name
    @discardableResult
    func export(usingPrefix prefix: String = defaultPackagePrefix) -> ExportResult {
        // Create the isolated package
        let packagePath = Path.from(prefix + filepath.basename(dropExtension: true))
        let packageResult = toScript(inside: packagePath)
        guard case .success = packageResult else { return packageResult }
        
        // Should we do this optional?
        return unwrapSourcesFromLocalDependencies(withPrefix: prefix, inside: packagePath)
    }
    
    init(_ filepath: Path) {
        self.filepath = filepath
    }
    
    init(_ filename: String) {
        self.init(Path.from(filename))
    }

}
