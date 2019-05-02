// PackageManifest

import Path

struct PackageManifest {
    var packagePath: Path
    var dependencies: [DependencyDescription]
    
    var packageName: String { return packagePath.basename() }
    
    var manifest : String {
        let dependencyPackages = (dependencies.map { return $0.spec(relativeTo: packagePath) }).joined(separator: ",\n    ")
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
        return manifest
    }
}
