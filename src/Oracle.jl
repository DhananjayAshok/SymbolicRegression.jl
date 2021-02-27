function vector_enable_string_formula(formula)
    	new_form = formula
    	for symbol in ["+", "-", "/", "*","^", "sin", "cos", "tan", "log", "sqrt"]
    		vectorized = " ."*symbol
		new_form = replace(new_form, symbol => vectorized)
		#println(new_form)
	end
	return new_form
end

function vector_form_to_function(form, variable_names)
	newform = form
	for i=1:length(variable_names)
		newform = replace(newform, variable_names[i] => "x["*string(i)*"]")
	end
	final_eval = "f(x...) ="*newform
	#println(final_eval)
	return eval(Meta.parse(final_eval))
end

struct Oracle
	nvariables::Integer
	f
	form::String
	variable_names::Array{String, 1}
	id::String
	Oracle(f, variable_names::Array{String, 1}, id::String) = new(size(variable_names)[1],f,nothing,variable_names,id)
	Oracle(form::String, variable_names::Array{String, 1}, id::String) = new(size(variable_names)[1], vector_form_to_function(vector_enable_string_formula(form), variable_names), vector_enable_string_formula(form), variable_names, id)

end

function OracleOutput(oracle::Oracle, inps::Array{Array{Float64, 1}, 1}):Array{Float64, 1}
	return oracle.f(inps...)
end

function OracleOutput(oracle::Oracle, inps::Array{Float64, 1})::Float64
	return oracle.f(inps...)
end

function OracleOutput(oracle::Oracle, inps::Array{Float64, 2})::Array{Float64, 1}
	return oracle.f(eachcol(inps)...)
end
