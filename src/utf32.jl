# This file includes code that was formerly a part of Julia. License is MIT: http://julialang.org/license

UTF32String(data::Vector{Char}) = UTF32String(reinterpret(UInt32, data))

# UTF-32 basic functions
next(s::UTF32String, i::Int) = (Char(s.data[i]), i+1)
lastindex(s::UTF32String) = length(s.data) - 1
length(s::UTF32String) = length(s.data) - 1

codeunit(s::UTF32String) = UInt32
ncodeunits(s::UTF32String) = length(s.data)

if isdefined(Base, :iterate)
    function iterate(s::UTF32String, i::Int = firstindex(s))
        i > length(s) && return nothing
        return next(s, i)
    end
end

reverse(s::UTF32String) = UTF32String(reverse!(copy(s.data), 1, length(s)))

sizeof(s::UTF32String) = sizeof(s.data) - sizeof(UInt32)

const empty_utf32 = UTF32String(UInt32[0])

convert(::Type{UTF32String}, c::Char) = UTF32String(UInt32[c, 0])
convert(::Type{UTF32String}, s::UTF32String) = s

function convert(::Type{UTF32String}, str::AbstractString)
    len, flags = unsafe_checkstring(str)
    buf = Vector{UInt32}(undef, len+1)
    out = 0
    @inbounds for ch in str ; buf[out += 1] = ch ; end
    @inbounds buf[out + 1] = 0 # NULL termination
    UTF32String(buf)
end

function convert(::Type{UTF8String},  str::UTF32String)
    dat = str.data
    len = sizeof(dat) >>> 2
    # handle zero length string quickly
    len <= 1 && return empty_utf8
    # get number of bytes to allocate
    len, flags, num4byte, num3byte, num2byte = unsafe_checkstring(dat, 1, len-1)
    flags == 0 && @inbounds return UTF8String(copyto!(Vector{UInt8}(undef, len), 1, dat, 1, len))
    return encode_to_utf8(UInt32, dat, len + num2byte + num3byte*2 + num4byte*3)
end

function convert(::Type{UTF32String}, str::UTF8String)
    dat = str.data
    # handle zero length string quickly
    sizeof(dat) == 0 && return empty_utf32
    # Validate UTF-8 encoding, and get number of words to create
    len, flags = unsafe_checkstring(dat)
    # Optimize case where no characters > 0x7f
    flags == 0 && @inbounds return fast_utf_copy(UTF32String, UInt32, len, dat, true)
    # has multi-byte UTF-8 sequences
    buf = Vector{UInt32}(undef, len+1)
    @inbounds buf[len+1] = 0 # NULL termination
    local ch::UInt32, surr::UInt32
    out = 0
    pos = 0
    @inbounds while out < len
        ch = dat[pos += 1]
        # Handle ASCII characters
        if ch <= 0x7f
            buf[out += 1] = ch
        # Handle range 0x80-0x7ff
        elseif ch < 0xe0
            buf[out += 1] = ((ch & 0x1f) << 6) | (dat[pos += 1] & 0x3f)
        # Handle range 0x800-0xffff
        elseif ch < 0xf0
            pos += 2
            ch = get_utf8_3byte(dat, pos, ch)
            # Handle surrogate pairs (should have been encoded in 4 bytes)
            if is_surrogate_lead(ch)
                # Build up 32-bit character from ch and trailing surrogate in next 3 bytes
                pos += 3
                surr = ((UInt32(dat[pos-2] & 0xf) << 12)
                        | (UInt32(dat[pos-1] & 0x3f) << 6)
                        | (dat[pos] & 0x3f))
                ch = get_supplementary(ch, surr)
            end
            buf[out += 1] = ch
        # Handle range 0x10000-0x10ffff
        else
            pos += 3
            buf[out += 1] = get_utf8_4byte(dat, pos, ch)
        end
    end
    UTF32String(buf)
end

