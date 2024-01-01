# struct Str{S} end
struct StrRe{S} end
struct StrSub{S} end

# macro c_str(x)
# 	:($Str{Symbol($x)}())
# end
macro cr_str(x)
	:($StrRe{Symbol($x)}())
end
macro cs_str(x)
	:($StrSub{Symbol($x)}())
end
