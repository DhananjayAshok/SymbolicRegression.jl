using Distributions
using Combinatorics
include("Truth.jl")
include("Oracle.jl")
include("LinearRegression.jl")

function gen_valid_points(oracle::Oracle, npoints::Integer=20, default_min=0.5, default_max=100)::Array{Float64, 2}
	dims = oracle.nvariables
	dist = Uniform(default_min, default_max)
	points = rand(dist, (npoints, dims))
end


function weak_learner(X::AbstractMatrix{T}, y::AbstractArray{T}, y_original::AbstractArray{T})::Tuple{Array{T, 1}, T} where {T<:Real}
    new_X = hcat(X, y_original) 
    weights= linearRegression(new_X, y)
    preds = hcat(new_X, ones(length(y))) * reshape(weights, (length(weights), 1))
    mse = mean((preds-y).^2)
    return weights, mse
end
function hasNaN(arr)::Bool
	return sum(isinf.(arr)) > 0
end

function verifyTransformation(transformation::Transformation, oracle::Oracle, npoints=20, threshold=1e-05, timeout=5)
  t = Timer(timeout)
  sat = false;
  X = nothing
  y_original = nothing
  while !sat && isopen(t)
    X = gen_valid_points(oracle, npoints)
    try
    	y_original = OracleOutput(oracle, X)
    	if !hasNaN(y_original)
		sat = true
	end
    catch e
	
    end
  end
  if !sat
	close(t)
	return false, nothing
  else
	X_transformed = transform(X, transformation)
	y = nothing
	try
		y = OracleOutput(oracle, X_transformed)
		if hasNaN(y)
			return false, nothing
		end
	catch e
		return false, nothing
	end
	weights, mse = weak_learner(X_transformed, y, y_original)
	if mse > threshold
		return false, weights
	else
		return true, Truth(transformation, weights)
	end
	
  end
end


function powerset(iterable)::Array{Array{Integer, 1}, 1}
	return collect(combinations(iterable))
end

function pairset(iterable)::Array{Array{Integer, 1}, 1}
	return collect(combinations(iterable, 2))
end


function multiprocess_task(transformation::Transformation, oracle::Oracle) 
    value, truth = verifyTransformation(transformation, oracle)
    if value == true
        return truth
    else
        return nothing
    end
end

function naive_procedure(oracle::Oracle)::Array{Truth, 1}
    nvariables = oracle.nvariables
    var_list = collect(range(1, nvariables, step=1))
    pairs = pairset(var_list)
    sets = powerset(var_list)
    final = []
    transformations = []
    for pair in pairs
    	type = 1 # symmetry
	params = pair
	push!(transformations, Transformation(type, params))
    end
    for smallset in sets
    	params = smallset
        if length(smallset) > 1
            type = 3 # value/ equality
	    push!(transformations, Transformation(type, params))
	end
	type = 2 # zero
	push!(transformations, Transformation(type, params))
    end
    function task(transformation)
	return multiprocess_task(transformation, oracle)
    end
    temp = task.(transformations)
    # do the multiprocess_task on all of the reansformations
    #temp = [multiprocess_task(transformation, oracle) for transformation in transformations]
    for t in temp
        if t != nothing
            push!(final, t)
	end
    end
    return final
end


function process_from_form_and_names(form::String, variable_names::Array{String, 1})::Array{Truth, 1}
    if form ==nothing || variable_names ==nothing
        return []
    end
    oracle = Oracle(form, variable_names, "ID")
    #println(form)
    truths = naive_procedure(oracle)
    #println("Discovered the following Auxiliary Truths")
    return truths
end

function discoverTruths(form::String, variable_names::Array{String, 1}, verbosity=1::Integer)::Array{Truth, 1}
	truths = process_from_form_and_names(form, variable_names)
	if verbosity > 0
		println("Discovered the following Auxiliary Truths")
	end
	return truths
end
