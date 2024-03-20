using Test
include("meta_circular_evaluator.jl")

@testset "Higher Order Functions" begin

    my_scope = Dict()
    meta_eval(:(call(f) = f),my_scope)
    @test haskey(my_scope, :call)
    meta_eval(:(p() = "Test"),my_scope)
    @test haskey(my_scope, :p)
    @test meta_eval(:(call(p())),my_scope) == "Test"

    meta_eval(:(add(x, y) = x + y),my_scope)
    @test meta_eval(:(call(add(2 ,3))),my_scope) == 5

    meta_eval(:(one = 1),my_scope)
    @test meta_eval(:(one),my_scope) == 1
    meta_eval(:(three = 3),my_scope)
    @test meta_eval(:(three),my_scope) == 3 
  # @test meta_eval(:(call(add(one ,three))),my_scope) == 4


end

