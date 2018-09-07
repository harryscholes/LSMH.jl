"""
    fasta_records(filename)

Reads records from `filename` in FASTA format.
"""
function fasta_records(filename::String)
    records = []

    reader = FASTA.Reader(open(filename, "r"))
    for record in reader
        push!(records, record)
    end
    close(reader)

    records
end

"""
    fasta_signatures(filename, k, n)

Reads protein sequences from `filename` in FASTA format and generates `n`
minhash signatures from `k`-shingles.
"""
function fasta_signatures(filename::String, k::Int, n::Int)
    signatures = Vector{UInt32}[]
    IDs = String[]

    reader = FASTA.Reader(open(filename, "r"))
    for record in reader
        push!(signatures, signature(record, k, n))
        push!(IDs, BioSequences.FASTA.identifier(record))
    end
    close(reader)

    signatures = hcat(signatures...)  # vector of vectors -> 2D array
    (IDs=IDs, signatures=signatures)
end

"""
    signature(record, k, n)

Generates `n` minhash signatures from `k`-shingles of a biological sequence
in a FASTA record.
"""
function signature(record::BioSequences.FASTA.Record, k::Int, n::Int)
    signature(String(sequence(record)), k, n)
end
