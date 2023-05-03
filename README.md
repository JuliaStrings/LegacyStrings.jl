# LegacyStrings

[![CI](https://github.com/JuliaStrings/LegacyStrings.jl/workflows/CI/badge.svg)](https://github.com/JuliaStrings/LegacyStrings.jl/actions?query=workflow%3ACI)

The LegacyStrings package provides compatibility string types from Julia 0.5 (and earlier), which were removed in subsequent versions, including:

- `ASCIIString`: a single-byte-per character string type that can only hold ASCII string data.
- `UTF8String`: a string type with single byte code units (`UInt8`), encoding strings as UTF-8.
- `UTF16String`: a string type with two-byte native-endian code units (`UInt16`), encoding strings as UTF-16.
- `UTF32String`: a string type with four-byte native-endian code units (`UInt32`), encoding strings as UTF-32.
- `ByteString`: a type alias for `Union{ASCIIString,UTF8String}`, i.e. strings that can be passed to C directly.
- `WString`: an alias for `UTF16String` if `Cwchart_t` is two bytes (i.e. Windows) or `UTF32String` otherwise.
- `RepString`: a string type for efficient handling of repeated strings.

LegacyStrings also defines and exports converter functions for these types, i.e.:

- `ascii`: convert to `ASCIIString`; since `Base` exports an `ascii` function as well, you must explicitly do `import LegacyStrings: ascii` or write `LegacyStrings.ascii` in order to use this function rather than `Base.ascii`.
- `utf8`: convert to `UTF8String`.
- `utf16`: convert to `UTF16String`.
- `utf32`: convert to `UTF32String`.
- `wstring`: alias for `utf16` or `utf32` according to what `WString` is an alias to.
