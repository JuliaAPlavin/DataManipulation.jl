macro S_str(str)
    # :(Symbol($(esc(str)))) - simple version without interpolation
    str_interpolated = esc(Meta.parse("\"$(escape_string(str))\""))
    :(Symbol($str_interpolated))
end

(name::Symbol)(x) = getproperty(x, name)
