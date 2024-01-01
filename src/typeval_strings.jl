# struct Str{S} end
struct StaticRegex{S} end
struct StaticSubstitution{S} end

# macro c_str(x)
# 	:($Str{Symbol($x)}())
# end
macro sr_str(x)
	:($StaticRegex{Symbol($x)}())
end
macro ss_str(x)
	:($StaticSubstitution{Symbol($x)}())
end

unstatic(::Type{StaticRegex{S}}) where {S} = Regex(String(S))
unstatic(::Type{StaticSubstitution{S}}) where {S} = SubstitutionString(String(S))