module BedMaker

import GFF3, BED
using DataStructures: DefaultDict
using GenomicFeatures: STRAND_POS, STRAND_NEG, STRAND_NA, STRAND_BOTH

include("helpers.jl")
include("intervals.jl")
include("featurepositions.jl")
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
