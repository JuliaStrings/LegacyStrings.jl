# This file includes code that was formerly a part of Julia. License is MIT: http://julialang.org/license

__precompile__(true)

module LegacyStrings

export
    ByteString,
    ASCIIString,
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
    endof,
    getindex,
    isvalid,
    lastidx,
    lcfirst,
    length,
    lowercase,
    map,
    next,
    pointer,
    reverse,
    reverseind,
    rsearch,
    search,
    show,
    sizeof,
    string,
    ucfirst,
    unsafe_convert,
    uppercase,
    write

    if VERSION >= v"0.5.0-"
        immutable ASCIIString <: DirectIndexString
            data::Array{UInt8,1}
        end

        immutable UTF8String <: AbstractString
            data::Vector{UInt8}
        end

        immutable UTF16String <: AbstractString
            data::Vector{UInt16} # includes 16-bit NULL termination after string chars
            function UTF16String(data::Vector{UInt16})
                if length(data) < 1 || data[end] != 0
                    throw(UnicodeError(UTF_ERR_NULL_16_TERMINATE, 0, 0))
                end
                new(data)
            end
        end

        immutable UTF32String <: DirectIndexString
            data::Vector{UInt32} # includes 32-bit NULL termination after string chars
            function UTF32String(data::Vector{UInt32})
                if length(data) < 1 || data[end] != 0
                    throw(UnicodeError(UTF_ERR_NULL_32_TERMINATE, 0, 0))
                end
                new(data)
            end
        end

        typealias ByteString Union{ASCIIString,UTF8String}

        include("support.jl")
        include("ascii.jl")
        include("utf8.jl")
        include("utf16.jl")
        include("utf32.jl")
    else
        using Base: UTF_ERR_SHORT, checkstring
    end
end # module
