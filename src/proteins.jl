"""
    fasta_records(filename::AbstractString)
    fasta_records(fasta_file::IO)

Reads records from a file in FASTA format.

If `filename::AbstractString`, first opens the file.

# Examples
```jldoctest
julia> fasta_file = IOBuffer(
\"\"\"
>seqA some description
QIKDLLVSSSTDLDTTLKMK
ILELPFASGDLSM
\"\"\");

julia> records = fasta_records(fasta_file)
1-element Array{BioSequences.FASTA.Record,1}:
 BioSequences.FASTA.Record:
   identifier: seqA
  description: some description
     sequence: QIKDLLVSSSTDLDTTLKMKILELPFASGDLSM
```
"""
function fasta_records(fasta_file::IO)
    records = Vector{BioSequences.FASTA.Record}()

    reader = FASTA.Reader(fasta_file)
    for record in reader
        push!(records, record)
    end
    close(reader)

    records
end
fasta_records(filename::AbstractString) = fasta_records(open(filename, "r"))

"""
    signature(record, k, n)

Generates `n` minhash signatures from `k`-shingles of a biological sequence
in a FASTA record.
"""
function signature(record::BioSequences.FASTA.Record, k::Int, n::Int)
    id = FASTA.identifier(record)
    sig = signature(String(sequence(record)), k, n)
    Signature(id, sig)
end

"""
    fasta_signatures(filename::AbstractString, k, n)
    fasta_signatures(fasta_file::IO, k, n)

Reads protein sequences from `filename` in FASTA format and generates `n`
minhash signatures from `k`-shingles.

# Examples
```jldoctest
julia> fasta_file = IOBuffer(
\"\"\"
>seqA some description
QIKDLLVSSSTDLDTTLKMK
ILELPFASGDLSM
>seqB
VLMALGMTDLFIPSANLTG*
\"\"\");

julia> sigs = fasta_signatures(fasta_file)
2-element Array{Signature,1}:
 Signature{String,Array{UInt32,1}}("seqA", UInt32[0x05094006, 0x0afea36a])
 Signature{String,Array{UInt32,1}}("seqB", UInt32[0x1380e49b, 0x17854bad])
```
"""
function fasta_signatures(fasta_file::IO, k::Int, n::Int)
    signatures = Vector{Signature}()

    reader = FASTA.Reader(fasta_file)
    for record in reader
        push!(signatures, LSMH.signature(record, k, n))
    end
    close(reader)

    signatures
end
function fasta_signatures(filename::AbstractString, k::Int, n::Int)
    fasta_signatures(open(filename, "r"), k, n)
end
