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
Abstract MinHash signature type.

Any subtype `S` <: `AbstractSignature` should implement the following methods:

* `identifier`: return the identifier for the signature
* `signature`: return the vector of MinHashes that constitute the signature
"""
abstract type AbstractSignature end

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
function identifier(s::AbstractSignature)::AbstractString
    isdefined(s, :id) ? s.id : throw(UndefRefError())
end

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
function signature(s::AbstractSignature)::AbstractVector{<:Unsigned}
    isdefined(s, :signature) ? s.signature : throw(UndefRefError())
end

"""
    Signature(id, signature)

Generic signature type.

# Examples
```jldoctest
julia> Signature("A", UInt32[1,2,3])
Signature{String,Array{UInt32,1}}("A", UInt8[0x01, 0x02, 0x03])
```
"""
struct Signature{I<:AbstractString,S<:AbstractVector{<:Unsigned}} <: AbstractSignature
    id::I
    signature::S
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
@inline function hashband(S::AbstractSignature, start::Int, stop::Int)
    hash(@view signature(S)[start:stop])  # TODO use 32 bit hash
end

"""
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

Base.iterate(h::HashTable) = iterate(hashtable(h))
Base.iterate(h::HashTable, i::Int) = iterate(hashtable(h), i)
Base.length(h::HashTable) = length(hashtable(h))
Base.haskey(h::HashTable, k) = haskey(hashtable(h), k)
Base.keys(h::HashTable) = keys(hashtable(h))
Base.values(h::HashTable) = values(hashtable(h))
function Base.setindex!(h::HashTable, v, k)
    if haskey(h, k)
        push!(hashtable(h)[k], v)
    else
        hashtable(h)[k] = Set([v])
    end
end

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
    filter_collisions!(hashtable)

Removes non-colliding sequences from the `hashtable`.

# Examples
```jldoctest
julia> d = Dict("A" => Set([1,2]), "B" => Set([3]));

julia> filter_collisions!(d)

julia> d
Dict{String,Set{Int64}} with 1 entry:
  "A" => Set([2, 1])
```
"""
function filter_collisions!(hashtable::AbstractDict)
    for k = keys(hashtable)
        if length(hashtable[k]) == 1
            delete!(hashtable, k)
        end
    end
end
filter_collisions!(h::HashTable) = filter_collisions!(h.hashtable)

"""
    candidates(hashtable)

Return candidate matches.
"""
function candidates(hashtable)
    v = Vector{Set}()
    sizehint!(v, length(hashtable))

    for (bucket, IDs) = hashtable
        for (i, j) = combinations(collect(IDs), 2)
            push!(v, Set([i,j]))
        end
    end

    unique!(v)
end

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
    filter_candidates(signatures, candidates, threshold)

Remove `candidates` with Jaccard similarity between their `signatures` less than
`threshold`.
"""
function filter_candidates(signatures, candidates, threshold)
    out = Vector{Tuple{Int,Int}}()

    for (i, j) = candidates
        println(i,j)
        similarity = jaccard(signatures[:,i], signatures[:,j])
        similarity >= threshold ? push!(out, (i,j)) : nothing
    end

    out
end
