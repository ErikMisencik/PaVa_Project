include("testing.jl")
include("default_fun.jl")
include("default_sym.jl")

debug = false

global scope_stack=[Dict{Symbol, Any}()]

function metajulia_repl()
    push_scope()
    while true
        print(">> ")
        result = ""
        input = ""
        while true
            input = input * "\n" * readline()
            result = Meta.parse(input, 1; greedy=true, raise=false)
            if result[1].head != :incomplete
                break
            end
        end
        println(metajulia_eval(result[1]))
    end
end

function metajulia_eval(exp, scope)
    global scope_stack = scope
    return metajulia_eval(exp)
end

"""
Could lead to very interesting use cases. If we are able to read julia code as string we could expose an api that takes julia code as input and we can process
this with our meta evaluator.
"""
function meta_eval_string(input_string)
    #cast string to expression
    expr = Meta.parse(input_string)
    metajulia_eval(expr)
end

function metajulia_eval(exp)
    if (debug)
        println(typeof(exp))
        println(exp)
        println("Current scope: ", scope_stack[end])
    end
    if is_expression(exp)
        return eval_exp(exp)
    elseif is_symbol(exp)
        return return_var(exp)
    elseif is_quote(exp)
        return eval_quote(exp)
    else
        return exp
    end
end

function eval_quote(quote_exp)
    if is_expression(quote_exp) && quote_exp.head == :$
        # Evaluate the interpolated expression
        return metajulia_eval(quote_exp.args[1])
    end

    if is_quote(quote_exp)
        # Return the value of the QuoteNode as is
        return quote_exp.value
    else
        return quote_exp.args[1]
    end
    
    ############### START ADDED FOR MACRO ##############
    if is_expression(quote_exp) && quote_exp.head == :quote
        if is_macro_expansion(quote_exp)
            # Evaluate the content of the quote if it's part of a macro expansion
            return metajulia_eval(quote_exp.args[1])
        else
            return quote_exp
        end
    end
    ############### END OF ADDED FOR MACRO ##############
end

function return_var(name)
    if haskey(scope_stack[end], name)
        return scope_stack[end][name]
    else
        return name
    end
end

function eval_exp(exp)

    ############### START ADDED FOR MACRO ##############
    # First check if it's a macro call or definition
    macro_type = is_macro_expansion(exp)
    if macro_type == :macro_def
        return define_macro(exp)
    elseif macro_type == :macro
        return eval_macro(exp)
    end
    ############### END OF ADDED FOR MACRO ##############
 
    if exp.head == :quote
        eval_quote(exp)  # Handle quoted expressions
    elseif exp.head != :call
        eval_operator(exp)
    else
        eval_call(exp)
    end
end

function eval_operator(operator_exp)
    if haskey(default_sym_dict, operator_exp.head)
        # the dict defines basic operation they can be retrieved by the value 
        return default_sym_dict[operator_exp.head](operator_exp)
    end
    throw(UndefVarError(operator_exp.head))
end

# First the scope is checked for a name reference. This allows to override default fun. 
function eval_call(call)
    fun = call.args[1]
    if is_anonymous_call(call)
        if (length(call.args) <= 1)  # no args
            return metajulia_eval(fun.args[2])
        end
        return eval_anonymous_call(metajulia_eval(call.args[1]), call.args[2:end])
    elseif is_fun_defined(fun)
        return eval_fun_call(call.args)
    elseif is_default_fun_defined(fun)
        # the dict defines basic operation they can be retrieved by the value 
        return default_fun_dict[fun](call)
    elseif typeof(scope_stack[end][call.args[1]]) == fexpr
        return eval_fexpr_call(call.args)
    elseif haskey(scope_stack[end], fun)   #call of a non defined function
        return eval_fun_call(call.args)    
    end
    throw(UndefVarError(fun))
end

struct Anonymous_Fun
    input_params::Any
    body::Any # can be expression or return value
end

function eval_anonymous_call(anon_fun, var_values)
    add_scope()
    input = to_tuple(anon_fun.input_params)
    values = to_tuple(var_values)
    inner_scope = Dict(zip(input, values))
    result = metajulia_eval(anon_fun.body)
    remove_scope()
    return result
end

