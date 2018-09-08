using LSMH: minhash, AbstractSignature, Signature

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
end
