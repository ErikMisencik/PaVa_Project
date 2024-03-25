default_fun_dict = Dict(
    #math operators
    :+ => (call) -> (return reduce(+, map(operand -> metajulia_eval(operand), call.args[2:end]))), #not sure if the eval works
    :- => (call) -> (return reduce(-, map(operand -> metajulia_eval(operand), call.args[2:end]))),
    :* => (call) -> (return reduce(*, map(operand -> metajulia_eval(operand), call.args[2:end]))),
    :/ => (call) -> (return reduce(/, map(operand -> metajulia_eval(operand), call.args[2:end]))),
    :sum =>(call) -> (return sum(map(operand -> metajulia_eval(operand), call.args[2:end]))),
    

    #compare operators
    :< => (call) -> (return metajulia_eval(call.args[2]) < metajulia_eval(call.args[3])),
    :(<=) => (call) -> (return metajulia_eval(call.args[2]) <= metajulia_eval(call.args[3])),
    :> => (call) -> (return metajulia_eval(call.args[2]) > metajulia_eval(call.args[3])),
    :(>=) => (call) -> (return metajulia_eval(call.args[2]) >= metajulia_eval(call.args[3])),
    Symbol("==") => (call) -> (return metajulia_eval(call.args[2]) == metajulia_eval(call.args[3])),
    Symbol("!=") => (call) -> (return metajulia_eval(call.args[2]) != metajulia_eval(call.args[3])),

    #unuary operators
    :! => (call) -> (return  !metajulia_eval(call.args[2])),
    
    #misc
    :println => (call) -> (return println(metajulia_eval(call.args[2]))),
    :eval => (call) -> (return metajulia_eval(call.args[2])),
)