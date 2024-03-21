using Test

function test_project()
    println("--- START TESTS ---")
    @assert(meta_eval(:"Hello, world!") == "Hello, world!")
    test_misc_symbols() 
    test_basic_math_operators()
    test_comparison_operators()
    test_different_bool_syntax()
    test_blocks()
    test_let()
    # test_anonymous_functions()
    test_implicit_assignments()
    test_reflection()
    #test_fexpr()
    test_special_functions()
    println("--- TESTS PERFORMED ---")
    
end

function test_misc_symbols() 
    println(">>> TEST MISC SYMBOLS >>>")

    println("*** TUPLES ***")
    @test meta_eval(:(1, "Hallo", 3.14)) == (1, "Hallo", 3.14) 

    println("<<< MISC SYMBOLS TESTED <<<")
end

function test_basic_math_operators()
    println(">>> TEST BASIC MATH OPERATORS >>>")
    
    println("*** ADDITION ***")
    @assert(meta_eval(:(1 + 2)) == 3, meta_eval(:(1 + 2)))
    @assert(meta_eval(:((1 + 2) + (1 + 2))) == 6)
    @test meta_eval(:(sum(5,2,4,5,5,6,6,43,2))) == 78 
    @test meta_eval(:(sum((5+2),(4*2),(6/3)))) == 17 

    println("*** SUBTRACTION ***")
    @assert(meta_eval(:(1 - 2)) == -1)
    @assert(meta_eval(:((1 - 2) - (1 - 2))) == 0)
    
    println("*** MULTIPLICATION ***")
    @assert(meta_eval(:(1 * 2)) == 2)
    @assert(meta_eval(:((-2 * 3))) == -6)
    @assert(meta_eval(:((2 + 3) * (4 + 5))) == 45)

    println("*** DIVISION ***")
    @assert(meta_eval(:((2 + 3) / (5))) == 1)
    @assert(meta_eval(:(14 / 7)) == 2)
    @assert(meta_eval(:((3.0 - 6) /2)) == -1.5)
    @assert(meta_eval(:(-14/7)) == -2)

    println("*** MORE THAN TWO OPERANDS ***")
    @assert(meta_eval(:((2 + 3 + 4))) == 9)
    @assert(meta_eval(:((3 - 2 - 1 - 1 ))) == -1)
    @assert(meta_eval(:((3 * 2 * 1 ))) == 6)
    @assert(meta_eval(:((8 / 2 / 2 ))) == 2)

    println("<<< BASIC MATH OPERATORS TESTED <<<")
end

function test_comparison_operators()
    println(">>> TEST COMPARISON OPERATORS >>>")
    @assert(meta_eval(:(3 > 2)) == true)
    @assert(meta_eval(:(3 < 2)) == false)
    @assert(meta_eval(:(3 > 2 && 3 < 2)) == false)
    @assert(meta_eval(:(3 > 2 || 3 < 2)) == true)
    @assert(meta_eval(:(2 == 2)) == true)
    @assert(meta_eval(:(3 == 2)) == false)
    @assert(meta_eval(:(2 != 2)) == false)
    @assert(meta_eval(:(3 != 2)) == true)
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
    @assert(meta_eval(:( if 3 > 2 
                            1 
                        else 
                            0 
                        end)) == 1)
    @assert(meta_eval(:( if 5 > 2 1 else 0 end)) == 1)
    @assert(meta_eval(:(if 3 < 2 1 elseif 2 > 3 2 else 0 end)) == 0)
    @assert(meta_eval(:( if 5 < 2 1 else 15 end)) == 15)
    @assert(meta_eval(:( if 2 < 6 4 else 1 end)) == 4)

    println("<<< DIFFERENT BOOL SYNTAX TESTED <<<")
end

function test_blocks()
    println(">>> TEST BLOCKS >>>")
    @assert(meta_eval(:(1+2; 2*3; 3/4)) == 0.75)
    @assert(meta_eval(:(begin 1+2; 2*3; 3/4 end)) == 0.75)
    @assert(meta_eval(:((a = 0; a +=1; a))) == 1)
    @assert(meta_eval(:((a = 0; a -=1; a))) == -1)
    @assert(meta_eval(:(begin println("first"); println("second"); "test" end)) == "test")
    println("<<< BLOCKS TESTED <<<")
end

function test_let()
    println(">>> TEST LET >>>")
    @assert(meta_eval(:1) == 1)
    println("*** ASSIGNMENT WITH LEXICAL SCOPE ***")
    @assert(meta_eval(:(let x = 1; x end)) == 1)
    @assert(meta_eval(:(let x = 2; x*3 end)) == 6)
    @assert(meta_eval(:(let a = 1, b = 2; let a = 3; a+b end end)) == 5)
    @assert(meta_eval(:(let a = 1
                         a + 2 end)) == 3)

    println("*** FUNCTION DEFINITION ***")
    @assert(meta_eval(:(let return_40() = 40; return_40() end)) == 40)
    @assert(meta_eval(:(let x(y) = y+1; x(1) end)) == 2)
    @assert(meta_eval(:(let x(y,z) = y+z; x(1,2) end)) == 3)
    @assert(meta_eval(:(let x = 1, y(x) = x+1; y(x+1) end)) == 3)
    @assert(meta_eval(:(let multiply_three(x, y, z) = x * y * z; multiply_three(1, 2 ,3) end)) == 6)
    @assert(meta_eval(:(let multiply_three(x, y, z) = x * y * z; multiply_three(1 + 2 ,2 +2 ,3 + 4) end)) == 84)
    @test_throws UndefVarError my_function(-1)

    println("*** Override default functions ***")
    @assert(meta_eval(:(let +() = "override of plus_default_fun"; +() end)) == "override of plus_default_fun")
    @assert(meta_eval(:(let println(a) = a + a; println(2) end)) == 4)

    println("<<< LET TESTED <<<")
