default_fun_dict = Dict(
    :+ => (call, scope) -> (return meta_eval(call.args[2], scope) + meta_eval(call.args[3], scope)),
    :* => (call, scope) -> (return meta_eval(call.args[2], scope) * meta_eval(call.args[3], scope)),
    :/ => (call, scope) -> (return meta_eval(call.args[2], scope) / meta_eval(call.args[3], scope)),
    :< => (call, scope) -> (return meta_eval(call.args[2], scope) < meta_eval(call.args[3], scope)),
    :> => (call, scope) -> (return meta_eval(call.args[2], scope) > meta_eval(call.args[3], scope)),
    :println => (call, scope) -> (return println(call.args[2]))
)