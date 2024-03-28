include("testing.jl")
include("default_fun.jl")
include("default_sym.jl")

function metajulia_repl()
    scope=[Dict{Symbol, Any}()]
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
        println(metajulia_eval(result[1], scope))
    end
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

function metajulia_eval(exp, scope=[Dict{Symbol, Any}()])
    if is_expression(exp)
        return eval_exp(exp, scope)
    elseif is_symbol(exp)
        return get_variable(scope,exp)
    elseif is_quoteNode(exp)
        return eval_quote(exp, scope)
    else
        return exp
    end
end

has_dollar_sign(args...) = any(contains(string(arg), '$') for arg in args)

function eval_dollar(quote_exp, scope)
    if has_dollar_sign(quote_exp)
        if is_expression(quote_exp) && quote_exp.head == :$
            quote_exp = metajulia_eval(quote_exp.args[1], scope)
        else
            quote_exp.args = [eval_dollar(arg, scope) for arg in quote_exp.args]
        end
        return eval_dollar(quote_exp, scope)  # Recursively evaluate remaining parts
    end
    return quote_exp
end

function eval_quote(quote_exp, scope)

    if is_expression(quote_exp) && has_dollar_sign(quote_exp.args...)
        return metajulia_eval(eval_dollar(quote_exp, scope), scope)
    end

    if is_quoteNode(quote_exp)
        # Return the value of the QuoteNode as is
        return quote_exp.value
    else
        return quote_exp.args[1]
    end
    
    # ############### THIS IS NOT WORKING FOR MACRO ##############
    # if is_expression(quote_exp) && quote_exp.head == :quote
    #     if is_macro_expansion(quote_exp, scope)
    #         # Evaluate the content of the quote if it's part of a macro expansion
    #         return metajulia_eval(quote_exp.args[1], scope)
    #     else
    #         return quote_exp
    #     end
    # end
    # ############### THIS IS NOT WORKING FOR MACRO ##############
end

function eval_exp(exp, scope)
#=
    # First check if it's a macro call or definition
    result = process_macro(exp, scope)
    if is_defined(result)
        return result
    end =#
    if is_quote(exp)
        eval_quote(exp, scope)  # Handle quoted expressions
    elseif !is_call(exp)
        eval_operator(exp, scope)
    else
        eval_call(exp, scope)
    end
end

function eval_operator(operator_exp, scope)
    if operator_exp.head == :$= 
        # the dict defines basic operation they can be retrieved by the value 
        return define_macro(operator_exp, scope)
    end
    if haskey(default_sym_dict, operator_exp.head)
        # the dict defines basic operation they can be retrieved by the value
        return default_sym_dict[operator_exp.head](operator_exp, scope)
    end
    throw(UndefVarError(operator_exp.head))
end

# First the scope is checked for a name reference. This allows to override default fun. 
function eval_call(call, scope)
    args = call.args
    fun = args[1]
    var = is_symbol(fun) ? get_variable(scope, fun) : nothing

    if is_anonymous_call(call)
        if (length(args) <= 1)  # no args
            return metajulia_eval(fun.args[2], scope)
        end
        return eval_anonymous_call(metajulia_eval(fun), args[2:end], scope) 

    elseif is_fun_defined(fun, scope)
        return eval_fun_call(args, scope)

    elseif is_default_fun_defined(fun)
        return default_fun_dict[fun](call, scope)   # the dict defines basic operation they can be retrieved by the value 

    elseif is_defined(var)
        if is_fexpr(var)
            return eval_fexpr_call(args, scope)
        else
            return eval_fun_call(args, scope) 
        end   
    end
    throw(UndefVarError(fun))
end

function is_defined(var)
    return var != false
end

struct Anonymous_Fun
    input_params::Any
    body::Any
end

function Base.show(io::IO, f::Anonymous_Fun) 
    print(io, "<function>") 
end

function eval_anonymous_call(fun, params, scope)

    inner_scope = Dict(zip(to_tuple(fun.input_params), params))
    update_scope(scope, inner_scope)
    result = metajulia_eval(fun.body, scope)
    
    return result
end

function get_lambda_input_params(fun)
    return to_tuple(fun.input_params)
end

function get_lambda_body(exp)
    return exp[1]
end

function is_anonymous_call(call)
    return (is_expression(call.args[1]) && (call.args[1].head == :->)) || is_lambda(exp)
end

function is_default_fun_defined(fun_name)
    return haskey(default_fun_dict, fun_name)
end

function var_def(var_name, var_value_exp, scope) 
    var_value = metajulia_eval(var_value_exp, scope)
    set_variable(scope, var_name, var_value) # Update scope
    return var_value
end

