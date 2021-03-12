using FromFile
import StatsBase: sample
@from "Truth.jl" import Truth,transform, truthPrediction
@from "LossFunctions.jl" import truthScore, truthLoss
@from "Core.jl" import Node
@from "EvaluateEquation.jl" import evalTreeArray
@from "EquationUtils.jl" import stringTree
@from "PopMember.jl" import PopMember
@from "Dataset.jl" import Dataset, extendDataset
@from "Core.jl" import Options

# Returns true iff Truth Score is below a given threshold i.e truth is satisfied
function testTruth(member::PopMember, truth::Truth)::Bool
    truthError = truthScore(member.tree, truth)
    #print(stringTree(member.tree), "\n")
    #print(truth, ": ")
    #print(truthError, "\n")
    if truthError >= 1
        #print("Returns False \n ----\n")
        return false
    else
        #print("Returns True \n ----\n")
        return true
    end
end

# Returns a list of violating functions from assumed list TRUTHS
function violatingTruths(member::PopMember)::Array{Truth}
    return violatingTruths(member.tree)
end

# Returns true iff Truth Score is below a given threshold i.e truth is satisfied
function testTruth(tree::Node, truth::Truth, dataset::Dataset, options::Options)::Bool
    truthError = truthScore(tree, dataset, truth, options)
    if truthError >= 1
        return false
    else
        return true
    end
end

# Returns a list of violating functions from assumed list TRUTHS
function violatingTruths(tree::Node, dataset::Dataset, options)::Array{Truth}
    toReturn = []
    #print("\n Checking Equation ", stringTree(tree), "\n")
    for truth in dataset.truths
        test_truth = testTruth(tree, truth, dataset, options)
        #print("Truth: ", truth, ": " , test_truth, "\n-----\n")
        if !test_truth
            push!(toReturn, truth)
        end
    end
    return toReturn
end

function randomIndex(cX::Array{Float32, 2}, k::Integer=10)::Array{Int32, 1}
    indxs = sample([Int32(i) for i in 1:size(cX)[1]], k)
    return indxs
end

function randomIndex(leng::Integer, k::Integer=10)::Array{Int32, 1}
    indxs = sample([Int32(i) for i in 1:leng], k)
    return indxs
end

function extendedX(cX::Array{Float32, 2}, truth::Truth, indx::Array{Int32, 1})::Array{Float32, 2}
    workingcX = copy(cX)
    X_slice = workingcX[:, indx]
    X_transformed = transform(X_slice, truth)
    return X_transformed
end

function extendedX(cX::Array{Float32, 2}, violatedTruths::Array{Truth}, indx::Array{Int32, 1})::Union{Array{Float32, 2}, Nothing}
    if length(violatedTruths) == 0
        return nothing
    end
    workingX = extendedX(cX, violatedTruths[1], indx)
    for truth in violatedTruths[2:length(violatedTruths)]
        workingX = hcat(workingX, extendedX(cX, truth, indx))
    end
    return workingX
end

function extendedy(cX::Array{Float32, 2}, cy::Array{Float32}, truth::Truth, indx::Array{Int32, 1})::Union{Array{Float32}, Nothing}
    cy = copy(cy)
    cX = copy(cX)
    X_slice = cX[:, indx]
    y_slice = cy[indx]
    X_transformed = transform(X_slice, truth)
    y_transformed = truthPrediction(X_transformed, y_slice, truth)
    return y_transformed
end

function extendedy(cX::Array{Float32, 2}, cy::Array{Float32}, violatedTruths::Array{Truth}, indx::Array{Int32, 1})::Union{Array{Float32}, Nothing}
    if length(violatedTruths) == 0
        return nothing
    end
    workingy = extendedy(cX, cy, violatedTruths[1], indx)
    for truth in violatedTruths[2:length(violatedTruths)]
        workingy = vcat(workingy, extendedy(cX, cy, truth, indx))
    end
    return workingy
end

function extendedX(dataset::Dataset, violatedTruths::Array{Truth, 1}, indx::Array{Int32, 1})::Union{Array{Float32, 2}, Nothing}
    return extendedX(dataset.OriginalX, violatedTruths, indx)
end

function extendedy(dataset::Dataset, violatedTruths::Array{Truth, 1}, indx::Array{Int32, 1})::Union{Array{Float32, 1}, Nothing}
    return extendedy(dataset.OriginalX, dataset.Originaly, violatedTruths, indx)
end


function CheckAndExtend(member::PopMember, dataset::Dataset, options::Options, threshold::Integer=500)
    violatedTruths = violatingTruths(member.tree, dataset, options)
	#println(length(dataset.y))
    if length(dataset.y) > threshold
		println("Exceeds")
        return nothing, nothing
    end
    shuf = randomIndex(dataset.OriginalX)
    X_extension = extendedX(dataset, violatedTruths, shuf)
    y_extension = extendedy(dataset, violatedTruths, shuf)
    violations = violatedTruths
    if (X_extension == nothing) || (y_extension == nothing)
        println("Equation ", stringTree(member.tree, options) ," compliant with all Truths\n")
		return nothing, nothing
    else
		println("Equation ",stringTree(member.tree, options) ," violated the following Truths")
		for truth in violatedTruths
			println(truth, "with Truth Loss ", truthLoss(member.tree, dataset.X, dataset.y, truth, options))
		end
		return X_extension, y_extension
		#extendDataset(dataset, X_extension, y_extension)    
    end
end


