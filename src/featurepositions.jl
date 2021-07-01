"""FeatureStrand

Enum for encoding feature's strandedness
"""
@enum FeatureStrand strand_pos=1 strand_neg=2 strand_both=3 strand_none=4 strand_fail=5

function FeatureStrand(strand::Char)
    checks = ['+', '-', '.', '?']
    i = 1
    while i <= 4
        if strand == checks[i]
            break
        end
        i += 1
    end
    return FeatureStrand(i)
end

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

function Base.Char(strand::FeatureStrand)
    if strand == strand_pos
        return '+'
    elseif strand == strand_neg
        return '-'
    elseif strand == strand_both
        return '.'
    elseif strand == strand_none
        return '?'
    else
        @error "Strand fail cannot be represented as a character"
    end
end

"""FeaturePosition

Position information for a feature.
FeaturePosition is structured as follows:

- `seqid::AbstractString`: ID of reference sequence that this feature is on.
- `pos::Interval`: Start and stop position of feature, 1-based, stored in interval struct.
- `strand::FeatureStrand`: Strand Information
- `phase::FeaturePhase`: CDS-specific Phase information.
"""
struct FeaturePosition
    seqid::AbstractString
    pos::Interval
    strand::FeatureStrand
end

"""FeaturePosition(record::GFF3.Record)

Create feature position from a GFF3 record
"""
function FeaturePosition(record::GFF3.Record)
    seqid = GFF3.seqid(record)
    pos_start = GFF3.seqstart(record)
    pos_stop = GFF3.seqend(record)
    strand = FeatureStrand(record)
    FeaturePosition(seqid, Interval(pos_start, pos_stop), strand)
end

FeaturePosition(seqid::String, pos::Interval, strand::Char) = FeaturePosition(seqid, pos, FeatureStrand(strand))
FeaturePosition(seqid::String, start::Integer, stop::Integer, strand::Char) = FeaturePosition(seqid, Interval(start, stop), strand)
FeaturePosition(seqid::String, pos::T, strand::Char) where {T <: Tuple{Integer, Integer}} = FeaturePosition(seqid, pos[1], pos[2], strand)

function Base.isless(x::FeaturePosition, y::FeaturePosition)
    x.seqid == y.seqid ? isless(x.pos, y.pos) : x.strand == y.strand ? isless(x.seqid, y.seqid) : false
end

function isoverlap(x::Vector{FeaturePosition})
    (x.seqid == y.seqid) && (x.strand == y.strand) && isoverlap(x.pos, y.pos)
end

function isoverlap_sticky(x::Vector{FeaturePosition})
    (x.seqid == y.seqid) && (x.strand == y.strand) && isoverlap_sticky(x.pos, y.pos)
end

function grouping_value(x::FeaturePosition)
    (x.seqid, x.strand)
end

# We group with seqids and phases
function group(x::Vector{FeaturePosition})
    groups = unique([grouping_value(i) for i in x])
    [findfirst([grouping_value(i) == group for group in groups]) for i in x]
end

function Base.union(x::Vector{FeaturePosition})
    groups = group(x)
    grouped = map(y -> x[groups .== y], unique(groups))
    result = map(grouped) do group_values
        intervals = [i.pos for i in group_values]
        new_pos = union(intervals)
        [FeaturePosition(group_values[1].seqid, x, group_values[1].strand) for x in new_pos]
    end
    reduce(vcat, result)
end

Base.union(x::Vector{FeaturePosition}, y::Vector{FeaturePosition}) = vcat(x, y) |> union
