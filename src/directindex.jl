# This file includes code that was formerly a part of Julia. License is MIT: http://julialang.org/license

abstract type DirectIndexString <: AbstractString end

next(s::DirectIndexString, i::Int) = (s[i],i+1)

length(s::DirectIndexString) = endof(s)

isvalid(s::DirectIndexString, i::Integer) = (firstindex(s) <= i <= lastindex(s))

prevind(s::DirectIndexString, i::Int) = i-1
nextind(s::DirectIndexString, i::Int) = i+1
prevind(s::DirectIndexString, i::Integer) = prevind(s, Int(i))
nextind(s::DirectIndexString, i::Integer) = nextind(s, Int(i))

function prevind(s::DirectIndexString, i::Int, nchar::Int)
    nchar ≥ 0 || throw(ArgumentError("n cannot be negative: $nchar"))
    return i-nchar
end

function nextind(s::DirectIndexString, i::Int, nchar::Int)
    nchar ≥ 0 || throw(ArgumentError("n cannot be negative: $nchar"))
    return i+nchar
end

prevind(s::DirectIndexString, i::Integer, n::Integer) = prevind(s, Int(i), Int(n))
nextind(s::DirectIndexString, i::Integer, n::Integer) = nextind(s, Int(i), Int(n))

ind2chr(s::DirectIndexString, i::Integer) = begin checkbounds(s,i); i end
chr2ind(s::DirectIndexString, i::Integer) = begin checkbounds(s,i); i end

length(s::SubString{<:DirectIndexString}) = lastindex(s)

isvalid(s::SubString{<:DirectIndexString}, i::Integer) = (firstindex(s) <= i <= ncodeunits(s))

ind2chr(s::SubString{<:DirectIndexString}, i::Integer) = begin checkbounds(s,i); i end
chr2ind(s::SubString{<:DirectIndexString}, i::Integer) = begin checkbounds(s,i); i end

reverseind(s::Union{DirectIndexString,SubString{DirectIndexString}}, i::Integer) = length(s) + 1 - i
