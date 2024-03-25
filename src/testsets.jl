using Test
include("meta_circular_evaluator.jl")
include("testing.jl")

@testset "Test Julia Meta Circular Evaluator" begin

    @testset "Higher Order Functions" begin

        my_scope = Dict() #use this scope over all children testsets

        @testset "Basic Higher Order Functions" begin
            metajulia_eval(:(call(f) = f), my_scope)
            @test haskey(my_scope, :call)
            metajulia_eval(:(p() = "Test"), my_scope)
            @test haskey(my_scope, :p)
            @test metajulia_eval(:(call(p())), my_scope) == "Test"

            metajulia_eval(:(add(x, y) = x + y), my_scope)
            @test metajulia_eval(:(call(add(2, 3))), my_scope) == 5

            metajulia_eval(:(double(a) = a + a), my_scope)
            metajulia_eval(:(sum_double(f, a) = f(a)), my_scope)
            @test metajulia_eval(:(sum_double(double, 1)), my_scope) == 2
        end

        @testset "Use Variables as Input" begin
            metajulia_eval(:(one = 1), my_scope)
            @test metajulia_eval(:(one), my_scope) == 1
            metajulia_eval(:(three = 3), my_scope)
            @test metajulia_eval(:(three), my_scope) == 3
            @test metajulia_eval(:(call(add(one, three))), my_scope) == 4
        end

        @testset "Return functions" begin
            my_scope = Dict()
            metajulia_eval(:(function1(x) = x + 1), my_scope)
            metajulia_eval(:(function2(x) = x * 2), my_scope)
            metajulia_eval(:(choose_function(input) = input == 1 ? function1 : function2), my_scope)
            metajulia_eval(:(a = choose_function(1)), my_scope)
            @test metajulia_eval(:((a(3))), my_scope) == 4
            metajulia_eval(:(a = choose_function(2)), my_scope)
            @test metajulia_eval(:(a(3)), my_scope) == 6
        end

        @testset "Function from project description" begin
            metajulia_eval(:(triple(a) = a + a + a), my_scope)
            metajulia_eval(:(sum(f, a, b) = a > b ? 0 : f(a) + sum(f, a + 1, b)), my_scope)
            @test metajulia_eval(:(sum(triple, 1, 10)), my_scope) == 165
        end
    end

    @testset "Test Project" begin
        test_project()
    end

    @testset "Override default fun" begin
        my_scope = Dict()
        @test metajulia_eval(:(sum(1)), my_scope) == 1
        metajulia_eval(:(sum() = "test"), my_scope)
        @test metajulia_eval(:(sum()), my_scope) == "test"
        metajulia_eval(:(sum(x) = x * x), my_scope)
        @test metajulia_eval(:(sum(4)), my_scope) == 16
        @test metajulia_eval(:(
            let +() = "override of plus_default_fun"
                +()
            end
        )) == "override of plus_default_fun"
        @test metajulia_eval(:(
            let println(a) = a + a
                println(2)
            end
        )) == 4
    end

    @testset "Define Functions" begin

        @testset "Define Functions using let" begin
            @test metajulia_eval(:(
                let return_40() = 40
                    return_40()
                end
            )) == 40
            @test metajulia_eval(:(
                let x(y) = y + 1
                    x(1)
                end
            )) == 2
            @test metajulia_eval(:(
                let x(y, z) = y + z
                    x(1, 2)
                end
            )) == 3
            @test metajulia_eval(:(
                let x = 1, y(x) = x + 1
                    y(x + 1)
                end
            )) == 3
            @test metajulia_eval(:(
                let multiply_three(x, y, z) = x * y * z
                    multiply_three(1, 2, 3)
                end
            )) == 6
            @test metajulia_eval(:(
                let multiply_three(x, y, z) = x * y * z
                    multiply_three(1 + 2, 2 + 2, 3 + 4)
                end
            )) == 84
            @test_throws UndefVarError my_function(-1)
        end

        @testset "Define Functions" begin
            my_scope = Dict()
            metajulia_eval(:(return_40() = 40), my_scope)
            @test metajulia_eval(:(return_40()), my_scope) == 40

            metajulia_eval(:(x(y) = y + 1), my_scope)
            @test metajulia_eval(:(x(1)), my_scope) == 2

            metajulia_eval(:(x(y, z) = y + z), my_scope)
            @test metajulia_eval(:(x(1, 2)), my_scope) == 3

            metajulia_eval(:(x = 1), my_scope)
            metajulia_eval(:(y(x) = x + 1), my_scope)
            @test metajulia_eval(:(y(x + 1)), my_scope) == 3

            metajulia_eval(:(multiply_three(x, y, z) = x * y * z), my_scope)
            @test metajulia_eval(:(multiply_three(1, 2, 3)), my_scope) == 6
            @test metajulia_eval(:(multiply_three(1 + 2, 2 + 2, 3 + 4)), my_scope) == 84
        end

    end

    @testset "ANONYMOUS FUNCTIONS" begin

        @testset "Basic Anonymous Functions" begin   
            @test metajulia_eval(:((() -> 5)())) == 5
            @test metajulia_eval(:((x -> x + 1)(2))) == 3
            @test metajulia_eval(:(((x, y) -> x + y)(1, 2))) == 3
            @test metajulia_eval(:(((x, y, z) -> x + y + z)(1, 2, 3))) == 6
        end

        @testset "Use Anonymous functions as input" begin
            @test metajulia_eval(:(sum((() -> 1)(), 2, 3))) == 6
            @test metajulia_eval(:(sum(((x) -> x + 1)(1), 2, 3))) == 7
            @test metajulia_eval(:(sum(((x, y) -> x + y + 1)(1, 2), 2, 3))) == 9
            @test metajulia_eval(:(sum(((x, y, z) -> x + y + z + 1)(1, 2, 3), 2, 3))) == 12
        end

        @testset "Use Anonymous function as function inside another function" begin
            my_scope = Dict()
            metajulia_eval(:(fun_zero(fun_exp, param) = fun_exp() + param), my_scope)
            @test metajulia_eval(:(fun_zero(() -> 6, 3)), my_scope) == 9 
            
            metajulia_eval(:(fun_one(fun_exp, param) = fun_exp(param)), my_scope)
            @test metajulia_eval(:(fun_one(x -> x + x, 3)), my_scope) == 6

            metajulia_eval(:(fun_two(fun_exp, param_one, param_two) = fun_exp(param_one, param_two)), my_scope)
            @test metajulia_eval(:(fun_two((x, y) -> x * y, 3, 5)), my_scope) == 15
        end

        @testset "Anonymous tasks from script" begin
            my_scope = Dict()
            metajulia_eval(:(sum(f, a, b) = a > b ? 0 : f(a) + sum(f, a + 1, b)), my_scope)
            @test metajulia_eval(:(sum(x -> x * x, 1, 10)), my_scope) == 385 skip=true
    
            @test metajulia_eval(:(incr = let priv_counter = 0
                    () -> priv_counter = priv_counter + 1
                end), my_scope) skip = true
            @test metajulia_eval(incr(), my_scope) == 1 skip = true
            @test metajulia_eval(incr(), my_scope) == 2 skip = true
        end
    end
end