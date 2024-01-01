# DataManipul

General utilities for conveniently manipulating tabular, quasi-tabular, and non-tabular datasets.

![](https://img.shields.io/badge/motivation-why%3F-brightgreen) 
The goal of `DataManipulation` is to extend the coverage of common data processing functionality on top of base Julia. This package provides more general mapping over datasets, grouping, selecting, reshaping and so on.

`DataManipulation` handles and processes basic data structures already familiar to Julia users and doesn't require switching to custom specialized dataset implementation. All functions stay composable and support a variety of datasets such as arrays, dicts, many table types.

`DataManipulation` functionality consists of two major parts.
- Reexports from focused companion packages that can also be imported separately: `DataPipes`, `FlexiMaps`, `FlexiGroups`, and `Skipper`. Also, currently we reexport `Accessors`, but this may change in the future.
- Functions defined in `DataManipulation` itself: they do not clearly belong to a narrower-scope package, or have not been split out yet. See [docs and usage examples ![](https://img.shields.io/badge/docs-examples-brightgreen?logo=julia)](https://aplavin.github.io/AccessorsExtra.jl/examples/notebook.html).

Additionally, `FlexiJoins` is considered a companion package with relevant goals and API. For now it's somewhat heavy in terms of dependencies and isn't included in `DataManipulation`, but can be added in the future.
