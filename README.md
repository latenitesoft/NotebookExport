# NotebookExport

Export cells from Swift for TensorFlow (S4TF) notebooks to Swift Packages.

This is a library intended to run as an installed extension inside a [swift-jupyter](https://github.com/google/swift-jupyter) environment, and is based on [fastai's](http://fast.ai) current export mechanisms for both Python and S4TF Jupyter notebooks.

## Install

Use `swift-jupyter`'s `%install` directives to install this package, alongside any other packages your notebook needs:

```
%install-location $cwd/swift-install
%install '.package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1")' Path
%install '.package(url: "https://github.com/JustHTTP/Just", from: "0.7.1")' Just
%install '.package(url: "https://github.com/latenitesoft/NotebookExport")' NotebookExport
```

For more details, please refer to [swift-jupyter](https://github.com/google/swift-jupyter) installation and usage guides.

## Usage

### Mark exportable cells

Mark the cells you wish to export with a `//export` comment in the first line of each exportable cell. For example:

```Swift
//export
@discardableResult
public func shellCommand(_ launchPath: String, _ arguments: [String]) -> String
{
    let task = Process()
    task.executableURL = URL(fileURLWithPath: launchPath)
    task.arguments = arguments

    let pipe = Pipe()
    task.standardOutput = pipe
    do {
        try task.run()
    } catch {
        print("Unexpected error: \(error).")
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: String.Encoding.utf8) ?? ""
}
```

### Export cells (default paths)

To export all marked cells, import the `NotebookExport` package in your S4TF notebook and use it in notebook cells like so:

```Swift
import Path
import NotebookExport
let exporter = NotebookExport(Path.cwd/"swift-notebook.ipynb")
```

```Swift
print(exporter.toPackage())
```

`toPackage()` exports marked cells from the notebook with the name you specified to a new Swift package with the name `ExportedNotebook_<notebook_name>` (minus the `.ipynb` extension). You can then `%install` that package in other notebooks you are working on.

```Swift
print(exporter.toScript())
```

`toScript()` adds the exportable cells from the notebook as a source Swift file inside the package `ExportedNotebooks`, which may already exist. You can add multiple scripts to the package as you work on a particular task. Importing that package (in another notebook, or in a different Swift environment altogether) will allow you to reuse the code from all the notebooks you exported from.

To perform both operations, simply use the `export` convenience function:

```Swift
print(exporter.export())
```

### Specify destinations

```Swift
print(exporter.toPackage(prefix: "MyProject"))
```

Creates `MyProject_<notebook_name>` package.

```Swift
print(exporter.toScript(inside: "MySwiftNotebooks"))
```

Adds the source code of the notebook's exported cells to a `MySwiftNotebooks` package, which may already exist.

```Swift
print(exporter.toScript(inside: "MySwiftNotebooks", independentPackagePrefix: "MyProject"))
```

