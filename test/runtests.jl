using Test, BedMaker

tests = [
    "intervals.jl",
    "genome.jl",
    "bed.jl",
]

for test in tests
    try
        include(test)
        println("PASSED: $test")
    catch e
        println("FAILED: $test")
        rethrow(e)
    end
end
