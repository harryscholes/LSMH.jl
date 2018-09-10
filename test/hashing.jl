using LSMH: minhash, AbstractSignature, Signature, HashTable, hashband, hashtable, band

struct BadSignature <: AbstractSignature
    badfield
end

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
    @testset "identifier" begin
        sig = Signature("ABC", UInt32[1,2,3])
        @test identifier(sig) == "ABC"

        badsig = BadSignature(nothing)
        @test_throws UndefRefError identifier(badsig)
    end
    @testset "signature" begin
        sig = Signature("ABC", UInt32[1,2,3])
        @test signature(sig) == UInt32[1,2,3]

        badsig = BadSignature(nothing)
        @test_throws UndefRefError signature(badsig)
    end
    @testset "Signature" begin
        sig = Signature("ABC", UInt32[1,2,3])
        @test isdefined(sig, :id)
        @test isdefined(sig, :signature)
    end
    @testset "hashband" begin
        sig = Signature("ABC", Array{UInt32}(1:100))
        @test hashband(sig, 1, 10) == 0xee56bf56bfc5b740
        @test hashband(sig, 11, 20) == 0x22f7fea1a9226a53
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
        @test haskey(ht, 1)
    end
end
