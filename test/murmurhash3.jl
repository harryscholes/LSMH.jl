"C implementation of MurmurHash3_x86_32."
function MurmurHash3_x86_32(s::String, seed::UInt32)
    ccall(:memhash32_seed, UInt32, (Ptr{UInt8}, Csize_t, UInt32), pointer(s),
          sizeof(s), seed % UInt32)
end

@testset "Test agreement of Julia and C implementations of MurmurHash3_x86_32" begin
    for seed in rand(UInt, 10)
        for l in 1:100
            for _ = 1:100
                s = randstring(l)
                seed = UInt32(0)
                @test murmur32(s, seed) == MurmurHash3_x86_32(s, seed)
            end
        end
    end
end
