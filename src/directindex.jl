# This file includes code that was formerly a part of Julia. License is MIT: http://julialang.org/license

abstract type DirectIndexString <: AbstractString end

next(s::DirectIndexString, i::Int) = (s[i],i+1)

length(s::DirectIndexString) = endof(s)

isvalid(s::DirectIndexString, i::Integer) = (firstindex(s) <= i <= lastindex(s))

prevind(s::DirectIndexString, i::Int) = i-1
nextind(s::DirectIndexString, i::Int) = i+1
prevind(s::DirectIndexString, i::Integer) = prevind(s, i)
nextind(s::DirectIndexString, i::Integer) = nextind(s, i)

function prevind(s::DirectIndexString, i::Integer, nchar::Integer)
    nchar > 0 || throw(ArgumentError("nchar must be greater than 0"))
    Int(i)-nchar
end

function nextind(s::DirectIndexString, i::Integer, nchar::Integer)
    nchar > 0 || throw(ArgumentError("nchar must be greater than 0"))
    Int(i)+nchar
end

ind2chr(s::DirectIndexString, i::Integer) = begin checkbounds(s,i); i end
chr2ind(s::DirectIndexString, i::Integer) = begin checkbounds(s,i); i end

length(s::SubString{<:DirectIndexString}) = lastindex(s)

isvalid(s::SubString{<:DirectIndexString}, i::Integer) = (firstindex(s) <= i <= ncodeunits(s))

ind2chr(s::SubString{<:DirectIndexString}, i::Integer) = begin checkbounds(s,i); i end
chr2ind(s::SubString{<:DirectIndexString}, i::Integer) = begin checkbounds(s,i); i end

reverseind(s::Union{DirectIndexString,SubString{DirectIndexString}}, i::Integer) = length(s) + 1 - i
