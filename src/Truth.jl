# *** Custom Functions
##################################################################################################################################
# *** Will somewhere need to define a list TRUTHS of all valid auxliary truths
struct Transformation
    type::Integer # 1 is symmetry, 2 is zero, 3 is equality
    params::Array{Integer}
    Transformation(type::Integer, params::Array{Integer, 1}) = new(type, params)
    Transformation(type::Integer, params::Array{Int32, 1}) = new(type, params)
	Transformation(type::Integer, params::Array{Int64, 1}) = new(type, params)
														
end

function string(transformation::Transformation)::String
	listString = Base.string(transformation.params)
	if transformation.type == 1
		return "Symmetry Constraint: variables "*listString
	elseif transformation.type == 2
		return "Zero Constraint: variables "*listString
	elseif transformation.type==3
		return "Equality Constraint: variables "*listString
	else
		return "Unknown Transformation"
	end
end

Base.show(io::IO, x::Transformation) = show(io, string(x))
																
struct Truth
    transformation::Transformation
    weights::Array{T} where {T<: Real}
    Truth(transformation::Transformation, weights::Array{T}) where {T <: Real} = new(transformation, weights)
    Truth(type::Int32, params::Array{Int32}, weights::Array{T}) where {T <: Real} = new(Transformation(type, params), weights)
	Truth(type::Int64, params::Array{Int64}, weights::Array{T}) where {T <: Real} = new(Transformation(type, params), weights)
	
end

function string(truth::Truth)::String
	return "(TRUTH: "*string(truth.transformation)*" weights: "*Base.string(truth.weights)
end

Base.show(io::IO, x::Truth) = show(io, string(x))


# Returns a copy of the data with the two specified columns swapped
function swapColumns(cX::AbstractMatrix{T}, a::Integer, b::Integer)::Array{T, 2} where {T <: Real}
    X1 = copy(cX)
    X1[:, a] = cX[:, b]
    X1[:, b] = cX[:, a]
    return X1
end

# Returns a copy of the data with the specified integers in the list set to value given
function setVal(cX::AbstractMatrix{T}, a::Array{Integer, 1}, val::S)::Array{T, 2} where {T <: Real, S <: Real}
    X1 = copy(cX)
    for i in 1:size(a)[1]
        X1[:, a[i]] = fill!(cX[:, a[i]], val)
    end
    return X1
end

# Returns a copy of the data with the specified integer indices in the list set to the first item of that list
function setEq(cX::AbstractMatrix{T}, a::Array{Integer, 1})::Array{T, 2} where {T <: Real}
    X1 = copy(cX)
    val = X1[:, a[1]]
    for i in 1:size(a)[1]
        X1[:, a[i]] = val
    end
    return X1
end

# Takes in a dataset and returns the transformed version of it as per the specified type and parameters
function transform(cX::AbstractMatrix{T}, transformation::Transformation)::Array{T, 2} where {T <: Real}
    if transformation.type==1 # then symmetry
        a = transformation.params[1]
        b = transformation.params[2]
        return swapColumns(cX, a, b)
    elseif transformation.type==2 # then zero condition
        return setVal(cX, transformation.params, Float32(0))
    elseif transformation.type == 3 # then equality condition
        return setEq(cX, transformation.params)
    else # Then error return X
        return cX
    end
end
function transform(cX::AbstractMatrix{T}, truth::Truth)::Array{T, 2} where {T <: Real}
    return transform(cX, truth.transformation)
end

# Returns a linear combination when given X of shape nxd, y of shape nx1 is f(x) and w of shape d+2x1, result is shape nx1
function LinearPrediction(cX::AbstractMatrix{T}, cy::AbstractArray{T}, w::AbstractArray{T})::AbstractArray{T} where {T <: Real}
     preds = 0
     for i in 1:ndims(cX)
       preds = preds .+ cX[:,i].*w[i]
       end
     preds = preds .+ cy.*w[ndims(cX)+1]
     return preds .+ w[ndims(cX)+2]
end


# Takes in X that has been transformed and returns what the Truth projects the target values should be
function truthPrediction(X_transformed::AbstractMatrix{T}, cy::AbstractArray{T}, truth::Truth)::Array{T} where {T <: Real}
    return LinearPrediction(X_transformed, cy, truth.weights)
end
