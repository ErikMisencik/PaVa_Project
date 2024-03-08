# function metajulia_repl()
#     while true
#         print(">> ")
#         a = readline() # keep record of multiple readlines until parser accepts the input
#         result = Meta.parse(input) # AST
#         # call eval function
#     end
# end
# metajulia_repl()

function meta_eval(input)
    println(input)
    if typeof(input) == Expr
        if input.head == :call
            if input.args[1] == :+
                return meta_eval(input.args[2]) + meta_eval(input.args[3])
            elseif input.args[1] == :*
                return meta_eval(input.args[2]) * meta_eval(input.args[3])
            elseif input.args[1] == :<
                return meta_eval(input.args[2]) < meta_eval(input.args[3])
            elseif input.args[1] == :>
                return meta_eval(input.args[2]) > meta_eval(input.args[3])
            end
        elseif input.head == :&&
            return meta_eval(input.args[1]) && meta_eval(input.args[2])
        elseif input.head == :||
            return meta_eval(input.args[1]) || meta_eval(input.args[2])
        end
    else
        return input
    end
end

function test_project()
    println("--- START TESTS ---")
    test_basic_operators()
    println("--- TESTS PERFORMED ---")
end

function test_basic_operators()
    println("*** TEST BASIC OPERATORS ***")
    @assert(meta_eval(:1) == 1)
    @assert(meta_eval(:"Hello, world!") == "Hello, world!")
    @assert(meta_eval(:(1 + 2)) == 3)
    @assert(meta_eval(:((1 + 2) + (1 + 2))) == 6)
    @assert(meta_eval(:((2 + 3) * (4 + 5))) == 45)
    @assert(meta_eval(:(3 > 2)) == true)
    @assert(meta_eval(:(3 < 2)) == false)
    @assert(meta_eval(:(3 > 2 && 3 < 2)) == false)
    @assert(meta_eval(:(3 > 2 || 3 < 2)) == true)
    println("*** BASIC OPERATORS TESTED ***")
end

test_project()