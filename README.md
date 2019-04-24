# NotebookExport

Export cells from Swift for TensorFlow (S4TF) notebooks to Swift Packages.

This is a library intended to run as an installed extension inside a [swift-jupyter](https://github.com/google/swift-jupyter) environment, and is based on [fastai's](http://fast.ai) current export mechanisms for both Python and S4TF Jupyter notebooks.

## Install

Use `swift-jupyter`'s `%install` directives to install this package, alongside any other packages your notebook needs:

```
%install-location $cwd/swift-install
%install '.package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1")' Path
%install '.package(url: "https://github.com/JustHTTP/Just", from: "0.7.1")' Just
%install '.package(url: "https://github.com/latenitesoft/NotebookExport", .branch("fastai"))' NotebookExport
```

For more details, please refer to [swift-jupyter](https://github.com/google/swift-jupyter) installation and usage guides.

## Usage

### Mark exportable cells

Mark the cells you wish to export with a `//export` comment in the first line of each exportable cell. For example:

```Swift
//export

public func notebookFunction()
{
	/* Code */
}
```

### Export cells as package (default name)

To export all marked cells, import the `NotebookExport` package in your S4TF notebook and use it in notebook cells like so:

```Swift
import Path
import NotebookExport
let exporter = NotebookExport(Path.cwd/"swift-notebook.ipynb")
```

```Swift
print(exporter.export())
```

This exports marked cells from the notebook with the name you specified to a new Swift package with the name `ExportedNotebook_<notebook_name>` (minus the `.ipynb` extension). You can then `%install` that package in other notebooks you are working on.

### Specify custom package prefix

```Swift
print(exporter.export(usingPrefix: "MyProject"))
```

Exports to a package called `MyProject_<notebook_name>`.

