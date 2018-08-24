struct MinHash{U<:Unsigned}
    minhash::U
    kmer::String
end

"""
    minhash(sequence::String, k::Int, [seed<:UInt])

Split `sequence` into `k`-shingles and hash using a `seed`ed hash function.
"""
function minhash(sequence::String, k::Int, seed::UInt)
    mh = UInt64_Max

    for i = 1:length(sequence)-k
        ch = hash(SubString(sequence, i:i+k-1), UInt(seed))

        if ch < mh
            mh = ch
        end
    end

    mh
end

minhash(sequence::String, k::Int, seed::Int) = minhash(sequence, k, UInt(seed))
minhash(sequence::String, k::Int) = minhash(sequence, k, UInt(0))

"""
"""
function minhash_with_sequence(sequence::String, k::Int, seed::UInt)
    mh = UInt64_Max
    seq = nothing

    for i = 1:length(sequence)-shingle_length
        shingle = SubString(sequence, i:i+shingle_length-1)
        ch = hash(shingle, UInt(seed))

        if ch < mh
            mh = ch
            seq = shingle
        end
    end

    MinHash(mh, string(seq))
end

minhash_with_sequence(sequence::String, k::Int, seed::Int) = minhash(sequence, k, UInt(seed))
minhash_with_sequence(sequence::String, k::Int) = minhash(sequence, k, UInt(0))

"""
    signature(sequence::String, k::Int, n_hashes::Int)

Split `sequence` into `k`-shingles and hash using `n_hashes` hash functions.
"""
function signature(sequence::String, k::Int, n_hashes::Int)
    A = Vector{UInt64}(1:n_hashes)

    for seed = 1:n_hashes
        A[seed] = minhash(sequence, k, seed)
    end

    A
end

"""
    lsh(A, n_bands)

Hashes signatures into buckets. For a signature matrix `A` of
(n_hashes,n_sequences), each signature is split into `n_bands` and hashed.
"""
function lsh(A::AbstractArray{T,2}, n_bands::Int) where T<:Unsigned
    n_hashes = size(A)[1]
    step = Int(n_hashes/n_bands)

    hashtable = [Dict{T,Set{Int}}() for _ in 1:n_bands]

    for col = 1:size(A)[2]
        for (band, ptr) = zip(1:n_bands, 1:step:n_hashes)
            h = hash(view(A, ptr:ptr+step-1, col))

            if haskey(hashtable[band], h)
                push!(hashtable[band][h], col)
            else
                hashtable[band][h] = Set([col])
            end
        end
    end

    hashtable
end

"""
    candidates(hashtable)

Return candidate matches.
"""
function candidates(hashtable)
    c = Vector{Set{Int}}()

    for band = hashtable
        for (bucket, ids) = band
            if length(ids) > 1
                for (i, j) = combinations(collect(ids), 2)
                    push!(c, Set([i,j]))
                end
            end
        end
    end

    unique!(c)
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
