"""
    fasta_records(filename)

Reads records from `filename` in FASTA format.
"""
function fasta_records(filename::AbstractString)
    records = []

    reader = FASTA.Reader(open(filename, "r"))
    for record in reader
        push!(records, record)
    end
    close(reader)

    records
end

"""
    signature(record, k, n)

Generates `n` minhash signatures from `k`-shingles of a biological sequence
in a FASTA record.
"""
function signature(record::BioSequences.FASTA.Record, k::Int, n::Int)
    id = BioSequences.FASTA.identifier(record)
    sig = signature(String(sequence(record)), k, n)
    Signature(id, sig)
end

"""
    fasta_signatures(filename, k, n)

Reads protein sequences from `filename` in FASTA format and generates `n`
minhash signatures from `k`-shingles.
"""
function fasta_signatures(filename::AbstractString, k::Int, n::Int)
    signatures = []

    reader = FASTA.Reader(open(filename, "r"))
    for record in reader
        push!(signatures, signature(record, k, n))
    end
    close(reader)

    signatures
end
