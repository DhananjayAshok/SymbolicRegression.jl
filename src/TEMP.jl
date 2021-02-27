include("Oracle.jl")
include("Truth.jl")
include("ConstraintDiscovery.jl")
#form = "a^2 + b^2 + c^2"
#var_names = ["a","b","c"]
id = "1"
#o = Oracle(form, var_names, id)
transformation = Transformation(1, [1, 2])
truth = Truth(2, [1, 2, 3], [0, 0, 0, 0, 0])
