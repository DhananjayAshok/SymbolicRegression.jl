using FromFile
using Random: randperm
using LossFunctions
@from "Core.jl" import Options, Dataset, Node
@from "EquationUtils.jl" import countNodes
@from "EvaluateEquation.jl" import evalTreeArray, differentiableEvalTreeArray
@from "Truth.jl" import Truth, transform, transformedTruthPrediction

function Loss(x::AbstractArray{T}, y::AbstractArray{T}, options::Options{A,B,C})::T where {T<:Real,A,B,C<:SupervisedLoss}
    value(options.loss, y, x, AggMode.Mean())
end
function Loss(x::AbstractArray{T}, y::AbstractArray{T}, options::Options{A,B,C})::T where {T<:Real,A,B,C<:Function}
    sum(options.loss.(x, y))/length(y)
end

function Loss(x::AbstractArray{T}, y::AbstractArray{T}, w::AbstractArray{T}, options::Options{A,B,C})::T where {T<:Real,A,B,C<:SupervisedLoss}
    value(options.loss, y, x, AggMode.WeightedMean(w))
end
function Loss(x::AbstractArray{T}, y::AbstractArray{T}, w::AbstractArray{T}, options::Options{A,B,C})::T where {T<:Real,A,B,C<:Function}
    sum(options.loss.(x, y, w))/sum(w)
end

function truthLoss(tree::Node, x::AbstractArray{T}, y::AbstractArray{T}, truth::Truth, options::Options)::T where {T<:Real}
	transformed = transform(x, truth)
    targets = transformedTruthPrediction(transformed, y, truth)
    preds, waste = evalTreeArray(tree, transformed, options)
	loss = Loss(preds, targets, options)
	return loss
end

function truthScore(tree::Node, x::AbstractArray{T}, y::AbstractArray{T}, truth::Truth, options::Options, threshold=1e-01)::Integer where {T<:Real}
   	loss = truthLoss(tree, x, y, truth, options)
    if loss > threshold
		return 1
    else
        return 0
    end
end
function truthScore(tree::Node, x::AbstractArray{T}, y::AbstractArray{T}, truths::Array{Truth, 1}, options::Options)::Integer where {T<:Real}
    s = 0
    for truth in truths
        s += (truthScore(tree,  x, y,  truth, options))
    end
    return s
end


function truthScore(tree::Node, dataset::Dataset{T}, truth::Truth, options::Options)::Integer where {T<:Real}
    return truthScore(tree, dataset.X, dataset.y, truth, options)
end

function truthScore(tree::Node, dataset::Dataset{T}, truths::Array{Truth, 1}, options::Options)::Integer where {T<:Real}
    return truthScore(tree, dataset.X, dataset.y, truths, options)
end

function truthScore(tree::Node, dataset::Dataset{T}, options::Options)::Integer where {T<:Real}
    return truthScore(tree, dataset, dataset.truths, options)
end

# Loss function. Only MSE implemented right now. TODO
# Also need to put actual loss function in scoreFuncBatch!
function EvalLoss(tree::Node, dataset::Dataset{T}, options::Options;
                  allow_diff=false)::T where {T<:Real}
    if !allow_diff
        (prediction, completion) = evalTreeArray(tree, dataset.X, options)
    else
        (prediction, completion) = differentiableEvalTreeArray(tree, dataset.X, options)
    end
    if !completion
        return T(1000000000)
    end

    if dataset.weighted
        return Loss(prediction, dataset.y, dataset.weights, options)
    else
        return Loss(prediction, dataset.y, options)
    end
end


# Score an equation
function scoreFunc(dataset::Dataset{T},
                   baseline::T, tree::Node,
                   options::Options; allow_diff=false)::T where {T<:Real}
    mse = EvalLoss(tree, dataset, options; allow_diff=allow_diff)
    tscore = truthScore(tree, dataset, options)
    #print(tscore)
    return mse / baseline + countNodes(tree)*options.parsimony + tscore*0
end

# Score an equation with a small batch
function scoreFuncBatch(dataset::Dataset{T}, baseline::T,
                        tree::Node, options::Options, truths::Array{T, 1}=[])::T where {T<:Real}
    batchSize = options.batchSize
    batch_idx = randperm(dataset.n)[1:options.batchSize]
    batch_X = dataset.X[:, batch_idx]
    batch_y = dataset.y[batch_idx]
    (prediction, completion) = evalTreeArray(tree, batch_X, options)
    if !completion
        return T(1000000000)
    end

    if !dataset.weighted
        mse = Loss(prediction, batch_y, options)
    else
        batch_w = dataset.weights[batch_idx]
        mse = Loss(prediction, batch_y, batch_w, options)
    end
    tscore = truthScore(tree, batch_X, batch_y, dataset.truths, options)
    return mse / baseline + countNodes(tree) * options.parsimony + tscore*0
end



