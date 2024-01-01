# DataManipulation.jl

General and composable utilities for manipulating tabular, quasi-tabular, and non-tabular datasets.

![](https://img.shields.io/badge/motivation-why%3F-brightgreen) Base Julia provides the most foundational building blocks for data processing, such as `map` and `filter` functions. The goal of `DataManipulation` is to extend common data processing functionality on top of that. This package provides more general mapping over datasets, grouping, selecting, reshaping and so on.

`DataManipulation` handles basic data structures already familiar to Julia users and doesn't require switching to custom specialized dataset types. All functions aim to stay composable and support datasets represented as Julia collections: arrays, dictionaries, tuples, many `Tables` types, ... .

*Note* This package is intended primarily for interactive usage: load `DataManipulation` and get access to a wide range of data processing tools. Other packages should prefer depending on individual packages listed below, when possible. Nevertheless, `DataManipulation` follows semver and is well-tested.

![](https://img.shields.io/badge/components-what's%20inside%3F-brightgreen) `DataManipulation` functionality consists of two major parts.
- Reexports from companion packages, each focused on a single area. These packages are designed so that they work together nicely and provide consistent and uniform interfaces:
    - [DataPipes.jl](https://gitlab.com/aplavin/DataPipes.jl): boilerplate-free piping for data manipulation
    - [FlexiMaps.jl](https://gitlab.com/aplavin/FlexiMaps.jl): functions such as `flatmap`, `filtermap`, and `mapview`, extending the all-familiar `map`
    - [FlexiGroups.jl](https://gitlab.com/aplavin/FlexiGroups.jl): group data by arbitrary keys & more
    - [Skipper.jl](https://gitlab.com/aplavin/Skipper.jl): `skip(predicate, collection)`, a generalization of `skipmissing`
    - [Accessors.jl](https://github.com/JuliaObjects/Accessors.jl): modify nested data structures conveniently with optics

  See the docs of these packages for more details.

  Additionally, [FlexiJoins.jl](https://gitlab.com/aplavin/FlexiJoins.jl) is considered a companion package with relevant goals and compatible API. For now it's somewhat heavy in terms of dependencies and isn't included in `DataManipulation`, but can be added in the future.

- Functions defined in `DataManipulation` itself: they do not clearly belong to a narrower-scope package, or just have not been split out yet. See the docstrings for details.
  - `findonly`, `filteronly`, `filterfirst`, `uniqueonly`: functions with the semantics of corresponding Base function combinations, but more efficient and naturally support `Accessors.set`.
  - `sortview`, `uniqueview`, `collectview`: non-copying versions of corresponding Base functions.
  - zero-cost property selection, indexing, and nesting by regex: `sr"regex"` literal, `nest` function
  - And more: `discreterange`, `shift_range`, `rev`


# Featured example
```julia
using DataManipulation

# let's say you have this raw table, probably read from a file:
julia> data_raw = [(; t_a=rand(), t_b=rand(), t_c=rand(), id=rand(1:5), i) for i in 1:10]
10-element Vector{...}:
 (t_a = 0.18651300247498126, t_b = 0.17891408921013918, t_c = 0.25088919057346093, id = 4, i = 1)
 (t_a = 0.008638783104697567, t_b = 0.2725301420722497, t_c = 0.3731421925708567, id = 1, i = 2)
 (t_a = 0.9263839548209668, t_b = 0.043017734093856785, t_c = 0.35927442939296217, id = 2, i = 3)
 ...

# we want to work with `t_a,b,c` values from the table, but it's not very convenient as-is:
# they are mixed with other unrelated columns, `id` and `i`
# let's gather all `t`s into one place by nesting another namedtuple:
julia> data_1 = @p data_raw |> map(nest(_, sr"(t)_(\w+)"))
10-element Vector{...}:
 (t = (a = 0.18651300247498126, b = 0.17891408921013918, c = 0.25088919057346093), id = 4, i = 1)
 (t = (a = 0.008638783104697567, b = 0.2725301420722497, c = 0.3731421925708567), id = 1, i = 2)
 (t = (a = 0.9263839548209668, b = 0.043017734093856785, c = 0.35927442939296217), id = 2, i = 3)
 ...

# much better!
# in practice, all related steps can be written into a single pipeline @p ...,
# here, we split them to demonstrate individual functions

# for the sake of example, let's normalize all `t`s to sum to 1 for each row:
julia> data_2 = @p data_1 |> mapset(t=Tuple(_.t) ./ sum(_.t))
10-element Vector{...}:
 (t = (0.3026254665729048, 0.29029589897330355, 0.40707863445379167), id = 4, i = 1)
 (t = (0.013202867673153734, 0.4165146131252091, 0.5702825192016372), id = 1, i = 2)
 (t = (0.6972233052557745, 0.0323763884223678, 0.27040030632185774), id = 2, i = 3)
 ...

# finally, let's find the maximum over all `t`s for each `id`
# we'll demonstrate two approaches leading to the same result here

# group immediately, then aggregate individual `t`s for each group at two levels - within row, and among rows:
julia> @p data_2 |> group(_.id) |> map(gr -> maximum(r -> maximum(r.t), gr))
5-element Dictionaries.Dictionary{Int64, Float64}
 1 │ 0.5702825192016372
 2 │ 0.6972233052557745
 3 │ 0.8107403478840245
 4 │ 0.4865089865249148
 5 │ 0.44064846734993746

# alternatively, flatten `t` first into a flat column, then group and aggregate at a single level:
julia> data_2_flat = @p data_2 |> flatmap(_.t, (;_..., t=_2))
30-element Vector{...}:
 (t = 0.3026254665729048, id = 4, i = 1)
 (t = 0.29029589897330355, id = 4, i = 1)
 (t = 0.40707863445379167, id = 4, i = 1)
 (t = 0.013202867673153734, id = 1, i = 2)
 ...
julia> @p data_2_flat |> group(_.id) |> map(gr -> maximum(r -> r.t, gr))
5-element Dictionaries.Dictionary{Int64, Float64}
 1 │ 0.5702825192016372
 2 │ 0.6972233052557745
 3 │ 0.8107403478840245
 4 │ 0.4865089865249148
 5 │ 0.44064846734993746
```
