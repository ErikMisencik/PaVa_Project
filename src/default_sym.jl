default_sym_dict = Dict(
    :&& => (operator_exp) -> (return metajulia_eval(operator_exp.args[1]) && metajulia_eval(operator_exp.args[2])),
    :|| => (operator_exp) -> (return metajulia_eval(operator_exp.args[1]) || metajulia_eval(operator_exp.args[2])),
    :if => (operator_exp) -> eval_if(operator_exp.args),
    :elseif => (operator_exp) -> eval_if(operator_exp.args),
    :block => (operator_exp) -> eval_block(operator_exp.args),
    :let => (operator_exp) -> (return eval_let(operator_exp.args)),
    :(=) => (operator_exp) -> eval_assignment(operator_exp),
    :+= => (operator_exp) -> (return assign_var(operator_exp.args[1], metajulia_eval(operator_exp.args[1]) + operator_exp.args[2])),
    :-= => (operator_exp) -> (return assign_var(operator_exp.args[1], metajulia_eval(operator_exp.args[1]) - operator_exp.args[2])),
    :tuple => (operator_exp) -> tuple(operator_exp.args...),
    :(:=) => (operator_exp) ->  eval_fexpr_def(operator_exp),
    :(->) => (operator_exp) -> Anonymous_Fun(operator_exp.args[1], operator_exp.args[2]),
    :global => (operator_exp) -> eval_global(operator_exp.args[1])
)