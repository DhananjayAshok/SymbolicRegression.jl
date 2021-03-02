using FromFile
import StatsBase: sample
@from "Truth.jl" import Truth,transform, truthPrediction
@from "LossFunctions.jl" import truthScore
@from "Core.jl" import Node
@from "EvaluateEquation.jl" import evalTreeArray
@from "PopMember.jl" import PopMember



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
function testTruth(tree::Node, truth::Truth)::Bool
    truthError = truthScore(tree, truth)
    if truthError >= 1
        return false
    else
        return true
    end
end

# Returns a list of violating functions from assumed list TRUTHS
function violatingTruths(tree::Node)::Array{Truth}
    toReturn = []
    #print("\n Checking Equation ", stringTree(tree), "\n")
    for truth in TRUTHS
        test_truth = testTruth(tree, truth)
        #print("Truth: ", truth, ": " , test_truth, "\n-----\n")
        if !test_truth
            append!(toReturn, [truth])
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
    X_slice = workingcX[indx, :]
    X_transformed = transform(X_slice, truth)
    return X_transformed
end
function extendedX(truth::Truth, indx::Array{Int32, 1})::Union{Array{Float32, 2}, Nothing}
    return extendedX(OriginalX, truth, indx)
end
function extendedX(cX::Array{Float32, 2}, violatedTruths::Array{Truth}, indx::Array{Int32, 1})::Union{Array{Float32, 2}, Nothing}
    if length(violatedTruths) == 0
        return nothing
    end
    workingX = extendedX(cX, violatedTruths[1], indx)
    for truth in violatedTruths[2:length(violatedTruths)]
        workingX = vcat(workingX, extendedX(cX, truth, indx))
    end
    return workingX
end
function extendedX(violatedTruths::Array{Truth}, indx::Array{Int32, 1})::Union{Array{Float32, 2}, Nothing}
    return extendedX(OriginalX, violatedTruths, indx)
end
function extendedX(tree::Node, indx::Array{Int32, 1})::Union{Array{Float32, 2}, Nothing}
    violatedTruths = violatingTruths(tree)
    return extendedX(violatedTruths, indx)
end
function extendedX(member::PopMember, indx::Array{Int32, 1})::Union{Array{Float32, 2}, Nothing}
    return extendedX(member.tree, indx)
end


function extendedy(cX::Array{Float32, 2}, cy::Array{Float32}, truth::Truth, indx::Array{Int32, 1})::Union{Array{Float32}, Nothing}
    cy = copy(cy)
    cX = copy(cX)
    X_slice = cX[indx, :]
    y_slice = cy[indx]
    X_transformed = transform(X_slice, truth)
    y_transformed = truthPrediction(X_transformed, y_slice, truth)
    return y_transformed
end
function extendedy(truth::Truth, indx::Array{Int32, 1})::Union{Array{Float32}, Nothing}
    return extendedy(OriginalX, Original_y, truth, indx)
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
function extendedy(violatedTruths::Array{Truth}, indx::Array{Int32, 1})::Union{Array{Float32}, Nothing}
    return extendedy(OriginalX,Original_y, violatedTruths, indx)
end
function extendedy(tree::Node, indx::Array{Int32, 1})::Union{Array{Float32}, Nothing}
    violatedTruths = violatingTruths(tree)
    return extendedy(violatedTruths, indx)
end
function extendedy(member::PopMember, indx::Array{Int32, 1})::Union{Array{Float32}, Nothing}
    return extendedy(member.tree, indx)
end

function CheckAndExtend(member::PopMember)::Nothing
    shuf = randomIndex(OriginalX)
    X_extension = extendedX(member, shuf)
    y_extension = extendedy(member,shuf)
    violations = violatingTruths(member)
    if (X_extension == nothing) || (y_extension == nothing)
        print("Equation Compliant with all Truths\n")
    else
        global X = vcat(X, X_extension)
        global y = vcat(y, y_extension)
        print("Found ", length(violations), " violated truths \n")
    end
end
