function plural_print(io, num::Number, info::AbstractString; level=0)
    print(io, "\n")
    for _ in 1:level
        print(io, "  ")
    end
    print(io, "$num $info")
    if num != 1
        print(io, "s")
    end
end

