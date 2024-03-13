function test_project()
    println("--- START TESTS ---")
    test_basic_math_operators()
    test_comparison_operators()
    test_different_bool_syntax()
    test_blocks()
    test_let()
    println("--- TESTS PERFORMED ---")
end

function test_basic_math_operators()
    println(">>> TEST BASIC MATH OPERATORS >>>")
    @assert(meta_eval(:1) == 1)
    @assert(meta_eval(:"Hello, world!") == "Hello, world!")
    @assert(meta_eval(:(1 + 2)) == 3)
    @assert(meta_eval(:((1 + 2) + (1 + 2))) == 6)
    @assert(meta_eval(:((2 + 3) * (4 + 5))) == 45)

    println("*** DIVISION ***")
    @assert(meta_eval(:((2 + 3) / (5))) == 1)
    @assert(meta_eval(:(14 / 7)) == 2)
    # Division of floating point numbers does not work right now
    # @assert(meta_eval(:((3.0 - 6) /2)) == -1.5)
    @assert(meta_eval(:(-14/7)) == -2)
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

function test_blocks()
    println(">>> TEST BLOCKS >>>")
    @assert(meta_eval(:(1+2; 2*3; 3/4)) == 0.75)
    @assert(meta_eval(:(begin 1+2; 2*3; 3/4 end)) == 0.75)
    @assert(meta_eval(:((a = 0; a +=1; a))) == 1)
    @assert(meta_eval(:((a = 0; a -=1; a))) == -1)
    #should evaluate right if println is implemented
    #@assert(meta_eval(:(begin println("first"); println("second"); "test" end)) == "test")
    println("<<< BLOCKS TESTED <<<")
end

function test_let()
    println(">>> TEST LET >>>")

    println("*** ASSIGNMENT WITH LEXICAL SCOPE ***")
    @assert(meta_eval(:(let x = 1; x end)) == 1)
    @assert(meta_eval(:(let x = 2; x*3 end)) == 6)
    @assert(meta_eval(:(let a = 1, b = 2; let a = 3; a+b end end)) == 5)
    @assert(meta_eval(:(let a = 1; a + 2 end)) == 3)

    println("*** FUNCTION DEFINITION ***")
    @assert(meta_eval(:(let x(y) = y+1; x(1) end)) == 2)
    @assert(meta_eval(:(let x(y,z) = y+z; x(1,2) end)) == 3)
    #@assert(meta_eval(:(let x = 1, y(x) = x+1; y(x+1) end)) == 3)

    println("<<< LET TESTED <<<")
end