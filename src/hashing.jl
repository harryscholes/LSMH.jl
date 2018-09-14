import Base: iterate, length, keys, values, haskey, delete!, size, getindex,
             IndexStyle

# MinHashing

"""
    minhash(s, k[, seed])

Split `s` into `k`-shingles and hash the shingles using a hash function seeded
by `seed`.

# Examples
```jldoctest
julia> minhash("Hello, world!", 5)
0x12da77c8

julia> minhash("Hello, world!", 5, 1)
0x2011211e
```
"""
@inline function minhash(s::AbstractString, k::Int, seed::Integer)
    k > 1 || throw(DomainError("`k` must be >= 2"))
    seed >= 0 || throw(DomainError("`seed` must be >= 0"))

    h = typemax(UInt32)

    for i = 1:length(s)-k+1
        hᵢ = murmur32(SubString(s, i:i+k-1), seed)

        if hᵢ < h
            h = hᵢ
        end
    end

    h
end
minhash(s::AbstractString, k::Int) = minhash(s, k, 0)

"""
    signature(s, k, n)

Split `s` into `k`-shingles and hash using `n` hash functions. The ith hash
function will be seeded with i.

# Examples
```jldoctest
julia> signature("Hello, world!", 5, 3)
3-element Array{UInt32,1}:
 0x2011211e
 0x1134f986
 0x291d3c45

julia> signature("Hello, world!", 6, 2)
2-element Array{UInt32,1}:
 0x441d7a91
 0x1af9b8f8
```
"""
function signature(s::AbstractString, k::Int, n::Int)
    k > 1 || throw(DomainError("`k` must be >= 2"))
    n > 0 || throw(DomainError("`n` must be >= 1"))

    A = Vector{UInt32}(undef, n)

    for seed = 1:n
        A[seed] = minhash(s, k, seed)
    end

    A
end

"""
    AbstractSignature{T} <: AbstractVector{T}

Abstract MinHash signature type.

Any subtype `S` <: `AbstractSignature` should implement the following methods:

* `identifier`: return the identifier for the signature
* `signature`: return the vector of MinHashes that constitute the signature
"""
abstract type AbstractSignature{T} <: AbstractVector{T} end

identifier(s::AbstractSignature) = s.id
signature(s::AbstractSignature) = s.signature
size(s::AbstractSignature) = size(signature(s))
getindex(s::AbstractSignature, i::Int) = getindex(signature(s), i)
IndexStyle(::AbstractSignature) = IndexLinear()

"""
    identifier(s::AbstractSignature)

Return the identifier for the signature `s`.

# Examples
```jldoctest
julia> s = Signature("ABC", UInt8[1,2,3]);

julia> identifier(s)
"ABC"
```
"""
identifier

"""
    signature(s::AbstractSignature)

Return the vector of MinHashes that constitute the signature `s`.

# Examples
```jldoctest
julia> s = Signature("ABC", UInt8[1,2,3]);

julia> signature(s)
3-element Array{UInt8,1}:
 0x01
 0x02
 0x03
```
"""
signature

"""
    Signature(id, signature)

Generic signature type.

# Examples
```jldoctest
julia> Signature("A", UInt32[1,2,3])
Signature{String,Array{UInt32,1}}("A", UInt8[0x01, 0x02, 0x03])
```
"""
struct Signature{T<:Unsigned} <: AbstractSignature{T}
    id::String
    signature::Vector{T}
end

"""
    hashband(signature, start, stop)

Hashes a band of `signature` from `start` to `stop` into a bucket.

# Examples
```jldoctest
julia> struct Signature <: AbstractSignature
           id
           signature
       end

julia> s = Signature("ID123", UInt32[1,2,3,4]);

julia> hashband(s, 1, 2)
0x8fd27f36c41781c8

julia> hashband(s, 3, 4)
0xad365722dfd05b0d
```
"""
@inline function hashband(s::AbstractSignature, start::Int, stop::Int)
    hash(@view s[start:stop])  # TODO use 32 bit hash
end

# HashTable

"""
    HashTable(band, hashtable)
    HashTable(K, V, band)

Construct a hashtable.

# Examples
```jldoctest
julia> h = HashTable(String, Int, 1)

julia> h["A"] = 1;

julia> h["A"] = 2;

julia> h
HashTable{String,Int64} with 1 entry:
  "A" => Set([2, 1])
```
"""
struct HashTable{K,V} <: AbstractDict{K,Set{V}}
    band::Int
    hashtable::Dict{K,Set{V}}
