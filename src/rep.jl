# This file includes code that was formerly a part of Julia. License is MIT: http://julialang.org/license

struct RepString <: AbstractString
    string::AbstractString
    repeat::Integer
end

function lastindex(s::RepString)
    e = lastindex(s.string)
    (iterate(s.string,e)[2]-1) * (s.repeat-1) + e
end
length(s::RepString) = length(s.string)*s.repeat
sizeof(s::RepString) = sizeof(s.string)*s.repeat

function isvalid(s::RepString, i::Int)
    1 ≤ i ≤ ncodeunits(s) || return false
    j = 1
    while j < i
        _, j = iterate(s, j)
    end
    return j == i
end

function next(s::RepString, i::Int)
    if i < 1
        throw(BoundsError(s, i))
    end
    e = lastindex(s.string)
    sz = iterate(s.string,e)[2]-1

    r, j = divrem(i-1, sz)
    j += 1

    if r >= s.repeat || j > e
        throw(BoundsError(s, i))
    end

    c, k = iterate(s.string, j)
    c, k-j+i
end

codeunit(s::RepString) = codeunit(s.string)
ncodeunits(s::RepString) = ncodeunits(s.string) * s.repeat

if isdefined(Base, :iterate)
    function iterate(s::RepString, i::Int = firstindex(s))
        i > ncodeunits(s) && return nothing
        return next(s, i)
    end
end

convert(::Type{RepString}, s::AbstractString) = RepString(s,1)
