module BedMaker

import GFF3, BED
using DataStructures: DefaultDict
using GenomicFeatures: STRAND_POS, STRAND_NEG, STRAND_NA, STRAND_BOTH

include("helpers.jl")
include("features.jl")
include("genome.jl")

export Genome, Feature, FeaturePosition, FeatureMeta

end # module
