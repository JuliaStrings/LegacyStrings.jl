# This file includes code that was formerly a part of Julia. License is MIT: https://julialang.org/license

## reversed strings without data movement ##

struct RevString{T<:AbstractString} <: AbstractString
    string::T
end

lastindex(s::RevString) = lastindex(s.string)
length(s::RevString) = length(s.string)
sizeof(s::RevString) = sizeof(s.string)

function next(s::RevString, i::Int)
    n = lastindex(s); j = n-i+1
    (s.string[j], n-prevind(s.string,j)+1)
end

codeunit(s::RevString) = codeunit(s.string)
@propagate_inbounds function codeunit(s::RevString, i::Integer)
    @boundscheck checkbounds(codeunits(s), i)
    s = s.string
    j = ncodeunits(s)-i+1
    j0 = thisind(s, j)
    j1 = nextind(s, j0)
    @inbounds codeunit(s, j0+j1-j-1)
end

ncodeunits(s::RevString) = ncodeunits(s.string)

if isdefined(Base, :iterate)
    function iterate(s::RevString, i::Int = firstindex(s))
        i > lastindex(s) && return nothing
        return next(s, i)
    end
end

function isvalid(s::RevString, i::Int)
    1 ≤ i ≤ ncodeunits(s) || return false
    j = 1
    while j < i
        _, j = iterate(s, j)
    end
    return j == i
end

reverse(s::RevString) = s.string
reverseind(s::RevString, i::Integer) = lastindex(s) - i + 1

isascii(s::RevString) = isascii(s.string)
