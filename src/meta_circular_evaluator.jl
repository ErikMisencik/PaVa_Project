include("testing.jl")
include("default_env.jl")

debug = false

function metajulia_repl()
    scope = Dict()
    while true
        print(">> ")
        result = ""
        input = ""
        while true
            input = input * "\n" * readline()
            result = Meta.parse(input, 1; greedy=true, raise=false)
            if result[1].head != :incomplete
                break
            end
        end
        println(meta_eval(result[1], scope))
    end
end

function metajulia_eval(exp, scope)
    return meta_eval(exp, scope)
end

"""
Could lead to very interesting use cases. If we are able to read julia code as string we could expose an api that takes julia code as input and we can process
this with our meta evaluator.
"""
function meta_eval_string(input_string)
    #cast string to expression
    expr = Meta.parse(input_string)
    meta_eval(expr)
end

function meta_eval(exp, scope=Dict())
    if (debug)
        println(typeof(exp))
        println(exp)
        println("Current scope: ", scope)
    end
    if is_expression(exp)
        return eval_exp(exp, scope)
    elseif is_symbol(exp)
        return return_var(exp, scope)
    elseif is_quote(exp)
        eval_quote(exp, scope)
    else
        return exp
    end
end

function eval_quote(quote_exp, scope)

    if is_expression(quote_exp) && quote_exp.head == :$
        # Evaluate the interpolated expression
        return meta_eval(quote_exp.args[1], scope)

    ############### START ADDED FOR MACRO ##############
    elseif is_expression(quote_exp) && quote_exp.head == :quote
        if is_macro_expansion(quote_exp, scope)
            # Evaluate the content of the quote if it's part of a macro expansion
            return meta_eval(quote_exp.args[1], scope)
        else
            return quote_exp
        end
    ############### END OF ADDED FOR MACRO ##############

    elseif isa(quote_exp, QuoteNode)
        # Return the value of the QuoteNode as is
        return quote_exp.value
    else
        return quote_exp
    end
end

function return_var(name, scope)
    if haskey(scope, name)
        return scope[name]
    else
        return name
    end
end

function eval_exp(exp, scope)

    ############### START ADDED FOR MACRO ##############
    # First check if it's a macro call or definition
    macro_type = is_macro_expansion(exp, scope)
    if macro_type == :macro_def
        return define_macro(exp, scope)
    elseif macro_type == :macro
        return eval_macro(exp, scope)
    end
    ############### END OF ADDED FOR MACRO ##############
 
    if exp.head == :quote
        eval_quote(exp, scope)  # Handle quoted expressions
    elseif exp.head != :call
        eval_operator(exp, scope)
    else
        eval_call(exp, scope)
    end
end

function eval_operator(operator_exp, scope)
    if haskey(default_sym_dict, operator_exp.head)
        # the dict defines basic operation they can be retrieved by the value 
        return default_sym_dict[operator_exp.head](operator_exp, scope)
    end
    throw(UndefVarError("Operator '$operator_exp.head' not defined."))
end

# First the scope is checked for a name reference. This allows to override default fun. 
function eval_call(call, scope)
    fun_name = call.args[1]
    if is_fun_defined(fun_name, scope)
        return eval_fun_call(call.args, scope)
    end
    if is_default_fun_defined(fun_name)
        # the dict defines basic operation they can be retrieved by the value 
        return default_fun_dict[fun_name](call, scope)
    end
    if is_anonymous_call(call)
        anonymous_Fun = Anonymous_Fun(meta_eval(call.args[1].args[1]), call.args[2:end], call.args[1].args[2].args[2])
        return eval_anonymous_call(anonymous_Fun)
    end
    if typeof(scope[call.args[1]]) == fexpr
        return eval_fexpr_call(call.args, scope)
    end
    if haskey(scope,call.args[1])        
        eval_fun_call(call.args, scope)    
    end
    throw(UndefVarError("Function '$fun_name' not defined."))
end

struct Anonymous_Fun
    inner_scope::Dict
    body::Any # can be expression or return value
end

function Anonymous_Fun(var_names, var_values, body)
    var_names = typeof(var_names) == Symbol ? [var_names] : var_names
    inner_scope = Dict(zip(var_names, var_values))
    return Anonymous_Fun(inner_scope, body)
end

function eval_anonymous_call(anonymous_Fun)
    return(meta_eval(anonymous_Fun.body, anonymous_Fun.inner_scope))
end

function is_anonymous_call(call)
    if typeof(call.args[1]) == Expr
        if call.args[1].head == :->
            return true
        end
    end
    return false
end

function is_default_fun_defined(fun_name)
    return haskey(default_fun_dict, fun_name)
end

function assign_var(var_name, var_value_exp, scope) # maybe in a later point of the project the var_name should also be evaluated
    var_value = meta_eval(var_value_exp, scope)
    scope[var_name] = var_value # Update scope
    return var_value
end

function eval_let(let_exp_args, outer_scope)

    let_exp_init = let_exp_args[1]
    let_exp_body = let_exp_args[2:end]
    local_scope = deepcopy(outer_scope)  # Inherit outer scope
    result = nothing

    if is_assignment(let_exp_init)   # if init only has 1 assignment
        eval_let_defs(let_exp_init, local_scope)
    else
        for exp in let_exp_init.args
            if (length(exp.args) > 1) && is_assignment(exp)   # if init is not empty
                eval_let_defs(exp, local_scope)
            end
        end
    end

    for exp in let_exp_body
        if length(exp.args) > 1    # if body is not empty expression
            if is_assignment(exp)
                eval_let_defs(exp, local_scope)
            else
                result = meta_eval(exp, local_scope)  # Use updated local_scope
            end
        end
    end
    return result
