#=
Benchmark pure Julia hash function implementations.
=#
using LSMH
using BenchmarkTools, Random, Statistics

function MurmurHash3_x86_32(s::String, seed::UInt32)
    ccall(:memhash32_seed, UInt32, (Ptr{UInt8}, Csize_t, UInt32), pointer(s),
          sizeof(s), seed % UInt32)
end
MurmurHash3_x86_32(s::String) = MurmurHash3_x86_32(s, UInt32(0))

string_lengths = [5, 10, 50, 100, 500, 1000]

A = zeros(length(string_lengths), 4)

for i = 1:length(string_lengths)
    l = string_lengths[i]
    murmur32(randstring(l))
    xxhash32(randstring(l))
    a = @benchmark murmur32($(randstring(l)))
    b = @benchmark MurmurHash3_x86_32($(randstring(l)))
    c = @benchmark xxhash32($(randstring(l)))
    A[i,1] = l
    A[i,2] = median(a.times)
    A[i,3] = median(b.times)
    A[i,4] = median(c.times)
end

A
