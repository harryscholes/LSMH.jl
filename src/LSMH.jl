module LSMH

using Combinatorics, BioSequences

export
    signature,
    lsh,
    murmur32,
    xxhash32,
    fasta_records,
    fasta_signatures,
    identifier,
    Signature,
    HashTable

include("hashing.jl")
include("murmurhash3.jl")
include("xxhash.jl")
include("proteins.jl")

end  # module
