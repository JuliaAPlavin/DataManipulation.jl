### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 6a38ae1a-4097-11ed-19f7-5b18b3fa3617
using DataManipulation
# Several functions are defined in `DataManipulation` directly. They can be split into other packages at some point, if considered useful not only for interactive work. These include:
# - `findonly`: like `findfirst`, but ensures that exactly a single match is present;
# - `filterfirst`, `filteronly`: more efficient `first(filter(f, X))` and `only(filter(f, X))`;
# - `uniqueonly`: more efficient `only(unique([f], X))`;
# - `mapset`, `mapinsert`, `mapsetview`, `mapinsertview`: generalized set/insert a table column, eg `mapset(a=x -> x.b^2, xs)` is equivalent to `map(x -> @set(x.a=x.b^2), xs)` and supports multiple properties as kwargs;
# - `filterview`, `sortview`, `uniqueview`: like `filter`/`sort`/`unique`, but return a view;
# - `collectview`: turn the input into an `AbstractArray`, like `collect` but doesn't copy; useful for general handling of arrays and dictionaries;
# - `materialize_views`: materialize views arbitrarily nested in dictionaries and `StructArray`s;
# - `discreterange`: similar to `maprange(...)`, but return `length` unique integers.


# ╔═╡ ae30f3d7-00e6-40ec-8fd1-dc3e8b736301
xs = [1., 2, 3]

# ╔═╡ cd8d0b6b-46ca-4879-98b0-0ed8aa109ecd
xsm = mapview(exp, xs)

# ╔═╡ 33a9ae56-b6f1-41e7-9d84-5db7410ffc3f
xsm[2] = 1000

# ╔═╡ f5ebb4d0-626a-40ce-89e3-4844005ba340
xs

# ╔═╡ 3ddaf5ee-2694-435e-bc56-2f33d6a354ea


# ╔═╡ 9c2d8a72-a088-4c53-9585-b84a93248579
flatten([[1, 2], [3]])

# ╔═╡ 71586607-b919-4eea-a828-9018f84bfb31
flatmap(i -> 1:i, 1:3)

# ╔═╡ e7eed221-6185-454b-a8ef-648c4534a2d6


# ╔═╡ 9159df12-748d-4da8-95c1-c0487b934858
filtermap(1:10) do x
	y = x^2
	sum(1:y) < 10 && return nothing
	y + 1
end

# ╔═╡ 3ab3eb53-88df-4800-82e6-5a8970cc4a2c


# ╔═╡ 7e204430-4f88-4018-8fb2-a34474ad371c
vals = [0, missing, NaN, 1, 2, -1, 5]

# ╔═╡ 08cc856d-fc9e-4ced-90fc-7f4280b28ad9
vals_sm = skip(ismissing, vals)

# ╔═╡ 94493a2b-2187-4c5c-8b5e-f9050ff87a97
eltype(vals_sm)

# ╔═╡ ae2eceb4-1249-435d-b48a-d2b979a84ae9
collect(vals_sm)

# ╔═╡ 0a771457-ccc8-41fe-aeef-93cf7516d565
vals_s = skip(x -> ismissing(x) || isnan(x), vals)

# ╔═╡ a0a5585f-5634-491a-9661-017b9b8df064
eltype(vals_s)

# ╔═╡ a7f1759b-8c79-4421-b179-7a3a327c7f82
collect(vals_s)

# ╔═╡ b8e0949d-4a34-4b15-83fb-8201de7f00b1
vals_s ./= sum(vals_s)

# ╔═╡ 471d2a55-c2e3-4e9c-8c45-0c7a58f5065a
vals

# ╔═╡ 1ff15207-19b3-4f85-b2b9-6fb456b84837


# ╔═╡ 6a4b78d8-c7ed-4ea7-8903-a50d56e55ee9


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataManipulation = "38052440-ad76-4236-8414-61389b2c5143"

[compat]
DataManipulation = "~0.1.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "cf4e738a4846e1a11c799166cf825c8ac9f7e190"

[[deps.Accessors]]
deps = ["Compat", "CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "LinearAlgebra", "MacroTools", "Requires", "Test"]
git-tree-sha1 = "ce67f55da3a937bb001a8d00559bdfa4dba6e4f5"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.20"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Combinatorics]]
git-tree-sha1 = "08c8b6831dc00bfea825826be0bc8336fc369860"
uuid = "861a8166-3701-5b0c-9a16-15d98fcdc6aa"
version = "1.0.2"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "5856d3031cdb1f3b2b6340dfdc66b6d9a149a374"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.2.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.CompositionsBase]]
git-tree-sha1 = "455419f7e328a1a2493cabc6428d79e951349769"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.1"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "fb21ddd70a051d882a1686a5a550990bbe371a95"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.4.1"