function is_anonymous_call(call)
    if typeof(call.args[1]) == Expr
        if call.args[1].head == :->
            return true
        end
    end
    return false
end

function is_default_fun_defined(fun_name)
    return haskey(default_fun_dict, fun_name)
end

function assign_var(var_name, var_value_exp) # maybe in a later point of the project the var_name should also be evaluated
    var_value = metajulia_eval(var_value_exp)
    set_variable(var_name, var_value) # Update scope
    return var_value
end

function eval_let(let_exp_args)
    add_scope()  # Add a new scope for let expression
    let_exp_init = let_exp_args[1]
    let_exp_body = let_exp_args[2:end]
    result = nothing

    if is_assignment(let_exp_init)   # if init only has 1 assignment
        eval_let_defs(let_exp_init)
    else
        for exp in let_exp_init.args
            if (length(exp.args) > 1) && is_assignment(exp)   # if init is not empty
                eval_let_defs(exp)
            end
        end
    end

    for exp in let_exp_body
        if length(exp.args) > 1    # if body is not empty expression
            if is_assignment(exp)
                eval_let_defs(exp)
            else
                result = metajulia_eval(exp)  # Use updated local_scope
            end
        end
    end
    remove_scope()
    return result
end

function eval_let_defs(exp)
    var_name = exp.args[1]
    var_value_exp = exp.args[2]
    if is_expression(var_name)
        assign_fun(var_name, var_value_exp)   # Function Definition
    else
        assign_var(var_name, var_value_exp)
    end
end

struct Fun_Def
    input_params::Any
    body::Any
end   
Base.show(io::IOBuffer, f::Fun_Def) = print(io, "<function>")

function assign_fun(function_decl, function_exp)
    # Extract function parameters and body
    name = function_decl.args[1]
    params = function_decl.args[2:end]
    body = function_exp.args[end]

    params = to_tuple(params)     # Put param in tuple if singular one param
    fun_dev = Fun_Def(params, body)
    set_variable(name, fun_dev) # Update scope
end 

struct UserFunction # System does not allow to use the name Function
    body::Any
    local_scope::Dict
end

function userFunction(fun_call_exp_args)
    fun_name = fun_call_exp_args[1]
    param_values = map(x -> metajulia_eval(x), fun_call_exp_args[2:end])
    fun_def = get_variable(fun_name)

    if typeof(fun_def) == Fun_Def   # defined function
        local_scope = Dict(zip(fun_def.input_params, param_values))
        body = fun_def.body
    elseif typeof(fun_def) == Anonymous_Fun # non defined function
        input_params = to_tuple(fun_def.input_params)
        local_scope = Dict(zip(input_params, param_values))
        body = fun_def.body
    else    # non params function
        local_scope = Dict()
        body = fun_def
    end
    merge!(scope_stack[end], local_scope)   # add local scope to current env
    return UserFunction(body, local_scope)
end

function eval_fun_call(fun_call_exp_args)
    add_scope()
    fun = userFunction(fun_call_exp_args)
    result = metajulia_eval(fun.body)
    remove_scope()
    return result
end

function is_fun_defined(fun_name)
    return (get_variable(fun_name) != false) && typeof(get_variable(fun_name)) == Fun_Def
end

function eval_global(global_exp_args)
    name = global_exp_args.args[1].args[1]
    value =  metajulia_eval(global_exp_args.args[2])

    if haskey(scope_stack[1], name)
        # Update the existing variable in the global scope
        set_variable(name, value)
    else
        # Create a new variable in the global scope
        scope_stack[1][name] = value
    end
end

function eval_if(if_exp_args)
    args_length = length(if_exp_args)
    i = 1
    # if_exp_args[] is the part of the if exp that decides if args[2] or [3] should be returned
    while i < args_length
        if metajulia_eval(if_exp_args[i]) # if_exp_args[i] is the boolean expression
            return metajulia_eval(if_exp_args[i + 1]) # if_exp_args[i + 1] is the value to return
        else
            i += 2
        end
    end
    return metajulia_eval(if_exp_args[end])
end

function eval_block(block_args)
    args_length = length(block_args)     #block_args represent the instructions inside the block body
    i = 1     #in julia arrays start at 1
    while i < args_length
        metajulia_eval(block_args[i])
        i += 1
    end
    return metajulia_eval(block_args[i])
