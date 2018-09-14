module LSMH

using Combinatorics, BioSequences

export
    murmur32,
    xxhash32,
    minhash, signature, lsh,
    fasta_records, fasta_signatures,
    AbstractSignature, Signature, identifier, hashband,
    HashTable, band, hashtable,
    candidates, jaccard

include("hashing.jl")
include("murmurhash3.jl")
include("xxhash.jl")
include("proteins.jl")

end  # module
