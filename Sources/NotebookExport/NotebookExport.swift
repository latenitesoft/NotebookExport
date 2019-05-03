import Foundation
import Path


public struct NotebookExport {
    let filepath: Path
    
    var scriptName: String { return filepath.basename(dropExtension: true) + ".swift" }
    
    public enum NotebookExportError: Error {
        case unexpectedNotebookFormat
    }
    
    //FIXME: hide these regexps elsewhere
    
    let exportRegexp = NSRegularExpression(#"^\s*//\s*export\s*$"#)

    // //executable: printMNISTShape
    let executableRegexp = NSRegularExpression(#"^\s*//\s*executable\s+([^\s]+)\s*$"#)

    // %install '.package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1")' Path
    let installRegexp = NSRegularExpression(#"^\s*%install '(.*)'\s(.*)$"#)

    struct CellSource {
        var name: String? = nil     // a CellSource may or may not have an associated name
        var lines: [String]
        
        init(name: String?, lines: [String]) {
            self.name = name
            self.lines = lines
        }
        
        init(lines: [String]) {
            self.init(name:nil, lines:lines)
        }
    }
    
    /// Parse the notebook and selects the cells of interest,
    /// returning the content filtered and transformed by the supplied closure.
    /// Parsed data is not cached, so multiple calls will read from the document again.
    func processCells(contentTransform: (_ rawSource: [String]) -> CellSource?) throws -> [CellSource] {
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
        let selectedSources: [CellSource] = cells.compactMap { cell in
            guard let source = cell["source"] as? [String] else { return nil }
            return contentTransform(source)     // nil to ignore this cell
        }
        
        return selectedSources
    }

    /// Parse the notebook and extract the source of the exportable cells (minus the comment line).
    /// Parsed data is not cached.
    func extractExportableSources() throws -> [CellSource] {
        return try processCells { source in
            guard exportRegexp.matches(source.first) else { return nil }
            return CellSource(lines: Array(source[1...]))
        }
    }

    /// Parse the notebook and extract the source of the install cells.
    /// Parsed data is not cached.
    func extractInstallableSources() throws -> [CellSource] {
        return try processCells { source in
            for line in source {
                if installRegexp.matches(line) { return CellSource(lines: source) }
            }
            return nil
        }
    }
    
    /// Parse the notebook and extract the source of the executable cells,
    /// alongside the executable names.
    /// Parsed data is not cached.
    func extractExecutableSources() throws -> [CellSource] {
        return try processCells { source in
            guard let executableName = executableRegexp.groupsOfFirstMatch(in: source.first)?.first else { return nil }
            return CellSource(name: executableName, lines: Array(source[1...]))
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
            for line in cellSource.lines {
                dependencies.append(contentsOf: dependencyFromInstallLine(line))
            }
        }
        return dependencies
    }

    /// Update global Package.swift
    func updatePackageSpec(at path: Path, packageName: String, dependencies: [DependencyDescription]) throws {
        let packageManifest = PackageManifest(packagePath: path, dependencies: dependencies)
        let manifest = packageManifest.manifest
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
        let packageName = packagePath.basename()
        let destination = packagePath/"Sources"/packageName/scriptName
        do {
            var module = """
            /*
            THIS FILE WAS AUTOGENERATED! DO NOT EDIT!
            file to edit: \(filepath.basename())
            
            */
            
            """
            for cellSource in try extractExportableSources() {
                module.append("\n" + cellSource.lines.joined() + "\n")
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
    
    /// Copy sources from previously exported notebooks this one explicitly depends on.
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
                            try entry.path.copy(into: destination, overwrite: true)
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

    /// Update this notebook's source into other notebooks that use it.
    func updatePackages(withPrefix prefix: String, fromPackage packagePath: Path) -> ExportResult {
        let scriptSource = packagePath/"Sources"/packagePath.basename()/scriptName
        var currentTargetPath: Path? = nil
        do {
            for entry in try (packagePath.parent).ls() where entry.kind == .directory && entry.path.basename().hasPrefix(prefix) {
                if entry.path == packagePath { continue }
                let packageName = entry.path.basename()
                let targetNotebookPath = (entry.path)/"Sources"/packageName/scriptName
                currentTargetPath = targetNotebookPath
                guard targetNotebookPath.exists else { continue }
                
                try scriptSource.copy(to: targetNotebookPath, overwrite: true)
            }
        } catch let e {
            return .failure(reason: e.localizedDescription + "\n" + "Attempting to copy \(scriptSource) to \(String(describing: currentTargetPath))")
        }
        return .success
    }
}

// Public API
public extension NotebookExport {
    static let version = "0.5.0"
    static let defaultPackagePrefix = "FastaiNotebook_"

    /// Export as an independent package, prepending the specified prefix to the name
    @discardableResult
    func export(usingPrefix prefix: String = defaultPackagePrefix) -> ExportResult {
        // Create the isolated package
        let packagePath = Path.from(prefix + filepath.basename(dropExtension: true))
        let packageResult = toScript(inside: packagePath)
        guard case .success = packageResult else { return packageResult }
        
        let unwrapResult = unwrapSourcesFromLocalDependencies(withPrefix: prefix, inside: packagePath)
        guard case .success = unwrapResult else { return unwrapResult }
        
        return updatePackages(withPrefix: prefix, fromPackage: packagePath)
    }
    
    init(_ filepath: Path) {
        self.filepath = filepath
    }
    
    init(_ filename: String) {
        self.init(Path.from(filename))
    }

}
