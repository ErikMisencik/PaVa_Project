include("testing.jl")

debug = false

# function metajulia_repl()
#     while true
#         print(">> ")
#         a = readline() # keep record of multiple readlines until parser accepts the input
#         result = Meta.parse(input) # AST
#         # call eval function
#     end
# end
# metajulia_repl()

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
            var_name = exp.args[1]
            var_value = meta_eval(exp.args[2], scope)
            scope[var_name] = var_value
            return var_value
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

function eval_let(let_exp_args, outer_scope)
    local_scope = deepcopy(outer_scope)  # Inherit outer scope
    result = nothing
    for exp in let_exp_args
        if exp.head == :(=)
            var_name = exp.args[1]
            var_value = meta_eval(exp.args[2], local_scope)
            local_scope[var_name] = var_value  # Update local_scope
            # In eval_let, after updating local_scope
            #println("Updated local_scope: ", local_scope)
        else
            result = meta_eval(exp, local_scope)  # Use updated local_scope
        end
    end
    #println("*** Final result of 'let' block: ", result)
    return result
end

function eval_if(if_exp_args, scope)
    # if_exp_args[1] is the part of the if exp that decides if args[2] or [3] should be returned
    if !meta_eval(if_exp_args[1], scope)
       return meta_eval(if_exp_args[3], scope)
    end
    return meta_eval(if_exp_args[2], scope)
end

function eval_block(block_exp, scope)
   # println(block_exp)
    #println(typeof(block_exp))
    args_length = length(block_exp)
    #println(args_length)

    i = 1
    while i < args_length 
        println(i)
        println(block_exp[i])
        #meta_eval(block_exp.args[i])
        i += 1 

    end
    println(i)



    println(meta_eval((block_exp[i])))
    return meta_eval(block_exp[i])
end

#test_project()

#dump((1+2; 2*3; 3/4))

#x = :(1+2; 2*3; 3/4)
#dump(x)


#meta_eval(:(1+2; 2*3; 3/4))
