struct Interval
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

function group_overlaps(x::Vector{Interval})
    if !(issorted(x))
        ArgumentError("x is not sorted") |> throw
    end
    groups = zeros(UInt, length(x))
    groups .+= 1
    group_counter = 1
    for i in 2:length(x)
        if !isoverlap_sticky(x[i-1], x[i])
            group_counter += 1
        end
        groups[i] = group_counter
    end
    groups
end

function Base.union(x::Vector{Interval})::Vector{Interval}
    if !(issorted(x))
        x = sort(x)
    end
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
