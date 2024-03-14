default_fun_dict = Dict(
    #math operators
    :+ => (call, scope) -> (return reduce(+, map(operand -> meta_eval(operand, scope), call.args[2:end]))), #not sure if the eval works
    :- => (call, scope) -> (return reduce(-, map(operand -> meta_eval(operand, scope), call.args[2:end]))),
    :* => (call, scope) -> (return reduce(*, map(operand -> meta_eval(operand, scope), call.args[2:end]))),
    :/ => (call, scope) -> (return reduce(/, map(operand -> meta_eval(operand, scope), call.args[2:end]))),
    
    #compare operators
    :< => (call, scope) -> (return meta_eval(call.args[2], scope) < meta_eval(call.args[3], scope)),
    :> => (call, scope) -> (return meta_eval(call.args[2], scope) > meta_eval(call.args[3], scope)),
    
    #misc
    :println => (call, scope) -> (return println(call.args[2]))
)

default_sym_dict = Dict(
    :&& => (operator_exp, scope) -> (return meta_eval(operator_exp.args[1], scope) && meta_eval(operator_exp.args[2], scope)),
    :|| => (operator_exp, scope) -> (return meta_eval(operator_exp.args[1], scope) || meta_eval(operator_exp.args[2], scope)),
    :if => (operator_exp, scope) -> eval_if(operator_exp.args, scope),
    :block => (operator_exp, scope) -> eval_block(operator_exp.args, scope),
    :let => (operator_exp, scope) -> (return eval_let(operator_exp.args, scope)),
    :(=) => (operator_exp, scope) -> eval_assignment(operator_exp, scope),
    :+= => (operator_exp, scope) -> (return assign_var(operator_exp.args[1], meta_eval(operator_exp.args[1], scope) + operator_exp.args[2], scope)),
    :-= => (operator_exp, scope) -> (return assign_var(operator_exp.args[1], meta_eval(operator_exp.args[1], scope) - operator_exp.args[2], scope))
)