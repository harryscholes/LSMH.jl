module LSMH

using Base.Iterators, Combinatorics

const UInt64_Max = typemax(UInt64)-1

include("hashing.jl")
include("murmurhash3.jl")

export murmur32

end  # module
