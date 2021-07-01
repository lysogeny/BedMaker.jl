
using BedMaker: FeaturePosition, isoverlap_sticky, isoverlap

@testset "FeaturePosition construction" begin
    pos = FeaturePosition("1", 1, 10, '+')
    @test pos.pos.start == 1
    @test pos.pos.stop == 10
    @test Char(pos.strand) == '+'
    @test pos.seqid == "1"
    pos = FeaturePosition("1", Interval(1, 10), '+')
    @test pos.pos.start == 1
    @test pos.pos.stop == 10
    @test Char(pos.strand) == '+'
    @test pos.seqid == "1"
    pos = FeaturePosition("1", (1, 10), '+')
    @test pos.pos.start == 1
    @test pos.pos.stop == 10
    @test Char(pos.strand) == '+'
    @test pos.seqid == "1"
end

@testset "FeaturePosition can union elements in same group" begin
    # Simple merge, two things on same group
    pos = [FeaturePosition("1", 1, 10, '+'),
           FeaturePosition("1", 5, 12, '+')]
    @test BedMaker.grouping_value(pos[1]) == ("1", BedMaker.strand_pos)
    pos_group = BedMaker.group(pos)
    @test all(pos_group .== [1, 1])
    merged = union(pos)
    @test length(merged) == 1
    @test merged[1] == FeaturePosition("1", 1, 12, '+')
end

@testset "FeaturePosition can union things on different strands" begin
    # Simple merge, two things on different groups
    pos = [FeaturePosition("1", 1, 10, '+'),
           FeaturePosition("1", 5, 12, '-')]
    pos_group = BedMaker.group(pos)
    @test all(pos_group .== [1, 2])
    merged = union(pos)
    @test length(merged) == 2
    @test all([m in pos for m in merged]) # no guarantee of order preservation
end

@testset "FeaturePosition can union things on different chromosomes" begin
    # Simple merge, two things on different groups
    pos = [FeaturePosition("1", 1, 10, '+'),
           FeaturePosition("2", 5, 12, '+')]
    pos_group = BedMaker.group(pos)
    @test all(pos_group .== [1, 2])
    merged = union(pos)
    @test length(merged) == 2
    @test all([m in pos for m in merged]) # no guarantee of order preservation
end

@testset "FeaturePosition can union things on different chromosomes" begin
    # Simple merge, two things on different groups
    pos = [FeaturePosition("1", 1, 10, '+'),
           FeaturePosition("1", 5, 12, '+'),
           FeaturePosition("1", 15, 20, '+')]
    output = [FeaturePosition("1", 1, 12, '+'), FeaturePosition("1", 15, 20, '+')]
    pos_group = BedMaker.group(pos)
    @test all(pos_group .== [1, 1, 1])
    merged = union(pos)
    @test length(merged) == 2
    @test all([m in output for m in merged]) # no guarantee of order preservation
end
