abstract type AbstractRecord <: AbstractPosition end

struct SmallRecord <: AbstractRecord
    pos::FeaturePosition
    #chrom::String
    #start::UInt32
    #stop::UInt32
    name::Union{Char, String}
    score::UInt8
    #strand::Char
    #thick_start::UInt32
    #thick_end::UInt32
    #rgb::Tuple{UInt8, UInt8, UInt8}
    #block_count::UInt32
    #block_size::Vector{UInt32}
    #block_start::Vector{UInt32}
    SmallRecord(pos, name='.', score=0) = new(pos, name, score)
end

function SmallRecord(feature::Feature)
    SmallRecord(
        feature.pos,
        feature.id == nothing ? '.' : feature.id,
        0
    )
end

function BedMaker.SmallRecord(feature::Feature, name::String)
    SmallRecord(feature.pos, name, 0)
end

struct BEDWriter
    output::IO
end

function Base.close(writer::BEDWriter)
    close(writer.io)
end

function Base.eof(writer::BEDWriter)
    eof(writer.io)
end

function Base.write(writer::BEDWriter, features::Vector{Feature})
    for feature in features
        write(writer.output, SmallRecord(feature))
    end
end

function Base.write(writer::BEDWriter, feature::Feature)
    write(writer.output, SmallRecord(feature))
end

function Base.write(writer::BEDWriter, records::Vector{SmallRecord})
    for record in records
        write(writer.output, record)
    end
end

function Base.write(writer::BEDWriter, record::SmallRecord)
    write(writer.output, record)
end

function Base.write(io::IO, record::SmallRecord)
    # chromosome, start-1, stop, name, score, strand
    fields = [record.pos.seqid, record.pos.pos.start-1, record.pos.pos.stop, record.name, record.score, Char(record.pos.strand)]
    #fields = [record.chrom, record.start, record.stop, record.name, record.score, record.strand]
    write(io, join(string.(fields), "\t")*'\n')
end

function grouping_value(x::SmallRecord)
    x.name
end

# We group with seqids and phases
function group(x::Vector{SmallRecord})
    groups = unique([grouping_value(i) for i in x])
    [findfirst([grouping_value(i) == group for group in groups]) for i in x]
end

function Base.union(x::Vector{SmallRecord})
    groups = group(x)
    grouped = map(y -> x[groups .== y], unique(groups))
    #println("There are $(length(grouped)) groups:")
    result = map(grouped) do group_values
        #println(length(group_values))
        intervals = [i.pos for i in group_values]
        #println(length(intervals))
        new_pos = union(intervals)
        #println(length(new_pos))
        [SmallRecord(x, group_values[1].name) for x in new_pos]
    end
    #println("with $(length(reduce(vcat, result))) records")
    reduce(vcat, result)
end

