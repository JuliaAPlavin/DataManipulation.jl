### A Pluto.jl notebook ###
# v0.19.11

using Markdown
using InteractiveUtils

# ╔═╡ 7e7707a6-6bb5-4e20-a867-98dcd359dea1
using BenchmarkTools

# ╔═╡ 66ee434c-b6d0-46c6-9ebf-b548978ad6d5
using Dictionaries

# ╔═╡ 2ab6da2c-2c7d-477b-a336-89cfb05c57f8
using ProfileCanvas

# ╔═╡ 11f58b35-a882-4e18-a64c-e57050303601
using DataPipes

# ╔═╡ b30128ce-f146-45b1-ae62-d5cf2ccbaa11
using ConstructionBase

# ╔═╡ 74c2c181-00e8-4d65-b3c8-c44ed31a926b
using Accessors

# ╔═╡ 8e799461-2ffe-46e9-9008-35effd0e19ab
dct = Dict(zip(1:10^3, 1:10^3))

# ╔═╡ c4b4712a-bf6c-47fc-9a07-ea5f4a78c8f9
mapvalues_naive(f, dct) = Dict(zip(keys(dct), map(f, values(dct))))

# ╔═╡ 3c57a85f-ea6b-411b-9b00-9a747c805fb2
function mapvalues_copy(f, dct)
	dct_ = copy(dct)
	map!(f, values(dct_))
	dct_
end

# ╔═╡ cb0c69a6-4509-42f7-9a8f-bc925ca8dee6
function mapvalues_vals1(f, dct)
	@modify(dct.vals) do vals
		map(f, vals)
	end
end

# ╔═╡ 26f220aa-69bf-4c3c-80ac-1347016ba06a
mappairs_naive(f, obj::Dict) = Dict(f(p) for p in pairs(obj))

# ╔═╡ ff966cf6-4a8c-4c78-8ffb-dfba181be612
@btime mappairs_naive(((k, v),) -> (k, v + 1), $dct)

# ╔═╡ e9156a19-3bce-4f3d-a792-40fe501c2078
@btime mappairs_naive(((k, v),) -> k + 1 => v + 1, $dct)

# ╔═╡ 90d875d3-2820-49ba-a1fb-4cabcf62e64a


# ╔═╡ ec17707a-a2d7-4f5c-a269-ce8c9c827e3c


# ╔═╡ 80882a46-3c0e-4ae8-a594-d43a6452552b
@btime mapvalues_naive(x -> x + 1, $dct)

# ╔═╡ 18386539-6691-453e-82b4-eb56493a4fa9
@btime mapvalues_copy(x -> x + 1, $dct)

# ╔═╡ 38c8dac8-8ae2-4210-b3eb-9f2e9db26e34
@btime mapvalues_vals1(x -> x + 1, $dct)

# ╔═╡ 1765fd22-4e77-442c-a6ab-7ffb913a8d23


# ╔═╡ 71cbe102-852d-44b6-b9ba-c6e7e90cea71


# ╔═╡ b5aeb319-b190-44cc-b657-82bfd8c9d414
ddct = dictionary(dct)

# ╔═╡ ba40d7f6-4a3d-4146-b714-0861d842b356
@btime map(x -> x + 1, $ddct)

# ╔═╡ 97b7328b-41b3-4c6b-bdef-344c300c8b5e


# ╔═╡ 23775197-1076-4431-9159-78e3465e12f9
@btime collect($ddct)

# ╔═╡ 0a3efe2e-71ec-49d5-8d14-a17255025e31
ddct.values == collect(ddct)

# ╔═╡ 6bc04097-07af-4ccc-9c4c-35e6af5e350c
@btime map(keys($ddct), values($ddct)) do k, v
	k + v
end

# ╔═╡ eaa68c38-902a-491a-b7bd-0fa8f8d2ae25
@btime map(pairs($ddct)) do (k, v)
	(;k, v)
end

# ╔═╡ 388e58ab-50ae-4f50-b684-fdef00c7eccf
@btime map(pairs($ddct)) do (k, v)
	(;k, v)
end.values

# ╔═╡ 11108388-347a-4719-9a0d-5fa3f64f4c1a
@btime map(pairs($ddct)) do (k, v)
	(;k, v)
end |> collect

# ╔═╡ ad5454bb-9f43-4494-abc1-0ad1af7c1eae
@btime map($(collect(pairs(ddct)))) do (k, v)
	(;k, v)
