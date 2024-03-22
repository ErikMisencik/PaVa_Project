default_sym_dict = Dict(
    :&& => (operator_exp, scope) -> (return metajulia_eval(operator_exp.args[1], scope) && metajulia_eval(operator_exp.args[2], scope)),
    :|| => (operator_exp, scope) -> (return metajulia_eval(operator_exp.args[1], scope) || metajulia_eval(operator_exp.args[2], scope)),
    :if => (operator_exp, scope) -> eval_if(operator_exp.args, scope),
    :elseif => (operator_exp, scope) -> eval_if(operator_exp.args, scope),
    :block => (operator_exp, scope) -> eval_block(operator_exp.args, scope),
    :let => (operator_exp, scope) -> (return eval_let(operator_exp.args, scope)),
    :(=) => (operator_exp, scope) -> eval_assignment(operator_exp, scope),
    :+= => (operator_exp, scope) -> (return assign_var(operator_exp.args[1], metajulia_eval(operator_exp.args[1], scope) + operator_exp.args[2], scope)),
    :-= => (operator_exp, scope) -> (return assign_var(operator_exp.args[1], metajulia_eval(operator_exp.args[1], scope) - operator_exp.args[2], scope)),
    :tuple => (operator_exp, scope) -> tuple(operator_exp.args...),
    :(:=) => (operator_exp, scope) ->  eval_fexpr_def(operator_exp, scope),
    :-> => (operator_exp, scope) ->  return Fun_Def(operator_exp.args[1:end-1], operator_exp.args[2].args[2])
)