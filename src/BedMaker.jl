module BedMaker

import GFF3, BED
using DataStructures: DefaultDict
using GenomicFeatures: STRAND_POS, STRAND_NEG, STRAND_NA, STRAND_BOTH

include("intervals.jl")
include("helpers.jl")
include("features.jl")
include("genome.jl")
include("bed.jl")

export Genome, 
    isoverlap,
    Feature, 
    FeaturePosition, 
    FeatureMeta, 
    genes, 
    transcripts,
    chromosomes, 
    features, 
    ref_sequence,
    BEDWriter

end # module
