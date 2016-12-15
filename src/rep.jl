# This file includes code that was formerly a part of Julia. License is MIT: http://julialang.org/license

immutable RepString <: AbstractString
    string::AbstractString
    repeat::Integer
end

function endof(s::RepString)
    e = endof(s.string)
    (next(s.string,e)[2]-1) * (s.repeat-1) + e
end
length(s::RepString) = length(s.string)*s.repeat
sizeof(s::RepString) = sizeof(s.string)*s.repeat

function next(s::RepString, i::Int)
    if i < 1
        throw(BoundsError(s, i))
    end
    e = endof(s.string)
    sz = next(s.string,e)[2]-1

    r, j = divrem(i-1, sz)
    j += 1

    if r >= s.repeat || j > e
        throw(BoundsError(s, i))
    end

    c, k = next(s.string, j)
    c, k-j+i
end

convert(::Type{RepString}, s::AbstractString) = RepString(s,1)