function convert(::Type{UTF32String}, str::UTF16String)
    dat = str.data
    len = sizeof(dat)
    # handle zero length string quickly (account for trailing \0)
    len <= 2 && return empty_utf32
    # get number of words to create
    len, flags, num4byte = unsafe_checkstring(dat, 1, len>>>1)
    # No surrogate pairs, do optimized copy
    (flags & UTF_UNICODE4) == 0 && @inbounds return UTF32String(copyto!(Vector{UInt32}(undef, len), dat))
    local ch::UInt32
    buf = Vector{UInt32}(undef, len)
    out = 0
    pos = 0
    @inbounds while out < len
        ch = dat[pos += 1]
        # check for surrogate pair
        if is_surrogate_lead(ch) ; ch = get_supplementary(ch, dat[pos += 1]) ; end
        buf[out += 1] = ch
    end
    UTF32String(buf)
end

function convert(::Type{UTF16String}, str::UTF32String)
    dat = str.data
    len = sizeof(dat)
    # handle zero length string quickly
    len <= 4 && return empty_utf16
    # get number of words to allocate
    len, flags, num4byte = unsafe_checkstring(dat, 1, len>>>2)
    # optimized path, no surrogates
    num4byte == 0 && @inbounds return UTF16String(copyto!(Vector{UInt16}(undef, len), dat))
    return encode_to_utf16(dat, len + num4byte)
end

function convert(::Type{UTF32String}, str::ASCIIString)
    dat = str.data
    @inbounds return fast_utf_copy(UTF32String, UInt32, length(dat), dat, true)
end

function convert(::Type{UTF32String}, dat::AbstractVector{UInt32})
    @inbounds return fast_utf_copy(UTF32String, UInt32, length(dat), dat, true)
end

convert(::Type{UTF32String}, data::AbstractVector{Int32}) =
    convert(UTF32String, reinterpret(UInt32, convert(Vector{Int32}, data)))

convert(::Type{UTF32String}, data::AbstractVector{Char}) =
    convert(UTF32String, map(UInt32, data))

convert(::Type{T}, v::AbstractVector{S}) where {T<:AbstractString, S<:Union{UInt32,Char,Int32}} =
    convert(T, utf32(v))

# specialize for performance reasons:
function convert(::Type{T}, data::AbstractVector{S}) where {T<:ByteString, S<:Union{UInt32,Char,Int32}}
    s = IOBuffer(Vector{UInt8}(undef, length(data)), read=true, write=true)
    truncate(s,0)
    for x in data
        print(s, Char(x))
    end
    convert(T, String(take!(s)))
end

convert(::Type{Vector{UInt32}}, str::UTF32String) = str.data
convert(::Type{Array{UInt32}},  str::UTF32String) = str.data

unsafe_convert(::Type{Ptr{T}}, s::UTF32String) where {T<:Union{UInt32,Int32,Char}} =
    convert(Ptr{T}, pointer(s))

function convert(T::Type{UTF32String}, bytes::AbstractArray{UInt8})
    isempty(bytes) && return empty_utf32
    nb = length(bytes)
    nb & 3 != 0 && throw(UnicodeError(UTF_ERR_ODD_BYTES_32,0,0))
    b1 = bytes[1]
    b2 = bytes[2]
    b3 = bytes[3]
    b4 = bytes[4]
    if b1 == 0 && b2 == 0 && b3 == 0xfe && b4 == 0xff
        offset = 1
        swap = false
    elseif b1 == 0xff && b2 == 0xfe && b3 == 0 && b4 == 0
        offset = 1
        swap = true
    else
        offset = 0
        swap = false
    end
    len = nb ÷ 4 - offset
    d = Vector{UInt32}(undef, len + 1)
    if swap
        @inbounds for i in 1:len
            ib = i + offset
            b1 = UInt32(bytes[ib * 2 - 1])
            b2 = UInt32(bytes[ib * 2])
            b3 = UInt32(bytes[ib * 2 + 1])
            b4 = UInt32(bytes[ib * 2 + 2])
            d[i] = (b1 << 24) | (b2 << 16) | (b3 << 8) | b4
        end
    else
        unsafe_copyto!(Ptr{UInt8}(pointer(d)), pointer(bytes, offset * 4 + 1), len * 4)
    end
    d[end] = 0 # NULL terminate
    UTF32String(d)
end

function isvalid(::Type{UTF32String}, str::Union{Vector{UInt32}, Vector{Char}})
    for c in str
        @inbounds if !isvalid(Char, UInt32(c)) ; return false ; end
    end
    return true
