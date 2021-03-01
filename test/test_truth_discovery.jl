include("../src/TruthDiscovery.jl")
form = "a * b + c"
var_names = ["a","b","c"]
id = "1"
#o = Oracle(form, var_names, id)
transformation = Transformation(1, [1, 2])
truth = Truth(2, [1, 2, 3], [0, 0, 0, 0, 0])
options = Options(binary_operators=(+, *), unary_operators=())
p = discoverTruths(form, var_names, options)
