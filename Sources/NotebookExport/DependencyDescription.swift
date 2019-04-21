// DependencyDescription

// It would be nice if we could use SPM's PackageDescription to parse and generate Package.swift.
// I didn't find an easy way to do it. Building the package manager as a library seems too much.
struct DependencyDescription {
    let name: String
    let procedency: Procedency
    
    /* Defaults, for testing */
    static let path = DependencyDescription(name: "Path",
                                            procedency: .remote(
                                                url:     "https://github.com/mxcl/Path.swift",
                                                version: .from("0.16.1")))
    static let just = DependencyDescription(name: "Just",
                                            procedency: .remote(
                                                url:     "https://github.com/JustHTTP/Just",
                                                version: .from("0.7.1")))
    static let defaults = [path, just]
    
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
        
        var description: String {
            switch self {
            case .local(let path): return "path: \(path)"
            case .remote(let url, let version): return "url: \(url.quoted), \(version.description)"
            }
        }
    }
    
    var description: String {
        return ".package(\(self.procedency.description))"
    }
    
    
}