[[deps.DataAPI]]
git-tree-sha1 = "1106fa7e1256b402a86a8e7b15c00c85036fef49"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.11.0"

[[deps.DataManipulation]]
deps = ["DataPipes", "Dictionaries", "FlexiGroups", "FlexiMaps", "InverseFunctions", "Reexport", "SentinelViews", "Skipper", "StructArrays"]
git-tree-sha1 = "8eacb3eb8b01841ce59ee1a9d8f4d605ac7a09b1"
uuid = "38052440-ad76-4236-8414-61389b2c5143"
version = "0.1.0"

[[deps.DataPipes]]
git-tree-sha1 = "b97559f7b941226df5bfef2893bf71f83cac5c41"
uuid = "02685ad9-2d12-40c3-9f73-c6aeda6a7ff5"
version = "0.3.0"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Dictionaries]]
deps = ["Indexing", "Random", "Serialization"]
git-tree-sha1 = "96dc5c5c8994be519ee3420953c931c55657a3f2"
uuid = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
version = "0.3.24"

[[deps.FlexiGroups]]
deps = ["Combinatorics", "DataPipes", "Dictionaries", "FlexiMaps"]
git-tree-sha1 = "e11c9c10c95faa79e2aa58b8bafac9adb6de6364"
uuid = "1e56b746-2900-429a-8028-5ec1f00612ec"
version = "0.1.5"

[[deps.FlexiMaps]]
deps = ["Accessors", "InverseFunctions"]
git-tree-sha1 = "006f73dc1cf09257f5dc443a047f7f0942803e38"
uuid = "6394faf6-06db-4fa8-b750-35ccc60383f7"
version = "0.1.3"

[[deps.Indexing]]
git-tree-sha1 = "ce1566720fd6b19ff3411404d4b977acd4814f9f"
uuid = "313cdc1a-70c2-5d6a-ae34-0150d3930a38"
version = "1.1.1"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelViews]]
git-tree-sha1 = "c7bff02ae89fd4cd0445bc7973470e830e656334"
uuid = "1c95a9c1-8e3f-460f-8963-106dcc440218"
version = "0.1.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Skipper]]
git-tree-sha1 = "ea4d60da1b785c2cf4cb34e574f4b1d6e2fadeb6"
uuid = "fc65d762-6112-4b1c-b428-ad0792653d81"
version = "0.1.0"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6b7ba252635a5eff6a0b0664a41ee140a1c9e72a"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.4.0"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArraysCore", "Tables"]
git-tree-sha1 = "8c6ac65ec9ab781af05b08ff305ddc727c25f680"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.12"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "2d7164f7b8a066bcfa6224e67736ce0eb54aef5b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.9.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"
"""

# ╔═╡ Cell order:
# ╠═6a38ae1a-4097-11ed-19f7-5b18b3fa3617
# ╠═ae30f3d7-00e6-40ec-8fd1-dc3e8b736301
# ╠═cd8d0b6b-46ca-4879-98b0-0ed8aa109ecd
# ╠═33a9ae56-b6f1-41e7-9d84-5db7410ffc3f
# ╠═f5ebb4d0-626a-40ce-89e3-4844005ba340
# ╠═3ddaf5ee-2694-435e-bc56-2f33d6a354ea
# ╠═9c2d8a72-a088-4c53-9585-b84a93248579
# ╠═71586607-b919-4eea-a828-9018f84bfb31
# ╠═e7eed221-6185-454b-a8ef-648c4534a2d6
# ╠═9159df12-748d-4da8-95c1-c0487b934858
# ╠═3ab3eb53-88df-4800-82e6-5a8970cc4a2c
# ╠═7e204430-4f88-4018-8fb2-a34474ad371c
# ╠═08cc856d-fc9e-4ced-90fc-7f4280b28ad9
# ╠═94493a2b-2187-4c5c-8b5e-f9050ff87a97
# ╠═ae2eceb4-1249-435d-b48a-d2b979a84ae9
# ╠═0a771457-ccc8-41fe-aeef-93cf7516d565
# ╠═a0a5585f-5634-491a-9661-017b9b8df064
# ╠═a7f1759b-8c79-4421-b179-7a3a327c7f82
# ╠═b8e0949d-4a34-4b15-83fb-8201de7f00b1
# ╠═471d2a55-c2e3-4e9c-8c45-0c7a58f5065a
# ╠═1ff15207-19b3-4f85-b2b9-6fb456b84837
# ╠═6a4b78d8-c7ed-4ea7-8903-a50d56e55ee9
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
