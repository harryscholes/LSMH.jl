using LSMH
using Test, Random, BioSequences

@testset "LSMH" begin

include("murmurhash3.jl")
include("xxhash.jl")
include("hashing.jl")
include("proteins.jl")

end
