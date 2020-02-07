// PackageManifest

import Path

struct PackageManifest {
    var packagePath: Path
    var dependencies: [DependencyDescription]
    var executableNames: [String]

    var packageName: String { return packagePath.basename() }

    var executableProducts: String {
        return executableNames.map {
            ".executable(name: \($0.quoted), targets: [\($0.quoted)])"
        }
        .joined(separator: ",\n")
    }

    var executableTargets: String {
        return executableNames.map {
            ".target(name: \($0.quoted), dependencies: [\(packageName.quoted)])"
        }
        .joined(separator: ",\n")
    }

    var manifest : String {
        let dependencyPackages = (dependencies.map { return $0.spec(relativeTo: packagePath) }).joined(separator: ",\n    ")
        let dependencyNames = (dependencies.map { return "\($0.name.quoted)" }).joined(separator: ", ")
        let manifest = """
        // swift-tools-version:5.1
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
