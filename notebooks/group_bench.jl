### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 2e7eec24-1b69-49d3-80ae-233873bfbc3f
using DataPipes

# ╔═╡ 2023726f-c64f-4ca5-be95-e3c4ba2ccbfb
using Dictionaries

# ╔═╡ f6e2233d-85fa-47e5-ba32-25af03b89abe
using StatsBase

# ╔═╡ 1af60db5-493d-4112-8142-09b6da29fbd7
using BenchmarkTools

# ╔═╡ ffc5026d-c3bd-469d-a13e-6be0093af522
using ProfileCanvas

# ╔═╡ f8e11e54-29e8-451f-a864-187161fb250d


# ╔═╡ 089e4520-67c7-41e9-b433-28e72f311049
tbl = [(a=rand(1:10), b=rand(1:1000), c=rand(1:10^15)) for _ in 1:10^5]

# ╔═╡ e78525dd-acfe-48c2-8445-71c754b8614a
fgr = x -> x.c

# ╔═╡ 27dacf95-27c1-4d25-9ccd-6330a5e3fc65
map([x -> x.a, x -> x.b, x -> x.c]) do f
	println("SAC")
	@btime @p $tbl |> SAC.group($f) |> pairs |> map(((k, gr),) -> (;k, l=length(gr)))
	println("My")
	@btime @p $tbl |> group($f) |> pairs |> map(((k, gr),) -> (;k, l=length(gr)))
	println("My Dict")
	@btime @p $tbl |> group($f; dicttype=Dict) |> pairs |> Iterators.map(identity) |> map(((k, gr),) -> (;k, l=length(gr)))
end

# ╔═╡ 1c545a87-129e-4976-8e57-26bdfb52507d
map([x -> x.a, x -> x.b, x -> x.c]) do f
	println("SAC")
	@btime @p $tbl |> SAC.groupview($f) |> pairs |> map(((k, gr),) -> (;k, l=length(gr)))
	println("My")
	@btime @p $tbl |> groupview($f) |> pairs |> map(((k, gr),) -> (;k, l=length(gr)))
	println("My Dict")
	@btime @p $tbl |> groupview($f; dicttype=Dict) |> pairs |> Iterators.map(identity) |> map(((k, gr),) -> (;k, l=length(gr)))
end

# ╔═╡ 99a20136-244d-4461-a469-1e26a60321bd


# ╔═╡ d1d584d4-b7ee-4ece-910e-4c6b1ffa3b91
_group_core(f, X, vals; dicttype=Dictionary) = _group_core(f, X, vals, dicttype)

# ╔═╡ 292a317c-ecd2-4b03-b69e-91010a885f8e


# ╔═╡ 1325e1e5-079f-477e-895e-af0e47f8a89e
_eltype(::T) where {T} = _eltype(T)

# ╔═╡ ca6f325e-3322-4c3b-8d28-4b467cb903fb
function _eltype(::Type{T}) where {T}
    ETb = eltype(T)
    ETb != Any && return ETb
    # Base.eltype returns Any for mapped/flattened/... iterators
    # here we attempt to infer a tighter type
    ET = Core.Compiler.return_type(first, Tuple{T})
    ET === Union{} ? Any : ET
end

# ╔═╡ 134b6a3b-7d44-40f5-b9c0-b5fdf052d1b9
_valtype(X) = _eltype(values(X))

# ╔═╡ e021dd30-9f64-45cf-9b33-b61b07dfa0c9
function _group_core(f, X::AbstractArray, vals::AbstractArray, ::Type{dicttype}) where {dicttype}
    ngroups = 0
    groups = similar(X, Int)
    dct = dicttype{Core.Compiler.return_type(f, Tuple{_valtype(X)}), Int}()
    @inbounds for (i, x) in pairs(X)
        groups[i] = gid = get!(dct, f(x), ngroups + 1)
        if gid == ngroups + 1
            ngroups += 1
        end
    end

    starts = zeros(Int, ngroups)
    @inbounds for gid in groups
        starts[gid] += 1
    end
    cumsum!(starts, starts)
    push!(starts, length(groups))

    rperm = similar(vals, Base.OneTo(length(vals)))
    # rperm = Vector{_eltype(vals)}(undef, length(X))
    @inbounds for (v, gid) in zip(vals, groups)
        rperm[starts[gid]] = v
        starts[gid] -= 1
    end

    # dct: key -> group_id
    # rperm[starts[group_id + 1]:-1:1 + starts[group_id]] = group_values

    return (; dct, starts, rperm)
