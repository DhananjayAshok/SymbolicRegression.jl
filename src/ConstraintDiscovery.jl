function gen_valid_points(oracle, npoints=20, default_min=0.5, default_max=100)
end

def weak_learner(X, y, y_original):
    """
    Takes in X, y and returns a weak learner that tries to fit the training data and its associated R^2 score as well as the model itself
    """

    y_original = np.reshape(y_original, newshape=(len(y_original), 1))
    # print(X.shape, y_original.shape)
    new_X = np.append(X, y_original, axis=1)

    model = LinearRegression()
    model.fit(new_X, y)
    # Force the model to be simple by rounding coefficients to 2 decimal points
    model.coef_ = np.round(model.coef_, 2)
    model.intercept_ = np.round(model.intercept_, 2)

    score = model.score(new_X, y)
    return model, score



function verifyTransformation(transformation, oracle, npoints=20, threshold=0.98, timeout=5)
  # Get random npoints points from some range
  # start the timer
  sat = false;
  while not sat # and we still have time
    # try to gen_valid_points, 
    #predict a y_original = oracle.f(points) if there are nans freak out
    # set sat to true if you have a working valid dataset
  end
  # if we are out of time return False, None
  # otherwise get X_transformed using points and transformation
  # Then try to evaluate this transformed input with the oracle and if you get an error return False and None because out of domain error after transformation
  #model, score = weak_learner(X, y, y_original)
  # if score is above the threshold return true with the Truth of that transformation and weight, else false with none
end


function powerset(iterable):
    #return the powerset of any iterable set of integers for use in zero and value conditions
end


function multiprocess_task(transformation, oracle):
    #Takes in a transformation and oracle and returns Truth if the value from discover is true else returns None
    
    value, truth = verifyTransformation(transformation, oracle)
    if value == True:
        return truth
    else:
        return nothing


function naive_procedure(oracle):
    """
    Takes in an oracle and gives out an exhaustive list of form [(constraint, model)] for all true constraints
    """
    nvariables = oracle.nvariables
    #var_list = range(nvariables)
    pairs = generate every possible pair from this set
    sets = powerset results which are non empty
    final = []
    transformations = []
    for pair in pairs:
        #Append a symmmetry transformation to transformations using the pair values
    end
    for smallset in sets:
        if len(smallset) > 1:
            #transformations.append(ValueTransformation(smallset))
        #transformations.append(ZeroTransformation(smallset))
    end
    # do the multiprocess_task on all of the reansformations
    #temp = [multiprocess_task(transformation, oracle) for transformation in transformations]
    for t in temp:
        if t is not nothing:
            final.append(t)
    return final
end


def process_from_problems(problems):
    ids = []
    forms = []
    ns = []
    for problem in problems:
        nvariables = problem.n_vars
        form = problem.form
        variable_names = problem.var_names
        id = problem.eq_id

        oracle = Oracle(nvariables, form=form, variable_names=variable_names, id=id)
        ids.append(oracle.id)
        forms.append(oracle.form)
        ns = len(naive_procedure(oracle))
    d = {"id": ids, "form": forms, "Number of Constraints": ns}
    return d


def process_from_form_and_names(form, variable_names):
    """
    Returns a julia string which declares an array called TRUTHS
    """
    if form is None or variable_names is None:
        return "TRUTHS = []"
    nvars = len(variable_names)
    oracle = Oracle(nvariables=nvars, form=form, variable_names=variable_names)
    truths = naive_procedure(oracle)
    print("Discovered the following Auxiliary Truths")
    for truth in truths:
        print(truth)
    julia_string = "TRUTHS = ["
    for truth in truths:
        addition = truth.julia_string()
        julia_string = julia_string + addition + ", "
    julia_string = julia_string + "]"
    return julia_string


if __name__ == "__main__":
    from Transformation import  SymTransformation
    from Oracle import Oracle
    from time import time

    variable_names = ["alpha", "beta"]
    form = "alpha * beta"
    nvariables = len(variable_names)
    # range_restriction={2: (1, 20)}
    oracle = Oracle(nvariables, form=form, variable_names=variable_names)
    now = time()
    finals = naive_procedure(oracle)
    end = time()
    print(finals)
    print(end - now)
