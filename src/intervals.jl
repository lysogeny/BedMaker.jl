abstract type AbstractPosition end

struct Interval <: AbstractPosition
    start::UInt
    stop::UInt
    Interval(start, stop) = (start <= stop) ? new(start, stop) : throw(ArgumentError("start is bigger than stop"))
end
Interval(t::Tuple{I, I}) where {I <: Integer} = Interval(t[1], t[2])

# For sorts
function Base.isless(x::Interval, y::Interval)
    # lexicographic less
    x.start == y.start ? isless(x.stop, y.stop) : isless(x.start, y.start)
end

function isoverlap(x::Interval, y::Interval)
    (x.start <= y.stop) && (y.start <= x.stop)
end

function isoverlap_sticky(x::Interval, y::Interval)
    (x.start <= (y.stop+1)) && (y.start <= (x.stop+1))
end
    
# Maximum extent of two intervals.
function union_unsafe(x::Interval, y::Interval)
    Interval(min(x.start, y.start), max(y.stop, x.stop))
end

function group_overlaps(x::Vector{Interval})
    if !(issorted(x))
        ArgumentError("x is not sorted") |> throw
    end
    if length(x) == 0
        return UInt[]
    end
    groups = ones(UInt, length(x))
    group_counter = 1
    group_interval = x[1]
    for i in 2:length(x)
        if !isoverlap_sticky(group_interval, x[i])
            group_interval = x[i]
            group_counter += 1
        else
            group_interval = union_unsafe(group_interval, x[i])
        end
        groups[i] = group_counter
    end
    groups
end

function Base.union(x::Vector{Interval})::Vector{Interval}
    x = sort(x)
    groups = group_overlaps(x)
    grouped = map(y -> x[groups .== y], unique(groups))
    map(grouped) do group
        Interval(minimum([i.start for i in group]), maximum([i.stop for i in group]))
    end
end

function Base.union(x::Vector{Interval}, y::Vector{Interval})
    vcat(x, y) |> union
end

#function Base.setdiff(x::Vector{Interval})::Vector{Interval}
#end
