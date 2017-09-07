# This file includes code that was formerly a part of Julia. License is MIT: https://julialang.org/license

## reversed strings without data movement ##

immutable RevString{T<:AbstractString} <: AbstractString
    string::T
end

endof(s::RevString) = endof(s.string)
length(s::RevString) = length(s.string)
sizeof(s::RevString) = sizeof(s.string)

function next(s::RevString, i::Int)
    n = endof(s); j = n-i+1
    (s.string[j], n-prevind(s.string,j)+1)
end

reverse(s::RevString) = s.string
reverseind(s::RevString, i::Integer) = endof(s) - i + 1
