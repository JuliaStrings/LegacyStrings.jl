# LegacyStrings

[![Travis CI Build Status](https://travis-ci.org/JuliaArchive/LegacyStrings.jl.svg?branch=master)](https://travis-ci.org/JuliaArchive/LegacyStrings.jl)
[![AppVeyor Build Status](https://ci.appveyor.com/api/projects/status/ib52329urgg62jai?svg=true)](https://ci.appveyor.com/project/nalimilan/legacystrings-jl)

[![Julia 0.4 Status](http://pkg.julialang.org/badges/LegacyStrings_0.4.svg)](http://pkg.julialang.org/?pkg=LegacyStrings&ver=0.4)
[![Julia 0.5 Status](http://pkg.julialang.org/badges/LegacyStrings_0.5.svg)](http://pkg.julialang.org/?pkg=LegacyStrings&ver=0.5)

The LegacyStrings package provides compatibility string types from Julia 0.5 (and earlier), which were removed in subsequent versions, including:

- `ASCIIString`: a single-byte-per character string type that can only hold ASCII string data.
- `UTF8String`: a string type with single byte code units (`UInt8`), encoding strings as UTF-8.
- `UTF16String`: a string type with two-byte native-endian code units (`UInt16`), encoding strings as UTF-16.
- `UTF32String`: a string type with four-byte native-endian code units (`UInt32`), encoding strings as UTF-32.
- `ByteString`: a type alias for `Union{ASCIIString,UTF8String}`, i.e. strings that can be passed to C directly.
- `WString`: an alias for `UTF16String` if `Cwchart_t` is two bytes (i.e. Windows) or `UTF32String` otherwise.
- `RepString`: a string type for efficient handling of repeated strings.

LegacyStrings also defines and exports converter functions for these types, i.e.:

- `ascii`: convert to `ASCIIString`; on 0.5 since `Base` exports an `ascii` function as well, you must explicitly do `import LegacyStrings: ascii` or write `LegacyStrings.ascii` in order to use this function rather than `Base.ascii`.
- `utf8`: convert to `UTF8String`.
- `utf16`: convert to `UTF16String`.
- `utf32`: convert to `UTF32String`.
- `wstring`: alias for `utf16` or `utf32` according to what `WString` is an alias to.

The definitions of the above types and functions are conditional on the version of Julia being used so that you can do `using LegacyStrings` unconditionally and be guaranteed that e.g. `LegacyStrings.ASCIIString` is an `ASCIIString` type that will behave as expect in Julia 0.4 or earlier.
