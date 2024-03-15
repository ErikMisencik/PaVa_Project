include("testing.jl")
include("default_env.jl")

debug = false

function metajulia_repl()
    scope=Dict()
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
        println(meta_eval(result[1]), scope)
    end
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
        eval_exp(exp, scope)
    elseif is_symbol(exp)
        return_var(exp, scope)
    else
        return exp
    end
end

function return_var(name, scope)
    if haskey(scope, name)
        return scope[name]
    else
        error("Undefined variable: ", name)
    end
end

function eval_exp(exp, scope)
    if exp.head != :call
        eval_operator(exp, scope)
    else
        eval_call(exp, scope)
    end
end

function eval_operator(operator_exp, scope)
    if haskey(default_sym_dict, operator_exp.head)
        # the dict defines basic operation they can be retrieved by the value 
        return default_sym_dict[operator_exp.head](operator_exp, scope)
    else
        error("Undefined operator ", operator_exp.head)
    end
end

function eval_call(call, scope)
    if haskey(default_fun_dict, call.args[1])
        # the dict defines basic operation they can be retrieved by the value 
        return default_fun_dict[call.args[1]](call, scope)
    elseif is_symbol(call.args[1])
        if is_expression(call.args[2])
            operation = deepcopy(call.args)
            operation[2] = meta_eval(call.args[2], scope)
            return  eval_func_call(operation , scope)
        else
            return eval_func_call(call.args, scope)
        end
    else
        error("Undefined call ", call.args[1])
    end
end

function assign_var(var_name, var_value_exp, scope) # maybe in a later point of the project the var_name should also be evaluated
    var_value = meta_eval(var_value_exp, scope)
    scope[var_name] = var_value # Update scope
    return var_value
end

function eval_let(let_exp_args, outer_scope)
    local_scope = deepcopy(outer_scope)  # Inherit outer scope
    result = nothing
    for exp in let_exp_args
        if exp.head == :(=)
            var_name = exp.args[1]
            if is_expression(var_name)
                # Function Definition
                eval_let_func_def(var_name, exp.args[2], local_scope)
            else
                assign_var(var_name, meta_eval(exp.args[2], local_scope), local_scope)
            end
        else
            result = meta_eval(exp, local_scope)  # Use updated local_scope
        end
    end
    #println("*** Final result of 'let' block: ", result)
    return result
end

function eval_let_func_def(function_decl, function_exp, scope)
    # Extract function parameters and body
    name = function_decl.args[1]
    params = function_decl.args[2:end]
    body = function_exp.args[end]

    params = is_symbol(params) ? (params,) : params     # Put param in tuple if singular one param
    function_object = Expr(:function, params..., body)  # Create a function object
    scope[name] = function_object   # Update scope
end

function eval_func_call(func_call_exp, scope)
    name = func_call_exp[1]
    local_scope_vals = func_call_exp[2:end]

    # Check if the function is defined in the scope
    if haskey(scope, name) && typeof(scope[name]) == Expr && scope[name].head == :function
        function_object = scope[name]
        params = function_object.args[1:end-1]
        body = function_object.args[end]

        # Create a local scope for the function call
        local_scope = Dict(zip(params, local_scope_vals))

        # Evaluate the function body in the local scope
        result = meta_eval(body, local_scope)

        return result
    else
        error("Function '$name' not defined.")
    end
end

function eval_if(if_exp_args, scope)
    # if_exp_args[1] is the part of the if exp that decides if args[2] or [3] should be returned
    if !meta_eval(if_exp_args[1], scope)
        return meta_eval(if_exp_args[3], scope)
    end
    return meta_eval(if_exp_args[2], scope)
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

function is_symbol(var)
    return isa(var, Symbol)
end

function eval_assignment(operator_exp, scope)
    # if call is a function definition
    if is_expression(operator_exp.args[1])
       return eval_let_func_def(operator_exp.args[1], operator_exp.args[2], scope)
   else
   return assign_var(operator_exp.args[1], operator_exp.args[2], scope)
   end
end

test_project()