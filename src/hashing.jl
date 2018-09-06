"""
    minhash(s, k[, seed])

Split `s` into `k`-shingles and hash the shingles using a hash function seeded
by `seed`.
"""
@inline function minhash(s::AbstractString, k::Int, seed::Integer)
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
"""
function signature(s::AbstractString, k::Int, n::Int)
    A = Vector{UInt32}(undef, n)

    for seed = 1:n
        A[seed] = minhash(s, k, seed)
    end

    A
end

"""
    lsh(A, bands)

Hashes signatures into buckets. For a signature matrix `A` of (m hashes × n
sequences), each signature is split into `bands` bands and hashed.

------------------------
    seq1 seq2 seq3 seq4
   ---------------------
h1
h2        band 1
h3
   ---------------------
h4
h5        band 2
h6
   ---------------------
h7
h8        band 3
h9
------------------------
"""
function lsh(A::AbstractArray{T,2}, bands::Int) where T<:Unsigned
    step = div(size(A)[1], bands)
    hashtables = Vector{Dict}()

    for bandᵢ = 1:bands
        start = (bandᵢ - 1) * step + 1
        band = @view A[start:start+step-1, :]
        push!(hashtables, hashband(band))
    end

    hashtables
end

"""
    hashband(band)

Hashes a `band` (m hashes × n sequences) into a hashtable mapping hashes of each
sequence's band to sequence IDs.
"""
@inline function hashband(band::AbstractArray{<:Unsigned,2})
    hashtable = Dict{UInt64,Set}()

    for j = 1:size(band)[2]
        hashes = @view band[:, j]

        # TODO use 32 bit hash
        h = hash(hashes)

        # TODO use e.g. UniProt IDs as values in the hashtable
        sequenceⱼ = j

        if haskey(hashtable, h)
            push!(hashtable[h], sequenceⱼ)
        else
            hashtable[h] = Set([sequenceⱼ])
        end
    end

    filter_collisions!(hashtable)
    hashtable
end

"""
    filter_collisions!(hashtable)

Removes non-colliding sequences from the `hashtable`.
"""
function filter_collisions!(hashtable)
    for k = keys(hashtable)
        if length(hashtable[k]) == 1
            delete!(hashtable, k)
        end
    end
end

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
"""
jaccard(a::T, b::T) where T<:AbstractArray = sum(a .== b) / length(a)

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