end
isvalid(str::Vector{Char}) = isvalid(UTF32String, str)

utf32(x) = convert(UTF32String, x)

utf32(p::Ptr{UInt32}, len::Integer) = utf32(unsafe_wrap(Array, p, len))
utf32(p::Union{Ptr{Char}, Ptr{Int32}}, len::Integer) = utf32(convert(Ptr{UInt32}, p), len)
function utf32(p::Union{Ptr{UInt32}, Ptr{Char}, Ptr{Int32}})
    len = 0
    while unsafe_load(p, len+1) != 0; len += 1; end
    utf32(p, len)
end

function map(f, s::UTF32String)
    d = s.data
    out = similar(d)
    out[end] = 0

    @inbounds for i = 1:(length(d)-1)
        c2 = f(Char(d[i]))
        if !isa(c2, Char)
            throw(UnicodeError(UTF_ERR_MAP_CHAR, 0, 0))
        end
        out[i] = (c2::Char)
    end
    UTF32String(out)
end

# Definitions for C compatible strings, that don't allow embedded
# '\0', and which are terminated by a '\0'
containsnul(s::ByteString) = containsnul(unsafe_convert(Ptr{Cchar}, s), sizeof(s))
containsnul(s::Union{UTF16String,UTF32String}) = findfirst(isequal(0), s.data) != length(s.data)

if sizeof(Cwchar_t) == 2
    const WString = UTF16String
    const wstring = utf16
elseif sizeof(Cwchar_t) == 4
    const WString = UTF32String
    const wstring = utf32
end
wstring(s::Cwstring) = wstring(convert(Ptr{Cwchar_t}, s))

# Cwstring is defined in c.jl, but conversion needs to be defined here
# to have WString
function unsafe_convert(::Type{Cwstring}, s::WString)
    if containsnul(s)
        throw(ArgumentError("embedded NUL chars are not allowed in C strings: $(repr(s))"))
    end
    return Cwstring(unsafe_convert(Ptr{Cwchar_t}, s))
end

# pointer conversions of ASCII/UTF8/UTF16/UTF32 strings:
pointer(x::Union{ByteString,UTF16String,UTF32String}) = pointer(x.data)
pointer(x::ByteString, i::Integer) = pointer(x.data)+(i-1)
pointer(x::Union{UTF16String,UTF32String}, i::Integer) = pointer(x)+(i-1)*sizeof(eltype(x.data))

# pointer conversions of SubString of ASCII/UTF8/UTF16/UTF32:
pointer(x::SubString{T}) where {T<:ByteString} = pointer(x.string.data) + x.offset
pointer(x::SubString{T}, i::Integer) where {T<:ByteString} = pointer(x.string.data) + x.offset + (i-1)
pointer(x::SubString{T}) where {T<:Union{UTF16String,UTF32String}} = pointer(x.string.data) + x.offset*sizeof(eltype(x.string.data))
pointer(x::SubString{T}, i::Integer) where {T<:Union{UTF16String,UTF32String}} = pointer(x.string.data) + (x.offset + (i-1))*sizeof(eltype(x.string.data))

"""
    utf32(s)

Create a UTF-32 string from a byte array, array of `Char` or `UInt32`, or any other string
type. (Conversions of byte arrays check for a byte-order marker in the first four bytes, and
do not include it in the resulting string.)

Note that the resulting `UTF32String` data is terminated by the NUL codepoint (32-bit zero),
which is not treated as a character in the string (so that it is mostly invisible in Julia);
this allows the string to be passed directly to external functions requiring NUL-terminated
data. This NUL is appended automatically by the `utf32(s)` conversion function. If you have
a `Char` or `UInt32` array `A` that is already NUL-terminated UTF-32 data, then you can
instead use `UTF32String(A)` to construct the string without making a copy of the data and
treating the NUL as a terminator rather than as part of the string.
"""
utf32(s)

"""
    utf32(::Union{Ptr{Char},Ptr{UInt32},Ptr{Int32}} [, length])

Create a string from the address of a NUL-terminated UTF-32 string. A copy is made; the
pointer can be safely freed. If `length` is specified, the string does not have to be
NUL-terminated.
"""
utf32(::Union{Ptr{Char},Ptr{UInt32},Ptr{Int32}}, length=length)
