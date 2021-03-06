using LSMH: filter_collisions!

minhash = LSMH.minhash

@testset "hashing.jl" begin
    @testset "minhash" begin
        s = "Hello, world!"

        @test minhash(s, 5) == 0x12da77c8
        @test minhash(s, 5, 0) == 0x12da77c8
        @test minhash(s, 5, 1) == 0x2011211e

        @test_throws DomainError minhash(s, 1)
        @test_throws DomainError minhash(s, 2, -1)
    end
    @testset "signature" begin
        s = "Hello, world!"

        @test signature(s, 5, 3) == UInt32[0x2011211e,0x1134f986,0x291d3c45]
        @test signature(s, 2, 2) == UInt32[0x09cf7d74,0x0a6f416e]

        @test_throws DomainError signature(s, 1, 3)
        @test_throws DomainError signature(s, 2, 0)
    end
    @testset "AbstractSignature" begin
        sig = Signature("ABC", UInt32[1,2,3])

        @test identifier(sig) == "ABC"
        @test signature(sig) == UInt32[1,2,3]

        @testset "Signature" begin
            @test isdefined(sig, :id)
            @test isdefined(sig, :signature)
        end
    end
    @testset "hashband" begin
        sig = Signature("ABC", Array{UInt32}(1:100))
        @test hashband(sig, 1, 10) == 0x83af1d94
        @test hashband(sig, 11, 20) == 0x531e9145
    end
    @testset "HashTable" begin
        ht = HashTable(UInt32, Int, 1)
        @test isdefined(ht, :band)
        @test isdefined(ht, :hashtable)
        @test band(ht) == 1
        ht[UInt32(1)] = 100
        @test hashtable(ht) == Dict{UInt32, Set{Int}}(1 => Set([100]))
        ht[UInt32(1)] = 100
        @test hashtable(ht) == Dict{UInt32, Set{Int}}(1 => Set([100]))
        ht[UInt32(1)] = 101
        @test hashtable(ht) == Dict{UInt32, Set{Int}}(1 => Set([100,101]))
        @test length(ht) == 1
        ht[UInt32(2)] = 101
        @test length(ht) == 2
        @test haskey(ht, UInt32(1))
    end
    @testset "lsh" begin
        A = Signature("A", UInt32[1,2,3,4])
        B = Signature("B", UInt32[1,2,5,6])
        @test lsh(A, 2) == UInt32[0xc3642e86, 0xe68b97c2]
        @test lsh(B, 2) == UInt32[0xc3642e86, 0x584cfdb6]

        C = Signature("C", UInt32[2,3,5,6])
        signatures = [A, B, C]
        candiate_duplicates = lsh(signatures, 2)

        candiate_duplicates[1].band
        @test collect(values(candiate_duplicates[1]))[1] == Set(["A", "B"])
        @test collect(values(candiate_duplicates[2]))[1] == Set(["B", "C"])
    end
    @testset "filter_collisions!" begin
        d = Dict("A" => Set([1,2]), "B" => Set([3]))
        ht = HashTable(1, d)
        filter_collisions!(ht)
        @test hashtable(ht) == Dict("A" => Set([1,2]))
        filter_collisions!(d)
        @test d == Dict("A" => Set([1,2]))
    end
    @testset "jaccard" begin
        @test jaccard(1:100, 2:100) == .99
        @test jaccard([], []) == 1.
    end
    @testset "candidates" begin
        d = Dict(nothing => Set([1,2,3]))
        @test candidates(d) == Vector{Set{Int}}([Set([2,3]),Set([2,1]),Set([3,1])])
    end
end
