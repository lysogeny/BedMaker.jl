
"""FeatureStrand

Enum for encoding feature's strandedness
"""
@enum FeatureStrand strand_pos=1 strand_neg=2 strand_both=3 strand_none=4 strand_fail=5

function FeatureStrand(record::GFF3.Record)
    if GFF3.ismissing(record, record.strand)
        return FeatureStrand(3)
    end
    strand = GFF3.strand(record)
    checks = [STRAND_POS, STRAND_NEG, STRAND_BOTH, STRAND_NA]
    i = 1
    while i <= 4
        if strand == checks[i]
            break
        end
        i += 1
    end
    return FeatureStrand(i)
end

"""FeaturePhase

Enum for encoding feature's phase (a CDS specific GFF3 field)
"""
@enum FeaturePhase phase_first=0 phase_second=1 phase_third=2 phase_missing=-1

function FeaturePhase(record::GFF3.Record)
    if GFF3.ismissing(record, record.phase)
        return FeaturePhase(-1)
    end
    return FeaturePhase(GFF3.phase(record))
end

abstract type AbstractPosition end

"""FeaturePosition

Position information for a feature.
FeaturePosition is structured as follows:

- `seqid::AbstractString`: ID of reference sequence that this feature is on.
- `pos_start::Integer`: Start position of feature, 1-based
- `pos_stop::Integer`: Stop position of feature, 1-based
- `strand::FeatureStrand`: Strand Information
- `phase::FeaturePhase`: CDS-specific Phase information.
"""
struct FeaturePosition <: AbstractPosition
    seqid::AbstractString
    pos_start::Integer
    pos_stop::Integer
    strand::FeatureStrand
    phase::FeaturePhase
end

"""FeaturePosition(record::GFF3.Record)

Create feature position from a GFF3 record
"""
function FeaturePosition(record::GFF3.Record)
    seqid = GFF3.seqid(record)
    pos_start = GFF3.seqstart(record)
    pos_stop = GFF3.seqend(record)
    strand = FeatureStrand(record)
    phase = FeaturePhase(record)
    FeaturePosition(seqid, pos_start, pos_stop, strand, phase)
end

"""FeatureMeta

Meta data of a Feature.
FeatureMeta is structured as follows:

 - `name::Union{Nothing, AbstractString}`: Name of this feature (if found as optional Attribute `Name`)
 - `description::Union{Nothing, AbstractString}`: Description (if found as optional Attribute `Description`
 - `type::AbstractString`: Type of this object as defined in it's field. Sequence Ontology Term or ID.
 - `attributes::Dict{String, Vector{String}}`: All of the Record's Attributes
"""
struct FeatureMeta
    name::Union{Nothing, AbstractString}
    description::Union{Nothing, AbstractString}
    type::AbstractString
    attributes::Dict{String, Vector{String}}
end

"""FeatureMeta(record::GFf3.Record)

Create FeatureMeta from GFF3 Record
"""
function FeatureMeta(record::GFF3.Record)
    attributes = Dict(GFF3.attributes(record)...)
    name = get(attributes, "Name", [nothing])[1]
    description = get(attributes, "description", [nothing])[1]
    type = GFF3.featuretype(record)
    FeatureMeta(name, description, type, attributes)
end

"""Feature

A Genomic Feature

Features are structured as follows:

- `id::Union{Nothing, AbstractString}`: ID of the Feature (optional Attribute `ID` from the GFF3, first found)
- `parent_id::Union{Nothing, AbstractString}`: Parent ID of the Feature (optional Attribute `Parent` from the GFF3, first find)
- `children::Vector{Feature}`: List of child elements of the Feature (Constructed from finding them with `Parent`. Requires that GFF3 is sorted in a sane order, that is parents show up before children.)
- `parent::Union{Nothing, Feature}`: Parent Feature as understood by optional Attribute `Parent`.
- `pos::FeaturePosition`: Positional information for this feature
- `meta::FeatureMeta`: Other meta data for this feature
"""
mutable struct Feature
    id::Union{Nothing, AbstractString}
    parent_id::Union{Nothing, AbstractString}
    children::Vector{Feature}
    parent::Union{Nothing, Feature}
    pos::FeaturePosition
    meta::FeatureMeta
end

"""Feature(record::GFF3.Record)

Construct genomic feature from GFF3 Record
"""
function Feature(record::GFF3.Record)
    attributes = Dict(GFF3.attributes(record)...)
    id = get(attributes, "ID", [nothing])[1]
    parent_id = get(attributes, "Parent", [nothing])[1]
    pos = FeaturePosition(record)
    meta = FeatureMeta(record)
    Feature(id, parent_id, Feature[], nothing, pos, meta)
end

"""meta_print(io, meta::FeatureMeta)

Internal printing function for `FeatureMeta` objects.
"""
function meta_print(io, meta::FeatureMeta)
    print(io, "\n  Type: $(meta.type)")
    if meta.name != nothing
        print(io, "\n  Name: $(meta.name)")
    end
    if meta.description != nothing
        print(io, "\n  Description: $(meta.description)")
    end
    # extra attributes
    print(io, "\n  Extra attributes:")
    for (key, value) in meta.attributes
        if key in ["ID", "description", "Name", "Parent"]
            continue
        end
        if length(value) <= 1
            print(io, "\n    $key: $(value[1])")
        else
            print(io, "\n    $key:")
            for val in value
                print(io, "\n        $val:")
            end
        end
    end
end

function Base.show(io::IO, ::MIME"text/plain", meta::FeatureMeta)
    print(io, "FeatureMeta")
    meta_print(io, meta)
end

function Base.show(io::IO, ::MIME"text/plain", feature::Feature)
    print(io, "Feature $(feature.id)")
    if feature.parent_id != nothing
        print(io, "\n  Parent: $(feature.parent_id)")
    end
    child_count = length(feature.children)
    print(io, "\n  $child_count children:")
    if length(feature.children) == 1
        print("$(feature.children[1].id)")
    elseif length(feature.children) > 1
        unnamed_count = 0
        for child in feature.children
            if child.id == nothing
                unnamed_count += 1
                continue
            end
            print("\n    $(child.id)")
        end
        if unnamed_count > 0
            print("\n    $(unnamed_count) Unnamed")
        end
    end
    print(io, "\n  Position: $(feature.pos)")
    meta_print(io, feature.meta)
end