end

function eval_let_defs(exp, scope)
    var_name = exp.args[1]

    if is_expression(var_name)
        assign_fun(var_name, exp.args[2], scope)   # Function Definition
    else
        assign_var(var_name, meta_eval(exp.args[2], scope), scope)
    end
end

struct Fun_Def
    input_params::Any
    body::Any
end   

function assign_fun(function_decl, function_exp, scope)
    # Extract function parameters and body
    name = function_decl.args[1]
    params = function_decl.args[2:end]
    body = function_exp.args[end]

    params = is_symbol(params) ? (params,) : params     # Put param in tuple if singular one param
    fun_dev = Fun_Def(params, body)
    scope[name] = fun_dev   # Update scope
end 

struct UserFunction # System does not allow to use the name Function
    body::Any
    local_scope::Dict
end

function userFunction(fun_call_exp_args, scope)
    fun_name = fun_call_exp_args[1]
    param_values = map(x -> meta_eval(x, scope), fun_call_exp_args[2:end])

    fun_dev = scope[fun_name]
    local_scope = Dict(zip(fun_dev.input_params, param_values))
    body = fun_dev.body
    return UserFunction(body, local_scope)
end

function eval_fun_call(fun_call_exp_args, scope)
    fun = userFunction(fun_call_exp_args, scope)
    fun_scope = merge(scope, fun.local_scope)
    result = meta_eval(fun.body, fun_scope)
    return result
end

function is_fun_defined(fun_name, scope)
    return haskey(scope, fun_name) && typeof(scope[fun_name]) == Fun_Def
end

function eval_if(if_exp_args, scope)
    args_length = length(if_exp_args)
    i = 1
    # if_exp_args[] is the part of the if exp that decides if args[2] or [3] should be returned
    while i < args_length
        if meta_eval(if_exp_args[i], scope) # if_exp_args[i] is the boolean expression
            return meta_eval(if_exp_args[i + 1], scope) # if_exp_args[i + 1] is the value to return
        else
            i += 2
        end
    end
    return meta_eval(if_exp_args[end], scope)
end

function eval_block(block_args, scope)
    args_length = length(block_args)     #block_args represent the instructions inside the block body
    i = 1     #in julia arrays start at 1
    while i < args_length
        meta_eval(block_args[i], scope)
        i += 1
    end
    return meta_eval(block_args[i], scope)
end

function is_expression(var)
    return isa(var, Expr)
end

function is_quote(quote_node)
    return isa(quote_node, QuoteNode)
end

function is_assignment(exp)
     return exp.head == :(=)
end

function is_symbol(var)
    return isa(var, Symbol)
end

function eval_assignment(operator_exp, scope)

    if is_expression(operator_exp.args[2])
        #define_fun(operator_exp, scope)
    end

    # if call is a function definition
    if is_expression(operator_exp.args[1]) 
        return assign_fun(operator_exp.args[1], operator_exp.args[2], scope)
    else
        return assign_var(operator_exp.args[1], operator_exp.args[2], scope)
    end
end

struct fexpr
    params
    body
end

function eval_fexpr_def(function_decl, scope)
    # Extract function parameters and body
    name = function_decl.args[1].args[1]
    params = function_decl.args[1].args[2:end]
    body = function_decl.args[end]

    function_object = fexpr( params, body)  # Create a function object
    scope[name] = function_object   # Update scope

end
	
function eval_fexpr_call(fun_call_exp_args, scope)
    fun_name = fun_call_exp_args[1]
    param_values = deepcopy(fun_call_exp_args[2:end])       
    for i in eachindex(param_values)
        if is_expression(param_values[i])
            param_values[i] = param_values[i]
        end
    end
    function_object = scope[fun_name]
    params = function_object.params
    body = function_object.body
    # Create a local scope for the function call
    local_scope = Dict(zip(params, param_values))
    # Evaluate the function body in the local scope
    result = meta_eval(body, local_scope)

    return result
end

 ############### START ADDED FOR MACRO ##############
function define_macro(exp, scope)
    macro_name = exp.args[1].args[1]  # Extracting the macro name
    macro_body = exp.args[2]  # Extracting the macro body
    scope[string(macro_name)] = (:macro, exp.args[1].args[2:end], macro_body)
end

function eval_macro(exp, scope)
    macro_name = string(exp.args[1])
    macro_def = scope[macro_name]
    macro_body = macro_def[3]
    macro_args = exp.args[2:end]

    for (param, arg) in zip(macro_def[2], macro_args)
        macro_body = replace_expr(macro_body, Expr(:$, param), arg)
    end
    fix_scope = Dict()
    return meta_eval(macro_body.args[1], fix_scope)
end

function is_macro_expansion(exp, scope)
    if isa(exp, Expr) && exp.head == :call
        macro_name = string(exp.args[1])
        return haskey(scope, macro_name) ? :macro : false
    elseif isa(exp, Expr) && exp.head == :$=
        return :macro_def
    end
    return false
end


function replace_expr(expr, to_replace, replacement)
    if expr == to_replace
        return replacement
    elseif isa(expr, Expr)
        # ericek na tuto casť kodu musis spravit evaluaciu, meta_eval(keke, scope) a nejako poriesiť scope ak treba ale možno netreba.
        return Expr(expr.head, [replace_expr(arg, to_replace, replacement) for arg in expr.args]...)
    else
        return expr
    end
end
 ############### END OF ADDED FOR MACRO ##############