using BedMaker: Interval, isoverlap, group_overlaps, isoverlap_sticky

@testset "Check interval only can be stop>=start" begin
    i = Interval(1, 2)
    @test i.start == 1
    @test i.stop == 2
    i = Interval((1, 2))
    @test i.start == 1
    @test i.stop == 2
    @test_throws ArgumentError Interval(2, 1) # Have to be properly sorted
    @test_throws InexactError Interval(-1, 1) # Negative not supported
end

@testset "Check overlaps are detected" begin
    @test isoverlap(Interval(1, 5), Interval(3, 7)) # no overlap
    @test isoverlap(Interval(3, 7), Interval(1, 5)) # no overlap, reversed
    @test !isoverlap(Interval(1, 5), Interval(6, 7)) # sticky overlap isn't technically an overlap
    @test isoverlap_sticky(Interval(1, 5), Interval(6, 7)) # but a sticky overlap
    @test !isoverlap_sticky(Interval(1, 5), Interval(7, 9)) # but a sticky overlap
    @test !isoverlap(Interval(1, 5), Interval(7, 17)) # not overlap
    @test !isoverlap(Interval(7, 17), Interval(1, 5)) # not overlap, reversed
    # Vector overlaps
    #@test !isoverlap([Interval(1, 5)], [Interval(7, 8)]) 
    #@test isoverlap([Interval(1, 5)], [Interval(3, 8)]) 
    #@test !isoverlap([Interval(1, 5)], [Interval(6, 8)]) 
    #@test isoverlap_sticky([Interval(1, 5)], [Interval(6, 8)]) 
    #@test isoverlap_sticky([Interval(1, 5)], [Interval(12, 15)]) 
end

@testset "Check intervals are sortable" begin
    @test Interval(1, 2) < Interval(3, 5)
    @test Interval(1, 2) < Interval(1, 5)
    @test !(Interval(1, 2) < Interval(1, 2))
    @test sort([Interval(3, 5), Interval(1, 2)]) == [Interval(1, 2), Interval(3, 5)]
    @test issorted([Interval(1, 2), Interval(3, 5)])
end

@testset "Check overlap groups are detected" begin
    @test_throws ArgumentError group_overlaps([Interval(5, 10), Interval(1, 2)])
    # works with many intervals
    @testset "Big group works" begin
        i = [(1, 10), (9, 12), (13, 15), (20, 25), (29, 35), (35, 90), (60, 100)]
        g = [1, 1, 1, 2, 3, 3, 3]
        grouped = group_overlaps(Interval.(i))
        @test grouped[end] == 3
        @test length(grouped) == 7
        @test all(grouped .== g)
    end
    @testset "Single interval vector works" begin
        # Works with single interval
        i = [(1, 10)]
        g = [1]
        grouped = group_overlaps(Interval.(i))
        @test grouped[end] == 1
        @test length(grouped) == 1
        @test all(grouped .== g)
    end
    @testset "Empty vector works" begin
        # works with zero interval
        i = Interval[]
        g = []
        grouped = group_overlaps(i)
        @test length(grouped) == 0
    end
end

@testset "Check intervals can merge" begin
    i = [(1, 10), (9, 12), (13, 15), (20, 25), (29, 35), (35, 90), (60, 100)]
    o = [(1, 15), (20, 25), (29, 100)]
    i = Interval.(i)
    o = Interval.(o)
    @test all(union(i) .== o)
end
