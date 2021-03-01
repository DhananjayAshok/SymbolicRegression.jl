using FromFile
@from "Core.jl" import Node, Options
@from "EvaluateEquation.jl" import evalTreeArray

function space_separate(form::String, variable_names::Array{String, 1})::String
	newform = form
	for i=1:length(variable_names)
		#println("ON ", variable_names[i])
		newform = replace(newform, variable_names[i] => "  "*variable_names[i]*"  ")
	end
	return newform
end

function string_to_Node(form::String, variable_names::Array{String, 1}, options::Options)::Node
	newform = space_separate(form, variable_names)
	for i=1:length(variable_names)
		#println("ON ", variable_names[i])
		newform = replace(newform, "  "*variable_names[i]*"  " => " Node(\"x"*string(i)*"\") ")
		#println(newform)
	end
	#println(newform)
	return eval(Meta.parse(newform))
end

struct Oracle
	nvariables::Integer
	f
	equation::Node
	variable_names::Array{String, 1}
	options::Options
	Oracle(f, variable_names::Array{String, 1}, options::Options) = new(size(variable_names)[1],f,nothing,variable_names,options)
	Oracle(form::String, variable_names::Array{String, 1}, options::Options) = new(size(variable_names)[1], nothing, string_to_Node(form, variable_names, options), variable_names, options)
end

# inps of shape (dims, N) not (N, dims)
function OracleOutput(oracle::Oracle, inps::Array{T, 2})::Array{T, 1} where {T <: Real}
	if oracle.f == nothing
		return evalTreeArray(oracle.equation, inps, oracle.options)[1]
	else
		return oracle.f(eachcol(inps)...)	
	end	
end
