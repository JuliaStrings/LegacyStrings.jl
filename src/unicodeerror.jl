##    Error messages for Unicode / UTF support

struct UnicodeError <: Exception
    errmsg::AbstractString   ##< A UTF_ERR_ message
    errpos::Int32            ##< Position of invalid character
    errchr::UInt32           ##< Invalid character
end

show(io::IO, exc::UnicodeError) = print(io, replace(replace(string("UnicodeError: ",exc.errmsg),
    "<<1>>" => string(exc.errpos)),
    "<<2>>" => string(exc.errchr, base=16)))
