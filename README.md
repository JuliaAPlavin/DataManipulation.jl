# DataManipulation.jl

General utilities for conveniently manipulating tabular and non-tabular datasets.

`DataManipulation.jl` is primarily intended for interactive use. Most of its functionality is simply reexported from self-contained companion packages that can also be imported separately: `DataPipes`, `FlexiMaps`, `FlexiGroups`,  `Skipper` and `SentinelViews`. Additionally, `FlexiJoins` is considered a companion packages with relevant goals, but for now it's somewhat heavy in terms of dependencies and isn't included in `DataManipulation`.

The aim of `DataManipulation` is to extend the selection of data processing functionality available in base Julia. This package provides more general mapping over datasets, grouping of those, and so on. `DataManipulation` continues using the basic data structures already familiar to Julia users and doesn't require switching to custom specialized dataset types. All functions stay composable and support a variety of dataset types such as arrays, dicts, and many table types.

Several functions are defined in `DataManipulation` directly. They can be split into other packages at some point, if considered useful not only for interactive work. These include:
- `findonly`: like `findfirst`, but ensures that exactly a single match is present;
- `filterfirst`, `filteronly`: more efficient `first(filter(f, X))` and `only(filter(f, X))`;
- `uniqueonly`: more efficient `only(unique([f], X))`;
- `mapset`, `mapinsert`, `mapsetview`, `mapinsertview`: generalized set/insert a table column, eg `mapset(a=x -> x.b^2, xs)` is equivalent to `map(x -> @set(x.a=x.b^2), xs)` and supports multiple properties as kwargs;
- `filterview`, `sortview`, `uniqueview`: like `filter`/`sort`/`unique`, but return a view;
- `collectview`: turn the input into an `AbstractArray`, like `collect` but doesn't copy; useful for general handling of arrays and dictionaries;
- `materialize_views`: materialize views arbitrarily nested in dictionaries and `StructArray`s;
- `discreterange`: similar to `maprange(...)`, but return `length` unique integers.
