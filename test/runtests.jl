using LSMH
using Test, Random

@testset "LSMH" begin

include("murmurhash3.jl")
include("xxhash.jl")
include("hashing.jl")

end