end

function is_expression(var)
    return isa(var, Expr)
end

function is_quote(quote_node)
    return isa(quote_node, QuoteNode)
end

function is_assignment(exp)
     return exp.head == :(=)
end

function is_symbol(var)
    return isa(var, Symbol)
end

# to faciliate dict zip
function to_tuple(var)
    if is_symbol(var) 
        return (var,)
    elseif is_expression(var)
        return var.args
    else
        return var
    end
end

function eval_assignment(operator_exp)

    if is_expression(operator_exp.args[2])
        #define_fun(operator_exp, scope)
    end

    # if call is a function definition
    if is_expression(operator_exp.args[1]) 
        return assign_fun(operator_exp.args[1], operator_exp.args[2])
    else
        return assign_var(operator_exp.args[1], operator_exp.args[2])
    end
end

struct fexpr
    params
    body
end
Base.show(io::IOBuffer, f::fexpr) = print(io, "<fexpr>")

function eval_fexpr_def(function_decl)
    # Extract function parameters and body
    name = function_decl.args[1].args[1]
    params = function_decl.args[1].args[2:end]
    body = function_decl.args[end]

    function_object = fexpr( params, body)  # Create a function object
    set_variable(name, function_object) # Update scope
end
	
function eval_fexpr_call(fun_call_exp_args)
    fun_name = fun_call_exp_args[1]
    param_values = deepcopy(fun_call_exp_args[2:end])  

    fexpr_object = get_variable(fun_name)
    params = fexpr_object.params
    body = fexpr_object.body

    # Create a local scope for the fexpr call
    local_scope = Dict(zip(params, param_values))
    merge!(scope_stack[end], local_scope)   # add local scope to current env
    result = metajulia_eval(body)
    return result
end

 ############### START ADDED FOR MACRO ##############
 
struct MacroDef
    name::String
    params::Vector{Symbol}
    body::Expr
end

function define_macro(exp,)
    macro_name, macro_params, macro_body = string(exp.args[1].args[1]), exp.args[1].args[2:end], exp.args[2]
    set_variable(macro_name) = MacroDef(macro_name, macro_params, macro_body)
end


function eval_macro(exp)

    macro_def = get_variable(string(exp.args[1]))
    macro_body = macro_def.body
    macro_args = exp.args[2:end]
    macro_body = foldl((body, pair) -> replace_expr(body, Expr(:$, pair[1]), pair[2]), zip(macro_def.params, macro_args), init = macro_body)
    metajulia_eval(macro_body.args[1])
end

function is_macro_expansion(exp)
    if isa(exp, Expr) && exp.head == :call
        return haskey(scope_stack[end], string(exp.args[1])) ? :macro : false
    elseif isa(exp, Expr) && exp.head == :$=
        return :macro_def
    end
    return false
end

function replace_expr(expr, to_replace, replacement)
    if expr == to_replace
        return replacement
    elseif isa(expr, Expr)
        return Expr(expr.head, map(arg -> replace_expr(arg, to_replace, replacement), expr.args)...)
    else
        return expr
    end
end
 ############### END OF ADDED FOR MACRO #############


function add_scope()
    new_scope = deepcopy(scope_stack[end])
    push!(scope_stack, new_scope)
end

function remove_scope()
    if length(scope_stack) > 1
        return pop!(scope_stack)
    else
        println("Error: Cannot remove the first element.")
    end
end

# Function to set a variable in the current scope
function set_variable(name::Symbol, value)
    scope_stack[end][name] = value
end

# Function to get the value of a variable from the scopes
function get_variable(name::Symbol)
    for frame in reverse(scope_stack)
        if haskey(frame, name)
            return frame[name]
        end
    end
    return false
end

"""
 metajulia_eval(:(
    begin
        incr = let priv_counter = 0
            () -> priv_counter = priv_counter + 1
        end
    end
))
println(metajulia_eval(:(incr()))) """

try
#println(metajulia_eval(:((x -> x + 1)(2))))
println(metajulia_eval(:(
    begin
        let secret = 1234
            global show_secret() = secret
        end
        show_secret()
    end)))
catch e
    println(e)
end
