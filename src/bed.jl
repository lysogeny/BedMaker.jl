abstract type AbstractRecord end

struct SmallRecord <: AbstractRecord
    chrom::String
    start::UInt32
    stop::UInt32
    name::Union{Char, String}
    score::UInt8
    strand::Char
    #thick_start::UInt32
    #thick_end::UInt32
    #rgb::Tuple{UInt8, UInt8, UInt8}
    #block_count::UInt32
    #block_size::Vector{UInt32}
    #block_start::Vector{UInt32}
    SmallRecord(chrom, start, stop, name='.', score=0, strand='.') = new(chrom, start, stop, name, score, strand)
end

function BedMaker.SmallRecord(feature::Feature)
    SmallRecord(
        feature.pos.seqid,
        feature.pos.pos.start-1, # open, but offset
        feature.pos.pos.stop, # closed
        feature.id == nothing ? '.' : feature.id,
        0,
        Char(feature.pos.strand)
    )
end

function BedMaker.SmallRecord(feature::Feature, name::String)
    SmallRecord(
        feature.pos.seqid,
        feature.pos.pos.start-1, # open, but offset
        feature.pos.pos.stop, # closed
        name,
        '.',
        Char(feature.pos.strand)
    )
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
    fields = [record.chrom, record.start, record.stop, record.name, record.score, record.strand]
    write(io, join(string.(fields), "\t")*'\n')
end
