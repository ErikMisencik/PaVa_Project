debug = true

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
    # Evaluate each expression in the block
    result = nothing
    for exp in block_exp
        result = meta_eval(exp, scope)
    end
    # Return the result of the last expression
    return result
end

function test_project()
    println("--- START TESTS ---")
    # test_basic_math_operators()
    # test_comparison_operators()
    # test_different_bool_syntax()
    test_let_syntax()
    println("--- TESTS PERFORMED ---")
end

function test_basic_math_operators()
    println(">>> TEST BASIC MATH OPERATORS >>>")
    @assert(meta_eval(:1) == 1)
    @assert(meta_eval(:"Hello, world!") == "Hello, world!")
    @assert(meta_eval(:(1 + 2)) == 3)
    @assert(meta_eval(:((1 + 2) + (1 + 2))) == 6)
    @assert(meta_eval(:((2 + 3) * (4 + 5))) == 45)
    println("<<< BASIC MATH OPERATORS TESTED <<<")
end

function test_comparison_operators()
    println(">>> TEST COMPARISON OPERATORS >>>")
    @assert(meta_eval(:(3 > 2)) == true)
    @assert(meta_eval(:(3 < 2)) == false)
    @assert(meta_eval(:(3 > 2 && 3 < 2)) == false)
    @assert(meta_eval(:(3 > 2 || 3 < 2)) == true)
    println("<<< COMPARISON OPERATORS TESTED <<<")
end

function test_different_bool_syntax()
    println(">>> TEST DIFFERENT BOOL SYNTAX >>>")

    println("*** TERNARY OPERATOR ***")
    @assert(meta_eval(:(3 > 2 ? 1 : 0)) == 1)
    @assert(meta_eval(:(5 > 2 ? 1 : 0)) == 1)
    @assert(meta_eval(:(5 < 2 ? 1 : 15)) == 15)
    @assert(meta_eval(:(2 < 6 ? 4 : 1)) == 4)
  
    println("*** PYTHON SYNTAX ***")
    @assert(meta_eval(:( if 3 > 2 1 else 0 end)) == 1)
    @assert(meta_eval(:( if 5 > 2 1 else 0 end)) == 1)
    @assert(meta_eval(:( if 5 < 2 1 else 15 end)) == 15)
    @assert(meta_eval(:( if 2 < 6 4 else 1 end)) == 4)

    println("<<< DIFFERENT BOOL SYNTAX TESTED <<<")
end

function test_let_syntax()
    println("*** LET SYNTAX ***")
    @assert(meta_eval(:(let x = 1; x end)) == 1)
    @assert(meta_eval(:(let x = 2; x*3 end)) == 6)
    @assert(meta_eval(:(let a = 1, b = 2; let a = 3; a+b end end)) == 5)
    @assert(meta_eval(:(let a = 1; a + 2 end)) == 3)
    println("*** TEST OF LET DONE SYNTAX ***")
end

test_project()