# NotebookExport

Export cells from Swift for TensorFlow (S4TF) notebooks to Swift Packages.

This is a library intended to run as an installed extension inside a [swift-jupyter](https://github.com/google/swift-jupyter) environment, and is based on [fastai's](http://fast.ai) current export mechanisms for both Python and S4TF Jupyter notebooks.

## Install

Use `swift-jupyter`'s `%install` directives to install this package, alongside any other packages your notebook needs:

```
%install-location $cwd/swift-install
%install '.package(url: "https://github.com/mxcl/Path.swift", from: "0.16.1")' Path
%install '.package(url: "https://github.com/JustHTTP/Just", from: "0.7.1")' Just
%install '.package(url: "https://github.com/latenitesoft/NotebookExport", from: "0.6.0")' NotebookExport
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

### Mark executable cells

You can extract the code in a particular cell as an executable product in the exported package. For example, the following comment will generate a product called `ls` which you can run by issuing the command `swift run ls` inside the exported package directory.

```Swift
//executable ls

print("/bin/ls".shell("-lh"))
```

The generated executable automatically imports the package name (which contains all the code from `export` cells), as well as the libraries installed in `%install` directives. Other non-installed dependencies (TensorFlow, Python) must be imported manually, if required.

Multiple executables can be created this way. Each executable cell should have a different name to create a different target. Merging several executable cells in a single executable target is not supported yet.

### Export cells (default name)

To export all marked cells, import the `NotebookExport` package in your S4TF notebook and use it in notebook cells like so:

```Swift
import Path
import NotebookExport
let exporter = NotebookExport(Path.cwd/"swift-notebook.ipynb")
```

```Swift
print(exporter.export())
```

This exports marked cells from the notebook with the name you specified to a new Swift package with the name `FastaiNotebook_<notebook_name>` (minus the `.ipynb` extension). You can then `%install` that package in other notebooks you are working on.

### Specify custom package prefix

```Swift
print(exporter.export(usingPrefix: "MyProject"))
```

Exports to a package called `MyProject_<notebook_name>`.

### Version

Use `NotebookExport.version` to verify the version installed.

