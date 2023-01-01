# DataManipulation.jl

General utilities for conveniently manipulating tabular and non-tabular datasets.

`DataManipulation.jl` is primarily intended for interactive use. Most of its functionality is simply reexported from smaller companion packages that can also be imported separately: `DataPipes`, `FlexiMaps`, `FlexiGroups`,  `Skipper` and `SentinelViews`. Also, `FlexiJoins` is considered a companion packages with relevant goals, but for now it's somewhat heavy in terms of dependencies and isn't included in `DataManipulation`.

The aim of `DataManipulation` is to extend the selection of data processing functionality available in base Julia, such as `map`/`filter` and functions from `Iterators`.
This package continue using idioms familiar from base Julia, same basic data structures, conventions. It stays composable with a variety of dataset types such as arrays (including many table types), dicts.

Several functions are defined in `DataManipulation` directly. They aren't well-documented yet, and can be split into other packages at some point. These include:
- `findonly`, `filterfirst`, `filteronly`, `uniqueonly`,
- `mapset`, `mapinsert`, `mapsetview`, `mapinsertview`,
- `filterview`, `sortview`, `uniqueview`,
- `materialize_views`, `collectview`.
See source code and tests for more information on those.
