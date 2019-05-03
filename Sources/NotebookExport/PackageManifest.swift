// PackageManifest

import Path

struct PackageManifest {
    var packagePath: Path
    var dependencies: [DependencyDescription]
    var executableNames: [String]

    // Create initializers so executableNames can be skipped
    
    init(packagePath: Path, dependencies: [DependencyDescription], executableNames: [String]) {
        self.packagePath = packagePath
        self.dependencies = dependencies
        self.executableNames = executableNames
    }

    init(packagePath: Path, dependencies: [DependencyDescription]) {
        self.init(packagePath: packagePath, dependencies: dependencies, executableNames: [])
    }

    var packageName: String { return packagePath.basename() }
    
    var executableProducts: String {
        return executableNames.map {
            ".executable(name: \($0.quoted), targets: [\($0.quoted)])"
        }
        .joined(separator: ",\n    ")
    }
    
    var executableTargets: String {
        return executableNames.map {
            ".target(name: \($0.quoted), dependencies: [\(packageName.quoted)])"
        }
        .joined(separator: ",\n    ")
    }

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
        \(executableProducts)
        ],
        dependencies: [
        \(dependencyPackages)
        ],
        targets: [
        .target(name: "\(packageName)", dependencies: [\(dependencyNames)]),
        \(executableTargets)
        ]
        )
        """
        return manifest
    }
}