function eval_let(let_exp_args, scope)
    add_scope(scope)  # Add a new scope for let expression
    let_exp_init = let_exp_args[1]
    let_exp_body = let_exp_args[2:end]
    result = nothing
    
    inner_scope = get_let_scope(let_exp_init, scope)

    update_scope(scope, inner_scope)

    for exp in let_exp_body
        if length(exp.args) > 1    # if body is not empty expression
            result = metajulia_eval(exp, scope)
        end
    end

    scope = remove_scope(scope)
    return result
end

function get_let_scope(let_exp_init, scope)
    inner_scope = Dict()

    if is_assignment(let_exp_init)   # if init only has 1 assignment
        eval_let_defs(inner_scope, let_exp_init, scope)
    else
        for exp in let_exp_init.args
            if (length(exp.args) > 1) && is_assignment(exp)   # if init is not empty
                eval_let_defs(inner_scope, exp, scope)
            end
        end
    end
    return inner_scope
end

function eval_let_defs(inner_scope, exp, scope)
    add_scope(scope)
    var_name = get_name(exp)
    var = metajulia_eval(exp, scope)
    inner_scope[var_name] = var
    remove_scope(scope)
end

struct Fun_Def
    inner_scope::Dict
    input_params::Any
    body::Any
end   

function Base.show(io::IO, f::Fun_Def) 
    print(io, "<function>") 
end

function fun_def(function_decl, function_exp, scope)
    # Extract function parameters and body
    name = get_name(function_decl)
    inner_scope = Dict()
    params = ()

    if (function_exp.head == :let)
        inner_scope = get_let_scope(function_exp.args[1],scope)
    else
        inner_scope = scope[end]
        params = get_fun_def_params(function_decl)
    end

    body = get_fun_def_body(function_exp)
    fun_dev = Fun_Def(inner_scope, params, body)
    set_variable(scope, name, fun_dev) # Update scope
    return fun_dev
end 

function get_fun_def_params(function_decl)
    params = function_decl.args[2:end]
    params = to_tuple(params)     # Put param in tuple if singular one param
    return params
end

function get_fun_def_body(function_exp)
    return function_exp.args[end]
end

struct UserFunction # System does not allow to use the name Function
    body::Any
    fun_scope::Dict
end

function userFunction(fun_call_exp_args, scope)
    fun_name = fun_call_exp_args[1]
    param_values = map(x -> metajulia_eval(x, scope), fun_call_exp_args[2:end])
    fun_def = get_variable(scope, fun_name) 
    
    if is_fdef(fun_def)   # defined function
        local_scope = Dict(zip(fun_def.input_params, param_values))
        body = fun_def.body
    elseif is_lambda(fun_def) # non defined function
        input_params = get_lambda_input_params(fun_def)
        local_scope = Dict(zip(input_params, param_values))
        body = fun_def.body
    else    # non params function
        local_scope = Dict()
        body = fun_def
    end
    return UserFunction(body, local_scope)
end

function eval_fun_call(fun_call_exp_args, scope)
    add_scope(scope)
    fun_name = fun_call_exp_args[1]
    def = get_variable(scope, fun_name)

    if is_fdef(def) && !isempty(def.inner_scope)
        update_scope(scope, def.inner_scope)
    end

    fun = userFunction(fun_call_exp_args, scope)    # eval given env and params
    update_scope(scope, fun.fun_scope)
    
    result = metajulia_eval(fun.body, scope)
    if is_lambda(result)
        result = eval_anonymous_call(result,() ,scope)
    end
    if is_fdef(def)
        new_def = Fun_Def(scope[end], def.input_params, def.body)
        update_variable(scope,fun_name,new_def)
    end
    remove_scope(scope)
    return result
end

function is_fun_defined(fun_name, scope)
    var = get_variable(scope, fun_name)
    return is_defined(var) && is_fdef(var)
end

function eval_global(global_exp_args, scope)
    name = get_name(global_exp_args)
    result = metajulia_eval(global_exp_args, scope)
    set_global_variable(scope,name,result)    # Create or update a new variable in the global scope
    return result
end

function get_name(exp)
    if is_expression(exp)
        get_name(exp.args[1])
    else
        return exp
    end
end

function eval_if(if_exp_args, scope)
    args_length = length(if_exp_args)
    i = 1
    # if_exp_args[] is the part of the if exp that decides if args[2] or [3] should be returned
    while i < args_length
        if metajulia_eval(if_exp_args[i], scope) # if_exp_args[i] is the boolean expression
            return metajulia_eval(if_exp_args[i + 1], scope) # if_exp_args[i + 1] is the value to return
        else
            i += 2
        end
    end
    return metajulia_eval(if_exp_args[end], scope)
end

function eval_block(block_args, scope)
    args_length = length(block_args)     #block_args represent the instructions inside the block body
    i = 1     #in julia arrays start at 1
    while i < args_length
        metajulia_eval(block_args[i], scope)
        i += 1
    end
    return metajulia_eval(block_args[i], scope)
end

