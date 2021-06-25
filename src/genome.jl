
"""Genome

A collection of Features.
Structed as follows:

- `name::String`: Name for this genome. Not used outside of printing.
- `sequence_regions::Dict{String, Vector{Feature}}`: Dictionary with one Vector of Features for each reference sequence (chromosome or other contig)
- `features::Dict{String, Feature}`: Dictionary of IDs which only have a single feature associated.
"""

mutable struct Genome
    name::String
    sequence_regions::Dict{String, Vector{Feature}}
    features::Dict{String, Feature}
end

function Genome(; name="")
    Genome(name,
           Dict{String, Vector{Feature}}(),
           Dict{String, Feature}())
end

"""Genome(reader::GFF3.Reader; name="", progress=true, skipcrap=true)

Parses a genome and returns a hierarchically structured representation of the GFF3

## Arguments

- `reader::GFF3.Reader` a GFF3 reader from the GFF3 library
- `name=""` Name for this genome
- `progress=true` show progress during reading?
- `skipcrap=true` skip idless features (see details)

## Details:

Features that have no id or parent id are uninteresting. They
likely are some `biological_region` or other non genomic-crap.
The default is to ignore them.
"""
function Genome(reader::GFF3.Reader; name="", progress=true, skipcrap=true)
    # First a filtering reader to only return things that have either parent,
    # id or both (optional).
    # Then an insertion thingy to insert these into the correct thingy
    sequence_regions = DefaultDict{String, Vector{Feature}}(Vector{Feature})
    features = DefaultDict{String, Vector{Feature}}(Vector{Feature})
    record = GFF3.Record()
    i = 0
    while !eof(reader)
        read!(reader, record)
        i += 1
        if (i % 1_000 == 0) & progress
            print("\r")
            print("Processed $i entries, ")
            print("now at $(length(features)) id features ")
            print("$(sum(length.(values(sequence_regions)))) total ")
        end
        keys = [attr.first for attr in GFF3.attributes(record)]
        if !("ID" in keys) & !("Parent" in keys) & skipcrap
            continue
        end
        feature = Feature(record)
        # familial relationships are defined.
        parent_features = get(features, feature.parent_id, Feature[])
        if (length(parent_features) == 1)
            feature.parent = parent_features[1]
        end
        if feature.parent != nothing
            push!(feature.parent.children, feature)
        end
        push!(sequence_regions[feature.pos.seqid], feature)
        if feature.id != nothing
            push!(features[feature.id], feature)
        end
    end
    features = Dict(key => value[1]
                    for (key, value) in features
                    if length(value) == 1)
    if progress
        print("\n")
    end
    Genome(name, sequence_regions, features)
end

function Base.show(io::IO, ::MIME"text/plain", genome::Genome)
    print(io, "Genome $(genome.name)")
    sequence_count = length(keys(genome.sequence_regions))
    plural_print(io, sequence_count, "Sequence region", level=1)
    feature_count = sum(length.(values(genome.sequence_regions)))
    plural_print(io, feature_count, "Total feature", level=1)
    id_count = length(genome.features)
    plural_print(io, id_count, "Unique ID Feature", level=2)
    primary_count = mapreduce(x -> x.parent_id == nothing, +, values(genome.features))
    plural_print(io, primary_count, "Top level ID", level=2)
end

function features(genome::Genome)
    vcat(values(genome.sequence_regions)...)
end

function features(genome::Genome, fun::Function)
    filter(fun, features(genome))
end

function features_with_id(genome::Genome)
    features(genome, x -> x.id != nothing)
end

function features_with_id(genome::Genome, fun::Function)
    filter(fun, features_with_id(genome))
end

# Horrible ensembl-specific hacks.
# TODO: parse the sequence type's SO to actually figure out if something is a gene.
# This would also avoid ignoring id-less genes.
chromosomes(genome::Genome) = features_with_id(genome, x -> contains(x.id, "chromosome:"))
transcripts(genome::Genome) = features_with_id(genome, x -> contains(x.id, "transcript:"))
genes(genome::Genome) = features_with_id(genome, x -> contains(x.id, "gene:"))
ref_sequence(genome::Genome, ref::AbstractString) = get(genome.sequence_regions, ref, Feature[])
#function positions(genome::Genome, tuple::Tuple{N, M}) where {N <: Number, M <: Number}
#    @assert tuple[1] <= tuple[2] "Tuple is unsorted"
#    ref_sequence(genome, x -> (tuple[1] <= x.pos.pos_start <= tuple[2]) | (tuple[1] <= x.pos.pos_end <= tuple[2]))
#end
