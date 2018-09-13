#=
MurmurHash3 was written by Austin Appleby, and is placed in the public
domain.
=#
const c1 = 0xcc9e2d51
const c2 = 0x1b873593

"""
    murmur32(key[, seed])

Hash `key` to a `UInt32` using the 32 bit MurmurHash3 hashing function, optionally
seeded with `seed`.
"""
function murmur32(data::Union{AbstractString,Array{UInt8}}, seed::UInt32)::UInt32
    # head
    len = UInt32(length(data))
    nblocks = div(len, 4)
    last = nblocks*4
    h = seed
    blocks = Ptr{UInt32}(pointer(data))

    # body
    @inbounds for block = 1:nblocks
        k = unsafe_load(blocks, block)
        k *= c1; k = rotl32(k, 15); k *= c2; h = h ⊻ k
        h = rotl32(h, 13); h *= UInt32(5); h += 0xe6546b64
    end

    # tail
    k = UInt32(0)
    remainder = len & 3
    tail = Ptr{UInt8}(pointer(data))

    if remainder == 3 k = k ⊻ UInt32(unsafe_load(tail, last+3)) << 16 end
    if remainder >= 2 k = k ⊻ UInt32(unsafe_load(tail, last+2)) <<  8 end
    if remainder >= 1
        k = k ⊻ unsafe_load(tail, last+1)
        k *= c1; k = rotl32(k, 15); k *= c2; h = h ⊻ k
    end

    # finalization
    h = h ⊻ len
    h = fmix32(h)
end
function murmur32(key::Union{AbstractString,Array{UInt8}}, seed::Integer)
    try
        murmur32(key, UInt32(seed))
    catch InexactError
        throw(DomainError(seed, "`seed` must be in [0..$(typemax(UInt32))]"))
    end
end
murmur32(key::Union{AbstractString,Array{UInt8}}) = murmur32(key, UInt32(0))

@inline rotl32(x::UInt32, r::Integer)::UInt32 = (x << r) | (x >> (32 - r))

@inline function fmix32(h::UInt32)::UInt32
    h = h ⊻ h >> 16
    h *= 0x85ebca6b
    h = h ⊻ h >> 13
    h *= 0xc2b2ae35
    h = h ⊻ h >> 16
end
