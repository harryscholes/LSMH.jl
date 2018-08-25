#=
Implementation of 32 bit xxHash by Yann Collet

https://github.com/Cyan4973/xxHash
=#
const prime1 = UInt32(2654435761)
const prime2 = UInt32(2246822519)
const prime3 = UInt32(3266489917)
const prime4 = UInt32( 668265263)
const prime5 = UInt32( 374761393)

@inline rotl(x::UInt32, r::Int)::UInt32 = (x << r) | (x >> (32 - r))

function _xxhash32(data, seed::UInt32)::UInt32
    len = length(data)
    acc::UInt32 = UInt32(0)
	i = n = 1
    bytes = Ptr{UInt8}(pointer(data))
    words = Ptr{UInt32}(pointer(data))

	if len >= 16
        limit = len - 15
        acc1::UInt32 = seed + prime1 + prime2
        acc2::UInt32 = seed + prime2
        acc3::UInt32 = seed
        acc4::UInt32 = seed - prime1

        @inbounds for _ = 1:16:limit
            acc1 = rotl(acc1 + unsafe_load(words, n  ) * prime2, 13) * prime1
            acc2 = rotl(acc2 + unsafe_load(words, n+1) * prime2, 13) * prime1
            acc3 = rotl(acc3 + unsafe_load(words, n+2) * prime2, 13) * prime1
            acc4 = rotl(acc4 + unsafe_load(words, n+3) * prime2, 13) * prime1
            i += 16
            n += 4
        end

        acc = rotl(acc1, 1) + rotl(acc2, 7) + rotl(acc3, 12) + rotl(acc4, 18)
    else
        acc = seed + prime5
    end

    acc += len

    @inbounds for _ = i:4:len-3
        acc = acc + unsafe_load(words, n) * prime3
        acc = rotl(acc, 17) * prime4
        i += 4
        n += 1
    end

    @inbounds for _ = i:len
        acc = acc + unsafe_load(bytes, i) * prime5
        acc = rotl(acc, 11) * prime1
        i += 1
    end

    acc = acc ⊻ acc >> 15
    acc = acc * prime2
    acc = acc ⊻ acc >> 13
    acc = acc * prime3
    acc = acc ⊻ acc >> 16
end

const Hashable = Union{AbstractString,Array{UInt8}}
xxhash32(key::Hashable)::UInt32 = _xxhash32(key, UInt32(0))
xxhash32(key::Hashable, seed::UInt32)::UInt32 = _xxhash32(key, seed)
xxhash32(key::Hashable, seed::Int)::UInt32 = _xxhash32(key, UInt32(seed))

"""
    xxhash32(key [, seed])

32 bit hash of `key` using xxHash, optionally seeded with `seed`.
"""
xxhash32
