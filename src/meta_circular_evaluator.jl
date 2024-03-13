include("testing.jl")

debug = false

function metajulia_repl()
    while true
        print(">> ")
        result = ""
        input = ""
        while true
            input = input * "\n" * readline()
            result = Meta.parse(input, 1; greedy=true, raise = false)
            if result[1].head != :incomplete
                break
            end
        end
        println(meta_eval(result[1]))
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
    if(debug)
        println(typeof(exp))
        println(exp)
        println("Current scope: ", scope)
    end
    if typeof(exp) == Expr
        if exp.head == :call
            if exp.args[1] == :+
                return meta_eval(exp.args[2], scope) + meta_eval(exp.args[3], scope)
            elseif exp.args[1] == :*  
                return meta_eval(exp.args[2], scope) * meta_eval(exp.args[3], scope)
            elseif exp.args[1] == :/  
                return meta_eval(exp.args[2], scope) / meta_eval(exp.args[3], scope)
            elseif exp.args[1] == :<
                return meta_eval(exp.args[2], scope) < meta_eval(exp.args[3], scope)
            elseif exp.args[1] == :>
                return meta_eval(exp.args[2], scope) > meta_eval(exp.args[3], scope)
            elseif is_symbol(exp.args[1])
                return eval_func_call(exp.args, scope)
            end
        elseif exp.head == :&&
            return meta_eval(exp.args[1], scope) && meta_eval(exp.args[2], scope)
        elseif exp.head == :||
            return meta_eval(exp.args[1], scope) || meta_eval(exp.args[2], scope)
        elseif exp.head == :if
            eval_if(exp.args, scope)
        elseif exp.head == :block
            eval_block(exp.args, scope)
        elseif exp.head == :let
            return eval_let(exp.args, scope)
        elseif exp.head == :(=)  # Handling assignment
            return assign_var(exp.args[1], exp.args[2], scope)
        elseif exp.head == :+=
           return assign_var(exp.args[1], meta_eval(exp.args[1], scope) + exp.args[2], scope) 
        elseif exp.head == :-=
            return assign_var(exp.args[1], meta_eval(exp.args[1], scope) - exp.args[2], scope) 
        end
    elseif typeof(exp) == Symbol  # Handling variables
        if haskey(scope, exp)
            return scope[exp]
        else
            error("Undefined variable: ", exp)
        end
    else
        return exp
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

test_project()