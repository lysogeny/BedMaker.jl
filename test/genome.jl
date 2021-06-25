# Test that genomes can be read and contain the expected information.

using GFF3

@testset "Test reading on actb" begin
    reader = open("actb.gff3") |> GFF3.Reader
    genome = Genome(reader)
    gene_ids = filter(x -> occursin("gene", x), keys(genome.features))
    genes = Dict(gene_id => genome.features[gene_id] for gene_id in gene_ids)
    genes_flat = genes |> values |> collect
    @test length(genes_flat) == 2
    actb = filter(x -> x.meta.name == "Actb", genes_flat)[1]
    @test actb.meta.name == "Actb"
    @test actb.id == "gene:ENSMUSG00000029580"
    @test length(actb.children) == 9
    @test actb.meta.type == "gene"
    @test all([child.parent === actb for child in actb.children])
    prot_coding = filter(x -> x.meta.type == "mRNA", actb.children)
end
