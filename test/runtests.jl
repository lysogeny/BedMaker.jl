using Test, BedMaker

tests = [
    "genome.jl",
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