end
HashTable(K::Type, V::Type, band::Int) = HashTable(band, Dict{K,Set{V}}())

band(h::HashTable) = h.band
hashtable(h::HashTable) = h.hashtable

for f in (:iterate, :length, :keys, :values)
    @eval ($f)(h::HashTable) = ($f)(hashtable(h))
end
for f in (:haskey, :delete!)
    @eval ($f)(h::HashTable, k) = ($f)(hashtable(h), k)
end
function Base.setindex!(h::HashTable, v, k)
    haskey(h, k) ? push!(hashtable(h)[k], v) : hashtable(h)[k] = Set([v])
end
Base.iterate(h::HashTable, i::Int) = iterate(hashtable(h), i)
Base.get(h::HashTable, k, default) = get(hashtable(h), k, default)

# LSH

"""
    lsh(signature, bands)

Splits a `signature` into `bands` bands which are hashed into buckets.

# Examples
```jldoctest
julia> signatures = [Signature("A", UInt32[1,2,3,4]), Signature("B", UInt32[1,2,5,6])];

julia> lsh(signatures, 2)
2-element Array{LSMH.HashTable{UInt64,Set{String}},1}:
 LSMH.HashTable{UInt64,Set{String}}(1, Dict(0x8fd27f36c41781c8=>Set(["B", "A"])))
 LSMH.HashTable{UInt64,Set{String}}(2, Dict{UInt64,Set{String}}())
```
"""
function lsh(signatures::AbstractVector{<:AbstractSignature}, bands::Int)
    hashtables = [HashTable(UInt64, String, b) for b = 1:bands]

    for s = signatures
        buckets = lsh(s, bands)

        for b = 1:bands
            hashtable = hashtables[b]
            bucket = buckets[b]
            hashtable[bucket] = identifier(s)
        end
    end

    map(filter_collisions!, hashtables)
    hashtables
end
function lsh(S::AbstractSignature, bands::Int)::Vector{<:Unsigned}
    step = div(size(signature(S))[1], bands)
    buckets = Vector{UInt64}(undef, bands)

    for i = 1:bands
        start = (i - 1) * step + 1
        buckets[i] = hashband(S, start, start+step-1)
    end

    buckets
end

"""
    filter_collisions!(d)

Removes non-colliding sequences from `d`.

Often `d<:AbstractDict{K,<:AbstractSet{V}}`.

# Examples
```jldoctest
julia> d = Dict("A" => Set([1,2]), "B" => Set([3]));

julia> filter_collisions!(d)

julia> d
Dict{String,Set{Int64}} with 1 entry:
  "A" => Set([2, 1])
```
"""
function filter_collisions!(d::AbstractDict)
    for k = keys(d)
        if length(d[k]) == 1
            delete!(d, k)
        end
    end
end

# Similarity

"""
    jaccard(a, b)

Calculate Jaccard similarity of two sets.

# Examples
```jldoctest
julia> jaccard(1:100, 2:100)
0.99

julia> jaccard([], [])
1.0
```
"""
function jaccard(a::T, b::T) where T<:Union{AbstractVector,AbstractSet}
    length(a) == 0 && length(b) == 0 && return 1.
    a = Set(a)
    b = Set(b)
    length(a ∩ b) / length(a ∪ b)
end

"""
    candidates(d)

Return pairs of candidate matches from `d`.

# Examples
```jldoctest
julia> d = Dict(nothing => Set([1,2,3]));

julia> candidates(d)
3-element Array{Set{Int64},1}:
 Set([2, 3])
 Set([2, 1])
 Set([3, 1])
```
"""
function candidates(d::AbstractDict)
    v = Vector{Set{eltype(eltype(values(hashtable)))}}()
    sizehint!(v, length(d))

    for (bucket, IDs) = d
        for (i, j) = combinations(collect(IDs), 2)
            push!(v, Set([i,j]))
        end
    end

    unique!(v)
end

# """
#     filter_candidates(signatures, candidates, threshold)
#
# Remove `candidates` with Jaccard similarity between their `signatures` less than
# `threshold`.
# """
# function filter_candidates(signatures, candidates, threshold)
#     out = Vector{Tuple{Int,Int}}()
#
#     for (i, j) = candidates
#         println(i,j)
#         similarity = jaccard(signatures[:,i], signatures[:,j])
#         similarity >= threshold ? push!(out, (i,j)) : nothing
#     end
#
#     out
# end
