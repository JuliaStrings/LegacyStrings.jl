# This file includes code that was formerly a part of Julia. License is MIT: http://julialang.org/license

__precompile__(true)

module LegacyStrings

export
    DirectIndexString,
    ByteString,
    ASCIIString,
    RepString,
    RevString,
    UTF8String,
    UTF16String,
    UTF32String,
    WString,
    ascii, # distinct from Base.ascii
    utf8,
    utf16,
    utf32,
    wstring

import Base:
    containsnul,
    convert,
    getindex,
    isvalid,
    length,
    lowercase,
    map,
    nextind,
    pointer,
    prevind,
    reverse,
    reverseind,
    show,
    sizeof,
    string,
    unsafe_convert,
    uppercase,
    write

using Compat
using Compat: IOBuffer
import Compat:
    lastindex,
    codeunit,
    ncodeunits

if isdefined(Base, :lcfirst)
    import Base: lcfirst
end

if isdefined(Base, :next)
    import Base: next
end

if isdefined(Base, :rsearch)
    import Base: rsearch
end

if isdefined(Base, :search)
    import Base: search
end

if isdefined(Base, :ucfirst)
    import Base: ucfirst
end

if isdefined(Base, :iterate)
    import Base: iterate
end

if isdefined(Base, :UnicodeError)
    import Base: UnicodeError
else
    include("unicodeerror.jl")
end

if isdefined(Base, :DirectIndexString)
    using Base: DirectIndexString
else
    include("directindex.jl")
end

struct ASCIIString <: DirectIndexString
    data::Vector{UInt8}
    ASCIIString(data::String) = new(Vector{UInt8}(codeunits(data)))
    ASCIIString(data) = new(data)
end

struct UTF8String <: AbstractString
    data::Vector{UInt8}
    UTF8String(data::String) = new(Vector{UInt8}(codeunits(data)))
    UTF8String(data) = new(data)
end

struct UTF16String <: AbstractString
    data::Vector{UInt16} # includes 16-bit NULL termination after string chars
    function UTF16String(data::Vector{UInt16})
        if length(data) < 1 || data[end] != 0
            throw(UnicodeError(UTF_ERR_NULL_16_TERMINATE, 0, 0))
        end
        new(data)
    end
end

struct UTF32String <: DirectIndexString
    data::Vector{UInt32} # includes 32-bit NULL termination after string chars
    function UTF32String(data::Vector{UInt32})
        if length(data) < 1 || data[end] != 0
            throw(UnicodeError(UTF_ERR_NULL_32_TERMINATE, 0, 0))
        end
        new(data)
    end
end

const ByteString = Union{ASCIIString,UTF8String}

include("support.jl")
include("ascii.jl")
include("utf8.jl")
include("utf16.jl")
include("utf32.jl")
include("rep.jl")

if isdefined(Base, :RevString)
    using Base: RevString
else
    include("rev.jl")
end

const AllLegacyStringTypes = Union{ASCIIString,UTF8String,UTF16String,UTF32String,RepString,RevString}

codeunit(s::SubString{<:AllLegacyStringTypes}) = codeunit(s.string)
ncodeunits(s::SubString{<:AllLegacyStringTypes}) = isdefined(s, :ncodeunits) ? s.ncodeunits : s.endof

if !isdefined(Base, :iterate)
    iterate(s::Union{String,SubString,AllLegacyStringTypes}, i::Int) = next(s, i)
end

end # module
