"C implementation of MurmurHash3_x86_32."
function MurmurHash3_x86_32(s::String, seed::UInt32)
    ccall(:memhash32_seed, UInt32, (Ptr{UInt8}, Csize_t, UInt32), pointer(s),
          sizeof(s), seed % UInt32)
end

@testset "murmurhash3.jl" begin
    @testset "murmur32 agreement with C implementation" begin
        for seed in rand(UInt, 10)
            for l = 1:100
                s = randstring(l)
                seed = UInt32(0)
                @test murmur32(s, seed) == MurmurHash3_x86_32(s, seed)
            end
        end
    end
    @testset "murmur32" begin
        s = "Hello, world!"
        @test murmur32(s) == MurmurHash3_x86_32(s, UInt32(0)) == 0xc0363e43
        @test murmur32(s, 0) == MurmurHash3_x86_32(s, UInt32(0)) == 0xc0363e43
        @test murmur32(s, 0x00000000) == MurmurHash3_x86_32(s, UInt32(0)) == 0xc0363e43
        @test murmur32(s, 1) == MurmurHash3_x86_32(s, UInt32(1)) == 0xaa5dc85b
        @test murmur32(s, 0x00000001) == MurmurHash3_x86_32(s, UInt32(1)) == 0xaa5dc85b
    end
    @testset "DomainError" begin
        @test_throws DomainError murmur32("A", -1)
        @test_throws DomainError murmur32("A", typemax(UInt32)+1)
    end
end
