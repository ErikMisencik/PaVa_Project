using Test

function test_project()
    println("--- START TESTS ---")
    @assert(metajulia_eval(:"Hello, world!") == "Hello, world!")
    test_misc_symbols() 
    test_basic_math_operators()
    test_comparison_operators()
    test_different_bool_syntax()
    test_short_circuit_evaluation()
    test_blocks()
    test_let()
    # test_anonymous_functions()
    test_implicit_assignments()
    test_reflection()
    #test_fexpr()
    test_special_functions()
    test_macros()
    println("--- TESTS PERFORMED ---")
    
end

function test_misc_symbols() 
    println(">>> TEST MISC SYMBOLS >>>")

    println("*** TUPLES ***")
    @test metajulia_eval(:(1, "Hallo", 3.14)) == (1, "Hallo", 3.14) 

    println("<<< MISC SYMBOLS TESTED <<<")
end

function test_basic_math_operators()
    println(">>> TEST BASIC MATH OPERATORS >>>")
    
    println("*** ADDITION ***")
    @assert(metajulia_eval(:(1 + 2)) == 3, metajulia_eval(:(1 + 2)))
    @assert(metajulia_eval(:((1 + 2) + (1 + 2))) == 6)
    @test metajulia_eval(:(sum(5,2,4,5,5,6,6,43,2))) == 78 
    @test metajulia_eval(:(sum((5+2),(4*2),(6/3)))) == 17 

    println("*** SUBTRACTION ***")
    @assert(metajulia_eval(:(1 - 2)) == -1)
    @assert(metajulia_eval(:((1 - 2) - (1 - 2))) == 0)
    
    println("*** MULTIPLICATION ***")
    @assert(metajulia_eval(:(1 * 2)) == 2)
    @assert(metajulia_eval(:((-2 * 3))) == -6)
    @assert(metajulia_eval(:((2 + 3) * (4 + 5))) == 45)

    println("*** DIVISION ***")
    @assert(metajulia_eval(:((2 + 3) / (5))) == 1)
    @assert(metajulia_eval(:(14 / 7)) == 2)
    @assert(metajulia_eval(:((3.0 - 6) /2)) == -1.5)
    @assert(metajulia_eval(:(-14/7)) == -2)

    println("*** MORE THAN TWO OPERANDS ***")
    @assert(metajulia_eval(:((2 + 3 + 4))) == 9)
    @assert(metajulia_eval(:((3 - 2 - 1 - 1 ))) == -1)
    @assert(metajulia_eval(:((3 * 2 * 1 ))) == 6)
    @assert(metajulia_eval(:((8 / 2 / 2 ))) == 2)

    println("<<< BASIC MATH OPERATORS TESTED <<<")
end

function test_comparison_operators()
    println(">>> TEST COMPARISON OPERATORS >>>")
    @assert(metajulia_eval(:(3 > 2)) == true)
    @assert(metajulia_eval(:(3 < 2)) == false)
    @assert(metajulia_eval(:(3 > 2 && 3 < 2)) == false)
    @assert(metajulia_eval(:(3 > 2 || 3 < 2)) == true)
    @assert(metajulia_eval(:(2 == 2)) == true)
    @assert(metajulia_eval(:(3 == 2)) == false)
    @assert(metajulia_eval(:(2 != 2)) == false)
    @assert(metajulia_eval(:(3 != 2)) == true)
    println("<<< COMPARISON OPERATORS TESTED <<<")
end

function test_different_bool_syntax()
    println(">>> TEST DIFFERENT BOOL SYNTAX >>>")

    println("*** TERNARY OPERATOR ***")
    @assert(metajulia_eval(:(3 > 2 ? 1 : 0)) == 1)
    @assert(metajulia_eval(:(5 > 2 ? 1 : 0)) == 1)
    @assert(metajulia_eval(:(5 < 2 ? 1 : 15)) == 15)
    @assert(metajulia_eval(:(2 < 6 ? 4 : 1)) == 4)
  
    println("*** PYTHON SYNTAX ***")
    @assert(metajulia_eval(:( if 3 > 2 1 else 0 end)) == 1)
    @assert(metajulia_eval(:( if 3 > 2 
                            1 
                        else 
                            0 
                        end)) == 1)
    @assert(metajulia_eval(:( if 5 > 2 1 else 0 end)) == 1)
    @assert(metajulia_eval(:(if 3 < 2 1 elseif 2 > 3 2 else 0 end)) == 0)
    @assert(metajulia_eval(:( if 5 < 2 1 else 15 end)) == 15)
    @assert(metajulia_eval(:( if 2 < 6 4 else 1 end)) == 4)

    println("<<< DIFFERENT BOOL SYNTAX TESTED <<<")
end

function test_short_circuit_evaluation()
    scope=Dict()
    println(">>> TEST SHORT-CIRCUIT EVALUATION >>>")
    @assert(metajulia_eval(:(quotient_or_false(a, b) = !(b == 0) && a/b), scope) !== nothing)
    @assert(metajulia_eval(:(quotient_or_false(6, 2)), scope) == 3.0)
    @assert(metajulia_eval(:(quotient_or_false(6, 0)), scope) == false)
    @assert(metajulia_eval(:(compare_values(x, y)= x == y), scope) !== nothing)
    @assert(metajulia_eval(:(2 < 1 || compare_values(5, 5)),scope) == true)
    @assert(metajulia_eval(:(2 < 1 || compare_values(5, 4)),scope) == false)
    @assert(metajulia_eval(:(5 > 1 && compare_values(5, 5)),scope) == true)
    @assert(metajulia_eval(:(5 > 1 && compare_values(5, 4)),scope) == false)
    println("<<< SHORT-CIRCUIT EVALUATION TESTED <<<")
