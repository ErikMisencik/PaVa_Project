default_fun_dict = Dict(
    :+ => (call, scope) -> (return meta_eval(call.args[2], scope) + meta_eval(call.args[3], scope)),
    :- => (call, scope) -> (return meta_eval(call.args[2], scope) - meta_eval(call.args[3], scope)),
    :* => (call, scope) -> (return meta_eval(call.args[2], scope) * meta_eval(call.args[3], scope)),
    :/ => (call, scope) -> (return meta_eval(call.args[2], scope) / meta_eval(call.args[3], scope)),
    :< => (call, scope) -> (return meta_eval(call.args[2], scope) < meta_eval(call.args[3], scope)),
    :> => (call, scope) -> (return meta_eval(call.args[2], scope) > meta_eval(call.args[3], scope)),
    :println => (call, scope) -> (return println(call.args[2]))
)

default_sym_dict = Dict(
    :&& => (operator_exp, scope) -> ( return meta_eval(operator_exp.args[1], scope) && meta_eval(operator_exp.args[2], scope)),
    :|| => (operator_exp, scope) -> (return meta_eval(operator_exp.args[1], scope) || meta_eval(operator_exp.args[2], scope)),
    :if => (operator_exp, scope) -> eval_if(operator_exp.args, scope),
    :block => (operator_exp, scope) -> eval_block(operator_exp.args, scope),
    :let => (operator_exp, scope) -> (return eval_let(operator_exp.args, scope)),
    :(=) => (operator_exp, scope) -> eval_assignment(operator_exp, scope),
    :+= => (operator_exp, scope) -> ( return assign_var(operator_exp.args[1], meta_eval(operator_exp.args[1], scope) + operator_exp.args[2], scope)),
    :-= => (operator_exp, scope) -> (  return assign_var(operator_exp.args[1], meta_eval(operator_exp.args[1], scope) - operator_exp.args[2], scope))
)