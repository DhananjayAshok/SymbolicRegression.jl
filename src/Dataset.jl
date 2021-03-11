using FromFile
@from "Truth.jl" import Truth

mutable struct Dataset{T<:Real}

    X::AbstractMatrix{T}
    y::AbstractVector{T}
    OriginalX::AbstractMatrix{T}
    Originaly::AbstractVector{T}
    truths::Array{Truth, 1}
    n::Int
    nfeatures::Int
    weighted::Bool
    weights::Union{AbstractVector{T}, Nothing}
    varMap::Array{String, 1}

end

"""
    Dataset(X::AbstractMatrix{T}, y::AbstractVector{T};
            weights::Union{AbstractVector{T}, Nothing}=nothing,
            varMap::Union{Array{String, 1}, Nothing}=nothing)

Construct a dataset to pass between internal functions.
"""
function Dataset(
        X::AbstractMatrix{T},
        y::AbstractVector{T},
	truths::Array{Truth, 1};
        weights::Union{AbstractVector{T}, Nothing}=nothing,
        varMap::Union{Array{String, 1}, Nothing}=nothing
       ) where {T<:Real}

    n = size(X, 2)
    nfeatures = size(X, 1)
    weighted = weights !== nothing
    if varMap == nothing
        varMap = ["x$(i)" for i=1:nfeatures]
    end

    return Dataset{T}(X, y, copy(X), copy(y), truths, n, nfeatures, weighted, weights, varMap)

end

function extendDataset(dataset , X , y)
	if X != nothing && y != nothing
		catX = hcat(dataset.X, X)
		caty = vcat(dataset.y, y)
		#println("d ", typeof(dataset.X), size(dataset.X))
		#println("x ", typeof(X), size(X))
		dataset.X = catX
		dataset.y = caty
	end
end

