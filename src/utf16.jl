# This file includes code that was formerly a part of Julia. License is MIT: http://julialang.org/license

# Quickly copy and set trailing \0
@inline function fast_utf_copy(::Type{S}, ::Type{T}, len, dat, flag::Bool=false) where
                              {S <: Union{UTF16String, UTF32String}, T <: Union{UInt16, UInt32}}
    S(setindex!(copyto!(Vector{T}(undef, len+1), 1, dat, 1, flag ? len : len+1), 0, len+1))
end

# Get rest of character ch from 3-byte UTF-8 sequence in dat
@inline function get_utf8_3byte(dat, pos, ch)
    @inbounds return ((ch & 0xf) << 12) | (UInt32(dat[pos-1] & 0x3f) << 6) | (dat[pos] & 0x3f)
end
# Get rest of character ch from 4-byte UTF-8 sequence in dat
@inline function get_utf8_4byte(dat, pos, ch)
    @inbounds return (((ch & 0x7) << 18)
                        | (UInt32(dat[pos-2] & 0x3f) << 12)
                        | (UInt32(dat[pos-1] & 0x3f) << 6)
                        | (dat[pos] & 0x3f))
end

# Output a character as a 4-byte UTF-8 sequence
@inline function output_utf8_4byte!(buf, out, ch)
    @inbounds begin
        buf[out + 1] = 0xf0 | (ch >>> 18)
        buf[out + 2] = 0x80 | ((ch >>> 12) & 0x3f)
        buf[out + 3] = 0x80 | ((ch >>> 6) & 0x3f)
        buf[out + 4] = 0x80 | (ch & 0x3f)
    end
end

const empty_utf16 = UTF16String(UInt16[0])

function length(s::UTF16String)
    d = s.data
    len = length(d) - 1
    len == 0 && return 0
    cnum = 0
    for i = 1:len
        @inbounds cnum += !is_surrogate_trail(d[i])
    end
    cnum
end

function lastindex(s::UTF16String)
    d = s.data
    i = length(d) - 1
    i == 0 && return i
    return is_surrogate_codeunit(d[i]) ? i-1 : i
end

codeunit(s::UTF16String) = UInt16
ncodeunits(s::UTF16String) = length(s.data) - 1

get_supplementary(lead::Unsigned, trail::Unsigned) = (UInt32(lead-0xd7f7)<<10 + trail)

function next(s::UTF16String, i::Int)
    ch = s.data[i]
    !is_surrogate_codeunit(ch) && return (Char(ch), i+1)
    # check length, account for terminating \0
    i >= (length(s.data)-1) && throw(UnicodeError(UTF_ERR_MISSING_SURROGATE, i, UInt32(ch)))
    !is_surrogate_lead(ch) && throw(UnicodeError(UTF_ERR_NOT_LEAD, i, ch))
    ct = s.data[i+1]
    !is_surrogate_trail(ct) && throw((UTF_ERR_NOT_TRAIL, i, ch))
    Char(get_supplementary(ch, ct)), i+2
end

if isdefined(Base, :iterate)
    function iterate(s::UTF16String, i::Int = firstindex(s))
        i > ncodeunits(s) && return nothing
        return next(s, i)
    end
end

function reverseind(s::UTF16String, i::Integer)
    j = length(s.data) - i
    return is_surrogate_trail(s.data[j]) ? j-1 : j
end

lastidx(s::UTF16String) = length(s.data) - 1 # s.data includes NULL terminator

function reverse(s::UTF16String)
    d = s.data
    out = similar(d)
    out[end] = 0 # NULL termination
    n = length(d)
    @inbounds for i = 1:n-1
        ch = d[n-i]
        if is_surrogate_lead(ch)
            out[i],out[i-1] = out[i-1],ch
        else
            out[i] = ch
        end
    end
    UTF16String(out)
end

sizeof(s::UTF16String) = sizeof(s.data) - sizeof(UInt16)

function isvalid(s::UTF16String, i::Int)
    (i < 1 || i > ncodeunits(s)) && return false
    if is_surrogate_lead(s.data[i]) && is_surrogate_trail(s.data[i+1])
        return true
    elseif is_surrogate_codeunit(s.data[i])
        return false
    else
        return true
    end
end