end

function test_blocks()
    println(">>> TEST BLOCKS >>>")
    @assert(metajulia_eval(:(1+2; 2*3; 3/4)) == 0.75)
    @assert(metajulia_eval(:(begin 1+2; 2*3; 3/4 end)) == 0.75)
    @assert(metajulia_eval(:((a = 0; a +=1; a))) == 1)
    @assert(metajulia_eval(:((a = 0; a -=1; a))) == -1)
    @assert(metajulia_eval(:(begin println("first"); println("second"); "test" end)) == "test")
    println("<<< BLOCKS TESTED <<<")
end

function test_let()
    println(">>> TEST LET >>>")
    @assert(metajulia_eval(:1) == 1)
    println("*** ASSIGNMENT WITH LEXICAL SCOPE ***")
    @assert(metajulia_eval(:(let x = 1; x end)) == 1)
    @assert(metajulia_eval(:(let x = 2; x*3 end)) == 6)
    @assert(metajulia_eval(:(let a = 1, b = 2; let a = 3; a+b end end)) == 5)
    @assert(metajulia_eval(:(let a = 1
                         a + 2 end)) == 3)
    println("<<< LET TESTED <<<")
end

function test_implicit_assignments()
    scope=Dict()
    println(">>> TEST IMPLICIT ASSIGNMENTS >>>")
    @assert(metajulia_eval(:(x = 1)) == 1)
    @assert(metajulia_eval(:(x = 1 + 2), scope) == 3)
    @assert(metajulia_eval(:(x + 2), scope) == 5)
    @assert(metajulia_eval(:(triple(a) = a + a + a), scope) !== nothing)
    @assert(metajulia_eval(:(triple(x+3)), scope)  == 18)
    @assert(metajulia_eval(:(baz = 3), scope)  == 3)
    @assert(metajulia_eval(:(let x = 0 
                                baz = 5
                                end + baz), scope)  == 8)
    # @assert(meta_eval(:(let ; baz = 6 end + baz), scope)  == 9)

    println("<<< IMPLICIT ASSIGNMENTS TESTED <<<")   
end

function test_reflection()
    scope=Dict()
    println(">>> TEST OF REFLECTION >>>")
    @assert(metajulia_eval(:(:foo), scope) == :foo)
    @assert(metajulia_eval(:(:(foo + bar)), scope) == :(:(foo + bar)))
    @assert(metajulia_eval(:((1 + 2) * $(1 + 2)), scope) == ((1 + 2) * 3))
    println("<<< REFLECTION TESTED <<<")
end

function test_fexpr()
    scope=Dict()
    println(">>> TEST OF FEXPR >>>")
    @assert(metajulia_eval(:(identity_function(x) = x), scope) !== nothing)
    @assert(metajulia_eval(:(identity_function(1+2)), scope)  == 3)
    @assert(metajulia_eval(:(identity_fexpr(x) := x), scope) !== nothing)
    @assert(metajulia_eval(:(identity_fexpr(1+2)), scope)  == :(1 + 2))
    @assert(metajulia_eval(:(identity_fexpr(1+2) == :(1+2)), scope) == true) # TODO I dont  understand, they print the same result...
    println("<<< FEXPR TESTED <<<")
end

function test_special_functions() 
    scope=Dict()
    println(">>> TEST SPECIAL FUNCTIONS >>>")

    println("*** RECURSIVE FUNCTIONS ***")
    @assert(metajulia_eval(:(factorial(n) = n == 0 ? 1 : n * factorial(n - 1)), scope) !== nothing)
    @assert(metajulia_eval(:(factorial(5)), scope) == 120)
    @assert(metajulia_eval(:(fibonacci(n) = n <= 1 ? n : fibonacci(n - 1) + fibonacci(n - 2)), scope) !== nothing)
    @assert(metajulia_eval(:(fibonacci(6)), scope) == 8)

    println("*** HIGHER ORDER FUNCTIONS ***")
    @assert(metajulia_eval(:(sum(f, a, b) = 
                                    a > b ?
                                        0 :
                                        f(a) + sum(f, a + 1, b)), scope) !== nothing)
    metajulia_eval(:(triple(a) = a + a + a), scope)
    @assert(metajulia_eval(:(sum(triple, 1, 10)),scope) == 165)
    @assert(metajulia_eval(:(square(a) = a * a), scope) !== nothing)
    @assert(metajulia_eval(:(sum(square, 1, 5)), scope) == 55)
    @assert(metajulia_eval(:(product(a, b) = a * b), scope) !== nothing)
    @assert(metajulia_eval(:(sum(product, 1, 5)), scope) == 75)
    println("<<< SPECIAL FUNCTIONS TESTED <<<")
end

function test_macros()
    scope=Dict()
    println("<<< TEST OF MACROS <<<")

    metajulia_eval(:(when(condition, action) $= :($condition ? $action : false)), scope)
    @assert(metajulia_eval(:(when(true, 3)), scope) == 3)

    println("<<< MACROS TESTED <<<")
end