module BedMaker

import GFF3, BED
using DataStructures: DefaultDict

include("helpers.jl")
include("features.jl")
include("genome.jl")

export Genome, Feature, FeaturePosition, FeatureMeta

end # module
