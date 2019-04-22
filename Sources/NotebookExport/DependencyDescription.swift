// DependencyDescription

// It would be nice if we could use SPM's PackageDescription to parse and generate Package.swift.
// I didn't find an easy way to do it. Building the package manager as a library seems too much.
struct DependencyDescription {
    let name: String
    let procedency: Procedency
    
    enum VersionSpec {
        case from(_ tag: String)
        //TODO: Add others
        
        var description: String {
            switch self {
            case .from(let tag): return "from: \(tag.quoted)"
            }
        }
    }
    
    enum Procedency {
        case local(path: String)
        case remote(url: String, version: VersionSpec)
        case rawSpec(spec: String)
        
        var description: String {
            switch self {
            case .local(let path): return "path: \(path)"
            case .remote(let url, let version): return "url: \(url.quoted), \(version.description)"
            case .rawSpec(let spec): return spec
            }
        }
    }
    
    var description: String {
        return ".package(\(self.procedency.description))"
    }
    
    init(name: String, procedency: Procedency) {
        self.name = name
        self.procedency = procedency
    }
    
    init(name: String, rawSpec spec: String) {
        self.init(name: name, procedency: .rawSpec(spec: spec))
    }
}