end

function test_implicit_assignments()
    scope=Dict()
    println(">>> TEST IMPLICIT ASSIGNMENTS >>>")
    @assert(meta_eval(:(x = 1)) == 1)
    @assert(meta_eval(:(x = 1 + 2), scope) == 3)
    @assert(meta_eval(:(x + 2), scope) == 5)
    @assert(meta_eval(:(triple(a) = a + a + a), scope) !== nothing)
    @assert(meta_eval(:(triple(x+3)), scope)  == 18)
    @assert(metajulia_eval(:(baz = 3), scope)  == 3)
    @assert(metajulia_eval(:(let x = 0 
                                baz = 5
                                end + baz), scope)  == 8)
    @assert(meta_eval(:(let ; baz = 6 end + baz), scope)  == 9)

    println("<<< IMPLICIT ASSIGNMENTS TESTED <<<")   
end

function test_reflection()
    scope=Dict()
    println(">>> TEST OF REFLECTION >>>")
    @assert(meta_eval(:(:foo), scope) == :foo)
    @assert(meta_eval(:(:(foo + bar)), scope) == :(:(foo + bar)))
    @assert(meta_eval(:((1 + 2) * $(1 + 2)), scope) == ((1 + 2) * 3))
    println("<<< REFLECTION TESTED <<<")
end


function test_anonymous_functions()
    println("<<< TEST ASSIGNMENT OF ANONYMOUS FUNCTIONS <<<")
 
    @test meta_eval(:((() -> 5)())) == 5 
    @test meta_eval(:((x -> x + 1)(2))) == 3 
    @test meta_eval(:(((x, y) -> x + y)(1, 2))) == 3 
    @test meta_eval(:(((x, y, z) -> x + y + z)(1, 2, 3))) == 6 
    
    @test meta_eval(:(sum((() -> 1)(), 2, 3))) == 6 
    @test meta_eval(:(sum(((x) -> x + 1)(1), 2, 3))) == 7 
    @test meta_eval(:(sum(((x, y) -> x + y + 1)(1, 2), 2, 3))) == 9 
    @test meta_eval(:(sum(((x, y, z) -> x + y + z + 1)(1, 2, 3), 2, 3))) == 12 

    @test meta_eval(:(sum(x -> x*x, 1, 10))) == 385 broken=true

    @test meta_eval(:(incr =
    let priv_counter = 0
    () -> priv_counter = priv_counter + 1
    end)) == 385 skip=true #call inc then 3 times
   
    println("<<< ASSIGNMENT OF ANONYMOUS FUNCTIONS TESTED <<<")
end

function test_fexpr()
    scope=Dict()
    println(">>> TEST OF FEXPR >>>")
    @assert(meta_eval(:(identity_function(x) = x), scope) !== nothing)
    @assert(meta_eval(:(identity_function(1+2)), scope)  == 3)
    @assert(meta_eval(:(identity_fexpr(x) := x), scope) !== nothing)
    @assert(meta_eval(:(identity_fexpr(1+2)), scope)  == :(1 + 2))
    @assert(meta_eval(:(identity_fexpr(1+2) == :(1+2)), scope) == true) # TODO I dont  understand, they print the same result...
    println("<<< FEXPR TESTED <<<")
end

function test_special_functions() 
    scope=Dict()
    println(">>> TEST SPECIAL FUNCTIONS >>>")

    println("*** RECURSIVE FUNCTIONS ***")
    @assert(meta_eval(:(factorial(n) = n == 0 ? 1 : n * factorial(n - 1)), scope) !== nothing)
    @assert(meta_eval(:(factorial(5)), scope) == 120)
    @assert(meta_eval(:(fibonacci(n) = n <= 1 ? n : fibonacci(n - 1) + fibonacci(n - 2)), scope) !== nothing)
    @assert(meta_eval(:(fibonacci(6)), scope) == 8)

    println("*** HIGHER ORDER FUNCTIONS ***")
    @assert(meta_eval(:(sum(f, a, b) = 
                                    a > b ?
                                        0 :
                                        f(a) + sum(f, a + 1, b)), scope) !== nothing)
    meta_eval(:(triple(a) = a + a + a), scope)
    @assert(meta_eval(:(sum(triple, 1, 10)),scope) == 165)
    @assert(meta_eval(:(square(a) = a * a), scope) !== nothing)
    @assert(meta_eval(:(sum(square, 1, 5)), scope) == 55)
    @assert(meta_eval(:(product(a, b) = a * b), scope) !== nothing)
    @assert(meta_eval(:(sum(product, 1, 5)), scope) == 75)
    println("<<< SPECIAL FUNCTIONS TESTED <<<")
end