end

# ╔═╡ 58474708-3bd0-4400-baef-419ade66963d
@btime map(collect(pairs($ddct))) do (k, v)
	(;k, v)
end

# ╔═╡ 0dc14e42-acf3-48fa-954b-354c28a1c775


# ╔═╡ 8fe2e214-1305-450a-9d0c-d6bb7069b8bf


# ╔═╡ 46999c78-04c4-45e0-8820-db133c1d2d49


# ╔═╡ a2f17316-2ec9-11ed-0400-514300b27b1a
function autotimed(f; mintime=0.5)
	f()
	T = @timed f()
	T.time > mintime && return (; T.time, T.gctime, T.bytes, nallocs=Base.gc_alloc_count(T.gcstats) / 1, T.value)
	n = 1
	while true
		n *= clamp(mintime / T.time, 1.2, 100)
		T = @timed begin
			for _ in 1:(n-1)
				f()
			end
			f()
		end
		T.time > mintime && return (; time=T.time / n, gctime=T.gctime / n, bytes=T.bytes ÷ n, nallocs=Base.gc_alloc_count(T.gcstats) / n, T.value)
	end
end

# ╔═╡ f4cea5a0-1c61-4760-be24-e1282a7f751a
function ConstructionBase.setproperties(d::Dict{K}, patch::NamedTuple{(:vals,), Tuple{Vector{V}}}) where {K, V}
    @assert length(d.keys) == length(patch.vals)
    Dict{K,V}(d.slots, d.keys, patch.vals, d.ndel, d.count, d.age, d.idxfloor, d.maxprobe)
end

# ╔═╡ c1f9fa7d-7c1c-4d08-8465-4930241e8223
function mapvalues_vals2(f, dct::Dict{K, V}) where {K, V}
	# V = Core.Compiler.return_type(f, Tuple{valtype(dct)})
	vals = dct.vals
	newvals = similar(vals, V)
	@inbounds for i in dct.idxfloor:lastindex(vals)
		if Base.isslotfilled(dct, i)
			newvals[i] = f(vals[i])
		end
	end
	setproperties(dct, vals=newvals)
end

# ╔═╡ c743823f-0a36-4d82-af18-3edd01e7ea5c
@btime mapvalues_vals2(x -> x + 1, $dct)

# ╔═╡ 2a78308e-24f4-489d-b12f-140cc18cf19f
begin
	function mappairs_vals(f, dct)
		KV = Core.Compiler.return_type(f, Tuple{eltype(dct)})
		_mappairs(f, dct, KV)
	end
	
	function _mappairs(f, dct::Dict{K}, ::Type{Pair{K, V}}) where {K, V}
		vals = dct.vals
		newvals = similar(vals, V)
		@inbounds for i in dct.idxfloor:lastindex(vals)
			if Base.isslotfilled(dct, i)
				p = dct.keys[i] => vals[i]
				newp = f(p)
				if newp.first == p.first
					newvals[i] = newp.second
				else
					return _mappairs_different(f, dct::Dict, Pair{K, V})
				end
			end
		end
		setproperties(dct, vals=newvals)
	end
	
	
	function _mappairs_different(f, dct::Dict, ::Type{Pair{K, V}}) where {K, V}
		Dict{K, V}(f(p) for p in dct)
	end
end

# ╔═╡ 479917d8-d00a-47a3-8d3d-ae8be32f73ca
@btime mappairs_vals(((k, v),) -> k => v + 1, $dct)

# ╔═╡ d6518d70-0188-4a85-a149-93accb36757e
@btime mappairs_vals(((k, v),) -> k + 1 => v + 1, $dct)

# ╔═╡ 18a98238-413e-445a-8ce0-d62e8f3f5d83


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Accessors = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
ConstructionBase = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
DataPipes = "02685ad9-2d12-40c3-9f73-c6aeda6a7ff5"
Dictionaries = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
ProfileCanvas = "efd6af41-a80b-495e-886c-e51b0c7d77a3"

[compat]
Accessors = "~0.1.20"
BenchmarkTools = "~1.3.1"
ConstructionBase = "~1.4.1"
DataPipes = "~0.3.0"
Dictionaries = "~0.3.24"
ProfileCanvas = "~0.1.4"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "ddcda892c7d834369e25ed6e522f13fd69369ad9"