function isvalid(::Type{UTF16String}, data::AbstractArray{UInt16})
    i = 1
    n = length(data) # this may include NULL termination; that's okay
    @inbounds while i < n # check for unpaired surrogates
        if is_surrogate_lead(data[i]) && is_surrogate_trail(data[i+1])
            i += 2
        elseif is_surrogate_codeunit(data[i])
            return false
        else
            i += 1
        end
    end
    return i > n || !is_surrogate_codeunit(data[i])
end

function convert(::Type{UTF16String}, str::AbstractString)
    len, flags, num4byte = unsafe_checkstring(str)
    buf = Vector{UInt16}(undef, len+num4byte+1)
    out = 0
    @inbounds for ch in str
        c = UInt32(ch)
        if c < 0x10000
            buf[out += 1] = UInt16(c)
        else
            # output surrogate pair
            buf[out += 1] = UInt16(0xd7c0 + (c >>> 10))
            buf[out += 1] = UInt16(0xdc00 + (c & 0x3ff))
        end
    end
    @inbounds buf[out + 1] = 0 # NULL termination
    UTF16String(buf)
end

function convert(::Type{UTF16String}, str::UTF8String)
    dat = str.data
    # handle zero length string quickly
    sizeof(dat) == 0 && return empty_utf16
    # Check that is correct UTF-8 encoding and get number of words needed
    len, flags, num4byte = unsafe_checkstring(dat)
    len += num4byte
    buf = Vector{UInt16}(undef, len+1)
    @inbounds buf[len+1] = 0
    # Optimize case where no characters > 0x7f
    flags == 0 && @inbounds return UTF16String(copyto!(buf, dat))
    out = 0
    pos = 0
    @inbounds while out < len
        ch::UInt32 = dat[pos += 1]
        # Handle ASCII characters
        if ch <= 0x7f
            buf[out += 1] = ch
        # Handle range 0x80-0x7ff
        elseif ch < 0xe0
            buf[out += 1] = ((ch & 0x1f) << 6) | (dat[pos += 1] & 0x3f)
        # Handle range 0x800-0xffff
        elseif ch < 0xf0
            pos += 2
            buf[out += 1] = get_utf8_3byte(dat, pos, ch)
        # Handle range 0x10000-0x10ffff
        else
            pos += 3
            ch = get_utf8_4byte(dat, pos, ch)
            # output surrogate pair
            buf[out += 1] = UInt16(0xd7c0 + (ch >>> 10))
            buf[out += 1] = UInt16(0xdc00 + (ch & 0x3ff))
        end
    end
    UTF16String(buf)
end

function convert(::Type{UTF8String}, str::UTF16String)
    dat = str.data
    len = sizeof(dat) >>> 1
    # handle zero length string quickly
    len <= 1 && return empty_utf8
    # get number of bytes to allocate
    len, flags, num4byte, num3byte, num2byte = unsafe_checkstring(dat, 1, len-1)
    flags == 0 && @inbounds return UTF8String(copyto!(Vector{UInt8}(undef, len), 1, dat, 1, len))
    return encode_to_utf8(UInt16, dat, len + num2byte + num3byte*2 + num4byte*3)
end

"""
Converts an already validated UTF-32 encoded vector of `UInt32` to a `UTF16String`

Input Arguments:

*   `dat` `Vector{UInt32}` of UTF-32 encoded data
*   `len` length of output in 16-bit words

Returns:

*   `UTF16String`
"""
function encode_to_utf16(dat, len)
    buf = Vector{UInt16}(undef, len)
    @inbounds buf[len] = 0 # NULL termination
    out = 0
    pos = 0
    @inbounds while out < len
        ch = UInt32(dat[pos += 1])
        if ch > 0xffff
            # Output surrogate pair for 0x10000-0x10ffff
            buf[out += 1] = 0xd7c0 + (ch >>> 10)
            ch = 0xdc00 + (ch & 0x3ff)
        end
        buf[out += 1] = ch
    end
    UTF16String(buf)
end

function convert(::Type{UTF16String}, str::ASCIIString)
    dat = str.data
    @inbounds return fast_utf_copy(UTF16String, UInt16, length(dat), dat, true)
end

convert(::Type{Vector{UInt16}}, str::UTF16String) = str.data
convert(::Type{Array{UInt16}},  str::UTF16String) = str.data

convert(::Type{UTF16String}, str::UTF16String)    = str

