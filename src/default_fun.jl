default_fun_dict = Dict(
    #math operators
    :+ => (call, scope) -> (return reduce(+, map(operand -> metajulia_eval(operand, scope), call.args[2:end]))), #not sure if the eval works
    :- => (call, scope) -> (return reduce(-, map(operand -> metajulia_eval(operand, scope), call.args[2:end]))),
    :* => (call, scope) -> (return reduce(*, map(operand -> metajulia_eval(operand, scope), call.args[2:end]))),
    :/ => (call, scope) -> (return reduce(/, map(operand -> metajulia_eval(operand, scope), call.args[2:end]))),
    :sum =>(call, scope) -> (return sum(map(operand -> metajulia_eval(operand, scope), call.args[2:end]))),
    

    #compare operators
    :< => (call, scope) -> (return metajulia_eval(call.args[2], scope) < metajulia_eval(call.args[3], scope)),
    :(<=) => (call, scope) -> (return metajulia_eval(call.args[2], scope) <= metajulia_eval(call.args[3], scope)),
    :> => (call, scope) -> (return metajulia_eval(call.args[2], scope) > metajulia_eval(call.args[3], scope)),
    :(>=) => (call, scope) -> (return metajulia_eval(call.args[2], scope) >= metajulia_eval(call.args[3], scope)),
    Symbol("==") => (call, scope) -> (return metajulia_eval(call.args[2], scope) == metajulia_eval(call.args[3], scope)),
    Symbol("!=") => (call, scope) -> (return metajulia_eval(call.args[2], scope) != metajulia_eval(call.args[3], scope)),

    #unuary operators
    :! => (call, scope) -> (return  !metajulia_eval(call.args[2], scope)),
    
    #misc
    :println => (call, scope) -> (return println(metajulia_eval(call.args[2], scope)))
)