[[deps.Accessors]]
deps = ["Compat", "CompositionsBase", "ConstructionBase", "Dates", "InverseFunctions", "LinearAlgebra", "MacroTools", "Requires", "Test"]
git-tree-sha1 = "ce67f55da3a937bb001a8d00559bdfa4dba6e4f5"
uuid = "7d9f7c33-5ae7-4f3b-8dc6-eff91059b697"
version = "0.1.20"

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

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "78bee250c6826e1cf805a88b7f1e86025275d208"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.46.0"

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

[[deps.DataPipes]]
git-tree-sha1 = "b97559f7b941226df5bfef2893bf71f83cac5c41"
uuid = "02685ad9-2d12-40c3-9f73-c6aeda6a7ff5"
version = "0.3.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Dictionaries]]
deps = ["Indexing", "Random", "Serialization"]
git-tree-sha1 = "96dc5c5c8994be519ee3420953c931c55657a3f2"
uuid = "85a47980-9c8c-11e8-2b9f-f7ca1fa99fb4"
version = "0.3.24"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

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

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

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

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

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
# ╠═8e799461-2ffe-46e9-9008-35effd0e19ab
# ╠═c4b4712a-bf6c-47fc-9a07-ea5f4a78c8f9
# ╠═3c57a85f-ea6b-411b-9b00-9a747c805fb2
# ╠═cb0c69a6-4509-42f7-9a8f-bc925ca8dee6
# ╠═c1f9fa7d-7c1c-4d08-8465-4930241e8223
# ╠═26f220aa-69bf-4c3c-80ac-1347016ba06a
# ╠═2a78308e-24f4-489d-b12f-140cc18cf19f
# ╠═7e7707a6-6bb5-4e20-a867-98dcd359dea1
# ╠═ff966cf6-4a8c-4c78-8ffb-dfba181be612
# ╠═e9156a19-3bce-4f3d-a792-40fe501c2078
# ╠═479917d8-d00a-47a3-8d3d-ae8be32f73ca
# ╠═d6518d70-0188-4a85-a149-93accb36757e
# ╠═90d875d3-2820-49ba-a1fb-4cabcf62e64a
# ╠═ec17707a-a2d7-4f5c-a269-ce8c9c827e3c
# ╠═80882a46-3c0e-4ae8-a594-d43a6452552b
# ╠═18386539-6691-453e-82b4-eb56493a4fa9
# ╠═38c8dac8-8ae2-4210-b3eb-9f2e9db26e34
# ╠═c743823f-0a36-4d82-af18-3edd01e7ea5c
# ╠═1765fd22-4e77-442c-a6ab-7ffb913a8d23
# ╠═71cbe102-852d-44b6-b9ba-c6e7e90cea71
# ╠═b5aeb319-b190-44cc-b657-82bfd8c9d414
# ╠═ba40d7f6-4a3d-4146-b714-0861d842b356
# ╠═97b7328b-41b3-4c6b-bdef-344c300c8b5e
# ╠═23775197-1076-4431-9159-78e3465e12f9
# ╠═0a3efe2e-71ec-49d5-8d14-a17255025e31
# ╠═6bc04097-07af-4ccc-9c4c-35e6af5e350c
# ╠═eaa68c38-902a-491a-b7bd-0fa8f8d2ae25
# ╠═388e58ab-50ae-4f50-b684-fdef00c7eccf
# ╠═11108388-347a-4719-9a0d-5fa3f64f4c1a
# ╠═ad5454bb-9f43-4494-abc1-0ad1af7c1eae
# ╠═58474708-3bd0-4400-baef-419ade66963d
# ╠═0dc14e42-acf3-48fa-954b-354c28a1c775
# ╠═8fe2e214-1305-450a-9d0c-d6bb7069b8bf
# ╠═46999c78-04c4-45e0-8820-db133c1d2d49
# ╠═66ee434c-b6d0-46c6-9ebf-b548978ad6d5
# ╠═2ab6da2c-2c7d-477b-a336-89cfb05c57f8
# ╠═11f58b35-a882-4e18-a64c-e57050303601
# ╠═b30128ce-f146-45b1-ae62-d5cf2ccbaa11
# ╠═74c2c181-00e8-4d65-b3c8-c44ed31a926b
# ╠═a2f17316-2ec9-11ed-0400-514300b27b1a
# ╠═f4cea5a0-1c61-4760-be24-e1282a7f751a
# ╠═18a98238-413e-445a-8ce0-d62e8f3f5d83
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
