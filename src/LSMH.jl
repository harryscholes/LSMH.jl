module LSMH

using Combinatorics

export
    signature,
    lsh,
    murmur32,
    xxhash32

include("hashing.jl")
include("murmurhash3.jl")
include("xxhash.jl")

end  # module