function is_expression(var)
    return isa(var, Expr)
end

function is_quoteNode(quote_node)
    return isa(quote_node, QuoteNode)
end
function is_quote(exp)
    return exp.head == :quote
end

function is_assignment(exp)
    return exp.head == :(=)
end

function is_symbol(var)
    return isa(var, Symbol)
end

function is_fdef(exp)
    return isa(exp, Fun_Def)
end

function is_lambda(exp)
    return isa(exp, Anonymous_Fun)
end

function is_call(exp)
    return exp.head == :call
end

function is_fexpr(exp)
    return isa(exp, fexpr)
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

function eval_assignment(operator_exp, scope)
    var_decl= operator_exp.args[1]
    var_value = operator_exp.args[2]
    # if call is a function definition
    if is_expression(var_decl) || (is_expression(var_value) && var_value.head == :let)
        return fun_def(var_decl, var_value, scope)
    else
        return var_def(var_decl, var_value, scope)
    end
end

function eval_lambda(operator_exp, scope)
    var_decl= operator_exp.args[1]
    var_value = operator_exp.args[2]
    return Anonymous_Fun(var_decl, var_value)
end

struct fexpr
    params
    body
end

function Base.show(io::IO, f::fexpr) 
    print(io, "<fexpr>") 
end

function eval_fexpr_def(function_decl, scope)
    # Extract function parameters and body
    name = function_decl.args[1].args[1]
    params = function_decl.args[1].args[2:end]
    body = function_decl.args[end]

    function_object = fexpr( params, body)  # Create a function object
    set_variable(scope, name, function_object) # Update scope
end
	
function eval_fexpr_call(fun_call_exp_args, scope)
    add_scope(scope)
    fun_name = fun_call_exp_args[1]
    param_values = deepcopy(fun_call_exp_args[2:end])  

    fexpr_object = get_variable(scope, fun_name)
    params = fexpr_object.params
    body = fexpr_object.body

    # Create a local scope for the fexpr call
    local_scope = Dict(zip(params, param_values))
    update_scope(scope, local_scope)   # add local scope to current env
    result = metajulia_eval(body, scope)
    #remove_scope(scope)
    return result
end

 ############### START ADDED FOR MACRO ##############
 
struct MacroDef
    name::String
    params::Vector{Symbol}
    body::Expr
end
Base.show(io::IOBuffer, f::MacroDef) = print(io, "<macro>")

function define_macro(exp, scope)
    macro_name, macro_params, macro_body = exp.args[1].args[1], exp.args[1].args[2:end], exp.args[2]
    set_variable(scope, macro_name, MacroDef(string(macro_name), macro_params, macro_body))
end

function eval_macro(exp, scope)
    #add_scope(scope)
    macro_def = get_variable(scope, exp.args[1])
    macro_body = macro_def.body
    macro_args = exp.args[2:end]
    macro_body = foldl((body, pair) -> replace_expr(body, Expr(:$, pair[1]), pair[2]), zip(macro_def.params, macro_args), init = macro_body)
    #remove_scope(scope)
    metajulia_eval(macro_body.args[1], scope)
end

function is_macro_expansion(exp, scope)
    if is_expression(exp)
        if is_call(exp)
            return haskey(scope[end], exp.args[1]) ? :macro : false
        elseif exp.head == :$=
            return :macro_def
        end
    end
    return false
end

function replace_expr(expr, to_replace, replacement)
    if expr == to_replace
        return replacement
    elseif  is_expression(expr)
        return Expr(expr.head, map(arg -> replace_expr(arg, to_replace, replacement), expr.args)...)
    else
        return expr
    end
end

function process_macro(exp, scope)
    # Check if it's a macro call or definition
    macro_type = is_macro_expansion(exp, scope)
    if macro_type == :macro_def
        define_macro(exp, scope)
    elseif macro_type == :macro
        eval_macro(exp, scope)
    else
        return false
    end
end
 ############### END OF ADDED FOR MACRO ##############


function add_scope(scope)
    new_scope = deepcopy(scope[end])
    push!(scope, new_scope)
    return scope
end

function update_scope(scope, new_scope_values)
    merge!(scope[end], new_scope_values)
    return scope
end

function remove_scope(scope)
    if length(scope) > 1
        return pop!(scope)
    else
        println("Error: Cannot remove the first element.")
    end
end

# Function to set a variable in the current scope
function set_variable(scope, name::Symbol, value)
    scope[end][name] = value
end

function set_global_variable(scope, name::Symbol, value)
    scope[1][name] = value
end

# Function to get the value of a variable from the scopes
function get_variable(scope, name::Symbol)
    for frame in reverse(scope)
        if haskey(frame, name)
            return frame[name]
        end
    end
    return false
end

function update_variable(scope, name::Symbol, value)
    for frame in scope
        if haskey(frame, name)
            frame[name] = value
        end
    end
end