unsafe_convert(::Type{Ptr{T}}, s::UTF16String) where {T<:Union{Int16,UInt16}} =
    convert(Ptr{T}, pointer(s))

convert(T::Type{UTF16String}, data::AbstractArray{UInt16}) =
    convert(T, reshape(data, length(data)))

convert(T::Type{UTF16String}, data::AbstractArray{Int16}) =
    convert(T, reinterpret(UInt16, data))

function convert(::Type{UTF16String}, dat::AbstractVector{UInt16})
    len, flags, num4byte = unsafe_checkstring(dat)
    @inbounds return fast_utf_copy(UTF16String, UInt16, len+num4byte, dat, true)
end

function convert(T::Type{UTF16String}, bytes::AbstractArray{UInt8})
    isempty(bytes) && return UTF16String(UInt16[0])
    nb = length(bytes)
    isodd(nb) && throw(UnicodeError(UTF_ERR_ODD_BYTES_16, length(bytes), 0))
    b1 = bytes[1]
    b2 = bytes[2]
    if b1 == 0xfe && b2 == 0xff
        offset = 1
        swap = false
    elseif b1 == 0xff && b2 == 0xfe
        offset = 1
        swap = true
    else
        offset = 0
        swap = false
    end
    len = nb ÷ 2 - offset
    d = Vector{UInt16}(undef, len + 1)
    if swap
        @inbounds for i in 1:len
            ib = i + offset
            bhi = bytes[ib * 2 - 1]
            blo = bytes[ib * 2]
            d[i] = (UInt16(bhi) << 8) | blo
        end
    else
        unsafe_copyto!(Ptr{UInt8}(pointer(d)), pointer(bytes, offset * 2 + 1), len * 2)
    end
    d[end] = 0 # NULL terminate
    !isvalid(UTF16String, d) && throw(UnicodeError(UTF_ERR_INVALID_16,0,0))
    UTF16String(d)
end

utf16(x) = convert(UTF16String, x)
utf16(p::Ptr{UInt16}, len::Integer) = utf16(unsafe_wrap(Array, p, len))
utf16(p::Ptr{Int16}, len::Integer) = utf16(convert(Ptr{UInt16}, p), len)
function utf16(p::Union{Ptr{UInt16}, Ptr{Int16}})
    len = 0
    while unsafe_load(p, len+1) != 0; len += 1; end
    utf16(p, len)
end

function map(fun, str::UTF16String)
    buf = UInt16[]
    sizehint!(buf, length(str.data))
    for ch in str
        c2 = fun(ch)
        if !isa(c2, Char)
            throw(UnicodeError(UTF_ERR_MAP_CHAR, 0, 0))
        end
        uc = UInt32(c2)
        if uc < 0x10000
            if is_surrogate_codeunit(UInt16(uc))
                throw(UnicodeError(UTF_ERR_INVALID_CHAR, 0, uc))
            end
            push!(buf, UInt16(uc))
        elseif uc <= 0x10ffff
            push!(buf, UInt16(0xd7c0 + (uc >> 10)))
            push!(buf, UInt16(0xdc00 + (uc & 0x3ff)))
        else
            throw(UnicodeError(UTF_ERR_INVALID_CHAR, 0, uc))
        end
    end
    push!(buf, 0)
    UTF16String(buf)
end

"""
    utf16(s)

Create a UTF-16 string from a byte array, array of `UInt16`, or any other string type. (Data
must be valid UTF-16. Conversions of byte arrays check for a byte-order marker in the first
two bytes, and do not include it in the resulting string.)

Note that the resulting `UTF16String` data is terminated by the NUL codepoint (16-bit zero),
which is not treated as a character in the string (so that it is mostly invisible in Julia);
this allows the string to be passed directly to external functions requiring NUL-terminated
data. This NUL is appended automatically by the `utf16(s)` conversion function. If you have
a `UInt16` array `A` that is already NUL-terminated valid UTF-16 data, then you can instead
use `UTF16String(A)` to construct the string without making a copy of the data and treating
the NUL as a terminator rather than as part of the string.
"""
utf16(s)

"""
    utf16(::Union{Ptr{UInt16},Ptr{Int16}} [, length])

Create a string from the address of a NUL-terminated UTF-16 string. A copy is made; the
pointer can be safely freed. If `length` is specified, the string does not have to be
NUL-terminated.
"""
utf16(::Union{Ptr{UInt16},Ptr{Int16}}, length=length)
