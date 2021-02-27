function linearRegression(X::AbstractMatrix{T}, y::AbstractArray{T})::Array{T, 1} where {T<:Real}
        mx = hcat(X, ones(length(y)))
        weights = nothing
        try
                weights = mx \ y
        catch e
                println("Linear Regression Failed")
                weights = zeros(size(X)[2])
        end
	weights = round.(weights, digits=2)
        return weights
end
