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

function meta_eval(exp)
    if(debug)
        println(typeof(exp))
        println(exp)
    end
    if typeof(exp) == Expr
        if exp.head == :call
            if exp.args[1] == :+
                return meta_eval(exp.args[2]) + meta_eval(exp.args[3])
            elseif exp.args[1] == :*
                return meta_eval(exp.args[2]) * meta_eval(exp.args[3])
            elseif exp.args[1] == :<
                return meta_eval(exp.args[2]) < meta_eval(exp.args[3])
            elseif exp.args[1] == :>
                return meta_eval(exp.args[2]) > meta_eval(exp.args[3])
            end
        elseif exp.head == :&&
            return meta_eval(exp.args[1]) && meta_eval(exp.args[2])
        elseif exp.head == :||
            return meta_eval(exp.args[1]) || meta_eval(exp.args[2])
        elseif exp.head == :if
            eval_if(exp.args)
        elseif exp.head == :block
            eval_block(exp.args)
        end
    else
        return exp
    end
end

function eval_if(if_exp_args)
    # if_exp_args[1] is the part of the if exp that decides if args[2] or [3] should be returned
    if !meta_eval(if_exp_args[1])
       return meta_eval(if_exp_args[3])
    end
    return meta_eval(if_exp_args[2])
end

function eval_block(block_exp)
    # Evaluate each expression in the block
    result = nothing
    for exp in block_exp
        result = meta_eval(exp)
    end
    # Return the result of the last expression
    return result
end

function test_project()
    println("--- START TESTS ---")
    test_basic_math_operators()
    test_comparison_operators()
    test_different_bool_syntax()
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

test_project()