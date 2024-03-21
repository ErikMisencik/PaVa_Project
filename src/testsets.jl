using Test
include("meta_circular_evaluator.jl")
include("testing.jl")

@testset "Higher Order Functions" begin

    my_scope = Dict() #use this scope over all children testsets

    @testset "Basic Higher Order Functions" begin
        meta_eval(:(call(f) = f), my_scope)
        @test haskey(my_scope, :call)
        meta_eval(:(p() = "Test"), my_scope)
        @test haskey(my_scope, :p)
        @test meta_eval(:(call(p())), my_scope) == "Test"

        meta_eval(:(add(x, y) = x + y), my_scope)
        @test meta_eval(:(call(add(2, 3))), my_scope) == 5

        meta_eval(:(double(a) = a + a), my_scope)
        meta_eval(:(sum_double(f, a) = f(a)), my_scope)
        @test meta_eval(:(sum_double(double, 1)), my_scope) == 2
    end

    @testset "Use Variables as Input" begin
        meta_eval(:(one = 1), my_scope)
        @test meta_eval(:(one), my_scope) == 1
        meta_eval(:(three = 3), my_scope)
        @test meta_eval(:(three), my_scope) == 3
        @test meta_eval(:(call(add(one, three))), my_scope) == 4
    end

    @testset "Function from project description" begin
        meta_eval(:(triple(a) = a + a + a), my_scope)
        meta_eval(:(sum(f, a, b) = a > b ? 0 : f(a) + sum(f, a + 1, b)), my_scope)
        @test meta_eval(:(sum(triple, 1, 10)), my_scope) == 165
    end
end

@testset "Test Project" begin
    test_project()
end

@testset "Override default fun" begin
    my_scope = Dict()
    @test meta_eval(:(sum(1)), my_scope) == 1
    meta_eval(:(sum() = "test"), my_scope)
    @test meta_eval(:(sum()), my_scope) == "test"
    meta_eval(:(sum(x) = x * x), my_scope)
    @test meta_eval(:(sum(4)), my_scope) == 16
    @test meta_eval(:(let +() = "override of plus_default_fun"; +() end)) == "override of plus_default_fun"
    @test meta_eval(:(let println(a) = a + a; println(2) end)) == 4
end