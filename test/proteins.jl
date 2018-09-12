@testset "proteins.jl" begin
    @testset "fasta_records" begin
        fasta_file = IOBuffer(
        """
        >seqA some description
        QIKDLLVSSSTDLDTTLKMK
        ILELPFASGDLSM
        >seqB
        VLMALGMTDLFIPSANLTG*
        """)
        records = fasta_records(fasta_file)
        @test length(records) == 2
        rec = records[1]
        @test FASTA.identifier(rec) == "seqA"
        @test FASTA.description(rec) == "some description"
        @test FASTA.sequence(rec) == AminoAcidSequence("QIKDLLVSSSTDLDTTLKMKILELPFASGDLSM")
        rec = records[2]
        @test FASTA.identifier(rec) == "seqB"
        @test FASTA.sequence(rec) == AminoAcidSequence("VLMALGMTDLFIPSANLTG*")
    end
    @testset "signature" begin
        record = FASTA.Record(
        """
        >seqA some description
        QIKDLLVSSSTDLDTTLKMK
        ILELPFASGDLSM
        """)
        sig = signature(record, 5, 2)
        @test signature(sig) == UInt32[0x05094006, 0x0afea36a]
    end
    @testset "fasta_signatures" begin
        fasta_file = IOBuffer(
        """
        >seqA some description
        QIKDLLVSSSTDLDTTLKMK
        ILELPFASGDLSM
        >seqB
        VLMALGMTDLFIPSANLTG*
        """)
        sigs = fasta_signatures(fasta_file, 5, 2)
        sig = sigs[1]
        identifier(sig) == "seqA"
        signature(sig) == UInt32[0x05094006, 0x0afea36a]
        sig = sigs[2]
        identifier(sig) == "seqB"
        signature(sig) == UInt32[0x05094006, 0x0afea36a]
    end
end