end

# ╔═╡ ba77ae70-85c9-4001-83c2-dc069f93d68d


# ╔═╡ d9d55cfd-6c0a-4276-9562-85b4588e2edf
mapvalues(f, dict::AbstractDictionary) = map(f, dict)

# ╔═╡ 075b8a65-b78c-4577-9169-03aa76c778c3
function _setproperties(d::Dict, patch::NamedTuple{(:vals,)})
    K = keytype(d)
    V = eltype(patch.vals)
    @assert length(d.keys) == length(patch.vals)
    Dict{K,V}(d.slots, d.keys, patch.vals, d.ndel, d.count, d.age, d.idxfloor, d.maxprobe)
end

# ╔═╡ 800f94bb-23c1-4edb-9305-8f121e184e62
function mapvalues(f, dict::Dict)
    V = Core.Compiler.return_type(f, Tuple{valtype(dict)})
    vals = dict.vals
    newvals = similar(vals, V)
    @inbounds for i in dict.idxfloor:lastindex(vals)
        if Base.isslotfilled(dict, i)
            newvals[i] = f(vals[i])
        end
    end
    _setproperties(dict, (;vals=newvals))
end

# ╔═╡ de2d1dde-5c00-4f49-b1bc-f14156598a8d
function groupfind(f, X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        @view rperm[starts[gid + 1]:-1:1 + starts[gid]]
    end
end

# ╔═╡ c9f42f7d-620e-4529-950c-15738c9da711
function groupview(f, X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        ix = @view rperm[starts[gid + 1]:-1:1 + starts[gid]]
        @view X[ix]
    end
end

# ╔═╡ 43a719b6-4f0f-4b29-946b-316ac716b3d4
function group(f, X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, values(X); kwargs...)
    mapvalues(dct) do gid
        @view rperm[starts[gid + 1]:-1:1 + starts[gid]]
    end
end

# ╔═╡ 2c098c8e-cfe0-4fff-b3b5-7c56231ffc65
function groupmap(f, ::typeof(length), X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, similar(X, Nothing); kwargs...)
    mapvalues(dct) do gid
        starts[gid + 1] - starts[gid]
    end
end

# ╔═╡ cf16545e-a409-48d4-98ab-93aa3951b75d
function groupmap(f, ::typeof(first), X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        ix = rperm[starts[gid + 1]]
        X[ix]
    end
end

# ╔═╡ c7e33758-8983-493e-8184-08545dc26835
function groupmap(f, ::typeof(last), X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        ix = rperm[1 + starts[gid]]
        X[ix]
    end
end

# ╔═╡ fcf1f47c-7f30-46d0-aa87-8302cd86362b
function groupmap(f, ::typeof(only), X; kwargs...)
    (; dct, starts, rperm) = _group_core(f, X, keys(X); kwargs...)
    mapvalues(dct) do gid
        starts[gid + 1] == starts[gid] + 1 || throw(ArgumentError("groupmap(only, X) requires that each group has exactly one element"))
        ix = rperm[starts[gid + 1]]
        X[ix]
    end
end

# ╔═╡ c977bd4c-a861-4973-a3a7-d2a26412f7c4


# ╔═╡ f37c6114-30ee-11ed-00cc-1d35875cc46b
import SplitApplyCombine as SAC

# ╔═╡ 8c8ac28b-9096-47bf-a54e-2c926371622d
map([x -> x.a, x -> x.b, x -> x.c]) do f
	println("SAC")
	@btime SAC.group($f, $tbl)
	println("My")
	@btime group($f, $tbl)
	println("My Dict")
	@btime group($f, $tbl; dicttype=Dict)
end

# ╔═╡ 2a613f12-89ed-46aa-8132-125455ffe81a
map([x -> x.a, x -> x.b, x -> x.c]) do f
	println("StatsBase")
	@btime countmap($(map(f, tbl)))
	println("SAC")
	@btime SAC.groupcount($f, $tbl)
	println("My")
	@btime groupmap($f, length, $tbl)
	println("My Dict")
	@btime groupmap($f, length, $tbl; dicttype=Dict)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
DataPipes = "02685ad9-2d12-40c3-9f73-c6aeda6a7ff5"
Dictionaries = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
ProfileCanvas = "efd6af41-a80b-495e-886c-e51b0c7d77a3"
SplitApplyCombine = "03a91e81-4c3e-53e1-a0a4-9c0c8f19dd66"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"

[compat]
BenchmarkTools = "~1.3.1"
DataPipes = "~0.3.0"
Dictionaries = "~0.3.24"
ProfileCanvas = "~0.1.4"
SplitApplyCombine = "~1.2.2"
StatsBase = "~0.33.21"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "a001eb21bddb77b9b503e134f95746d2c3619b73"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "4c10eee4af024676200bc7752e536f858c6b8f93"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "8a494fe0c4ae21047f28eb48ac968f0b8a6fcaa7"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.4"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "5856d3031cdb1f3b2b6340dfdc66b6d9a149a374"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.2.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataPipes]]
git-tree-sha1 = "b97559f7b941226df5bfef2893bf71f83cac5c41"
uuid = "02685ad9-2d12-40c3-9f73-c6aeda6a7ff5"
version = "0.3.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Dictionaries]]
deps = ["Indexing", "Random", "Serialization"]
git-tree-sha1 = "96dc5c5c8994be519ee3420953c931c55657a3f2"
uuid = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
version = "0.3.24"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "5158c2b41018c5f7eb1470d558127ac274eca0c9"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.1"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

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

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "94d9c52ca447e23eac0c0f074effbcd38830deb5"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.18"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "3d5bf43e3e8b412656404ed9466f1dcbf7c50269"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.4.0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.ProfileCanvas]]
deps = ["Base64", "JSON", "Pkg", "Profile", "REPL"]
git-tree-sha1 = "8fc50fe9b7a9a7425986c5709b2064775196bca7"
uuid = "efd6af41-a80b-495e-886c-e51b0c7d77a3"
version = "0.1.4"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SplitApplyCombine]]
deps = ["Dictionaries", "Indexing"]
git-tree-sha1 = "48f393b0231516850e39f6c756970e7ca8b77045"
uuid = "03a91e81-4c3e-53e1-a0a4-9c0c8f19dd66"
version = "1.2.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╠═f8e11e54-29e8-451f-a864-187161fb250d
# ╠═089e4520-67c7-41e9-b433-28e72f311049
# ╠═e78525dd-acfe-48c2-8445-71c754b8614a
# ╠═8c8ac28b-9096-47bf-a54e-2c926371622d
# ╠═27dacf95-27c1-4d25-9ccd-6330a5e3fc65
# ╠═1c545a87-129e-4976-8e57-26bdfb52507d
# ╠═2a613f12-89ed-46aa-8132-125455ffe81a
# ╠═99a20136-244d-4461-a469-1e26a60321bd
# ╠═de2d1dde-5c00-4f49-b1bc-f14156598a8d
# ╠═c9f42f7d-620e-4529-950c-15738c9da711
# ╠═43a719b6-4f0f-4b29-946b-316ac716b3d4
# ╠═2c098c8e-cfe0-4fff-b3b5-7c56231ffc65
# ╠═cf16545e-a409-48d4-98ab-93aa3951b75d
# ╠═c7e33758-8983-493e-8184-08545dc26835
# ╠═fcf1f47c-7f30-46d0-aa87-8302cd86362b
# ╠═d1d584d4-b7ee-4ece-910e-4c6b1ffa3b91
# ╠═e021dd30-9f64-45cf-9b33-b61b07dfa0c9
# ╠═292a317c-ecd2-4b03-b69e-91010a885f8e
# ╠═1325e1e5-079f-477e-895e-af0e47f8a89e
# ╠═ca6f325e-3322-4c3b-8d28-4b467cb903fb
# ╠═134b6a3b-7d44-40f5-b9c0-b5fdf052d1b9
# ╠═ba77ae70-85c9-4001-83c2-dc069f93d68d
# ╠═d9d55cfd-6c0a-4276-9562-85b4588e2edf
# ╠═800f94bb-23c1-4edb-9305-8f121e184e62
# ╠═075b8a65-b78c-4577-9169-03aa76c778c3
# ╠═c977bd4c-a861-4973-a3a7-d2a26412f7c4
# ╠═2e7eec24-1b69-49d3-80ae-233873bfbc3f
# ╠═f37c6114-30ee-11ed-00cc-1d35875cc46b
# ╠═2023726f-c64f-4ca5-be95-e3c4ba2ccbfb
# ╠═f6e2233d-85fa-47e5-ba32-25af03b89abe
# ╠═1af60db5-493d-4112-8142-09b6da29fbd7
# ╠═ffc5026d-c3bd-469d-a13e-6be0093af522
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
