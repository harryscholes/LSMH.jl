module LSMH

using Base.Iterators, Combinatorics

const UInt64_Max = typemax(UInt64)-1

include("hashing.jl")
include("murmurhash3.jl")
include("xxhash.jl")

export murmur32, xxhash32

end  # module
