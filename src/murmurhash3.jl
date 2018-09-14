#=
MurmurHash3 was written by Austin Appleby, and is placed in the public
domain.
=#
const c1 = 0xcc9e2d51
const c2 = 0x1b873593

function _murmur32(data::Union{AbstractString,AbstractVector{UInt8}}, seed::UInt32)::UInt32
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

function _check_seed(k::Union{AbstractString,AbstractVector{UInt8}}, s::Integer)
    try
        _murmur32(k, UInt32(s))
    catch InexactError
        throw(DomainError(s, "`seed` must be in [0..$(typemax(UInt32))]"))
    end
end

murmur32(k::AbstractVector{UInt8}, s::Integer)    = _check_seed(k, s)
murmur32(k::AbstractVector{UInt8})                = _murmur32(k, UInt32(0))
murmur32(k::AbstractString, s::Integer)           = _check_seed(k, s)
murmur32(k::AbstractString)                       = _murmur32(k, UInt32(0))
murmur32(k::AbstractVector{<:Number}, s::Integer) = _check_seed(reinterpret(UInt8, k), s)
murmur32(k::AbstractVector{<:Number})             = murmur32(reinterpret(UInt8, k))
murmur32(k::AbstractArray{<:Number}, s::Integer)  = murmur32(vec(k), s)
murmur32(k::AbstractArray{<:Number})              = murmur32(vec(k))

"""
    murmur32(key::AbstractArray{<:Number}[, seed])
    murmur32(key::AbstractString[, seed])

Hash `key` to a `UInt32` using the 32 bit MurmurHash3 hashing function, optionally
seeded with `seed`.
"""
murmur32

@inline rotl32(x::UInt32, r::Integer)::UInt32 = (x << r) | (x >> (32 - r))

@inline function fmix32(h::UInt32)::UInt32
    h = h ⊻ h >> 16
    h *= 0x85ebca6b
    h = h ⊻ h >> 13
    h *= 0xc2b2ae35
    h = h ⊻ h >> 16
end
