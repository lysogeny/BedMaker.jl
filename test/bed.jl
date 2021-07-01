using BED

@testset "Test bed entry creation" begin
    reader = open("actb.gff3") |> GFF3.Reader
    genome = Genome(reader)
    genes_flat = genes(genome)
    @test typeof(BedMaker.SmallRecord.(genes_flat)) == Vector{BedMaker.SmallRecord}
    actb = filter(x -> x.meta.name == "Actb", genes_flat)[1]
    mock = BedMaker.SmallRecord(actb.pos, actb.id, 0)
    @test BedMaker.SmallRecord(actb) == mock
    custom_name = BedMaker.SmallRecord(actb, "Test") 
    @test custom_name != mock
    @test custom_name.name == "Test"
end

@testset "Test bed writing" begin
    reader = open("actb.gff3") |> GFF3.Reader
    genome = Genome(reader)
    genes_flat = genes(genome)
    records = BedMaker.SmallRecord.(genes_flat)
    out_files = Dict(
        :small_vector => tempname(), 
        :feature_vector => tempname(), 
        :small => tempname(), 
        :feature => tempname()
    )
    # Writing small records
    open(out_files[:small_vector], "w") do io
        writer = BEDWriter(io)
        write(writer, records)
    end
    # Writing features
    open(out_files[:feature_vector], "w") do io
        writer = BEDWriter(io)
        write(writer, genes_flat)
    end
    # Writing small records individually
    open(out_files[:small], "w") do io
        writer = BEDWriter(io)
        for gene in records
            write(writer, gene)
        end
    end
    # Writing features individually
    open(out_files[:feature], "w") do io
        writer = BEDWriter(io)
        for gene in genes_flat
            write(writer, gene)
        end
    end
    @testset "Check files created in `method:$key` are vaguely correct" for (key, out_file) in out_files
        open(out_file) do io
            @test countlines(io) == 2
            seekstart(io)
            content = read(io, String)
            @test length(findall("gene:ENSMUSG", content)) == 2
            @test length(findall("\t", content)) == 10
        end
    end
end

@testset "BED is readable" begin
    reader = open("actb.gff3") |> GFF3.Reader
    genome = Genome(reader)
    records = BedMaker.SmallRecord.(genes(genome))
    out_file = tempname()
    # Writing small records
    open(out_file, "w") do io
        writer = BEDWriter(io)
        write(writer, records)
    end
    open(out_file, "r") do io
        reader = BED.Reader(io)
        entries = collect(reader)
        @test length(entries) == length(records)
    end
end

#@testset "interval merges" begin
#    i1 = [(1, 3), (2, 5), (6, 9), (12, 15), (15, 17), (20, 25)]
#    [FeaturePosition(i) for i in i1]
#    FeaturePosition.(i1)
#end
