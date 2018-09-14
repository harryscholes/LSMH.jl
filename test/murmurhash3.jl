"C implementation of MurmurHash3_x86_32."
function MurmurHash3_x86_32(key, seed::Integer)
    seed = UInt32(seed)
    ccall(:memhash32_seed, UInt32, (Ptr{UInt8}, Csize_t, UInt32), pointer(key),
          sizeof(key), seed % UInt32)
end

@testset "murmurhash3.jl" begin
    @testset "murmur32" begin
        s = "Hello, world!"
        @test murmur32(s) == MurmurHash3_x86_32(s, UInt32(0)) == 0xc0363e43
        @test murmur32(s, 0) == MurmurHash3_x86_32(s, UInt32(0)) == 0xc0363e43
        @test murmur32(s, 0x00000000) == MurmurHash3_x86_32(s, UInt32(0)) == 0xc0363e43
        @test murmur32(s, 1) == MurmurHash3_x86_32(s, UInt32(1)) == 0xaa5dc85b
        @test murmur32(s, 0x00000001) == MurmurHash3_x86_32(s, UInt32(1)) == 0xaa5dc85b
    end
    @testset "Strings" begin
        for seed in rand(UInt, 10)
            for l = 1:100
                s = randstring(l)
                seed = UInt32(0)
                @test murmur32(s, seed) == MurmurHash3_x86_32(s, seed)
            end
        end
    end
    @testset "Arrays" begin
        for Type in (Int8, Int16, Int32, Int64, Int128,
                     UInt8, UInt16, UInt32, UInt64, UInt128)
            V = rand(Type, 100)
            @test murmur32(V) == MurmurHash3_x86_32(V, 0)
            @test murmur32(V, 1) == MurmurHash3_x86_32(V, 1)
            A = rand(Type, 10, 10)
            @test murmur32(A) == MurmurHash3_x86_32(A, 0)
            @test murmur32(A, 1) == MurmurHash3_x86_32(A, 1)
        end
    end
    @testset "Domain check of `seed`" begin
        @test_throws DomainError murmur32("A", -1)
        @test_throws DomainError murmur32("A", typemax(UInt32)+1)
    end
end
