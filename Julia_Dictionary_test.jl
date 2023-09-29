include("functions.jl")


using GlobalSensitivity, Statistics, OrdinaryDiffEq, QuasiMonteCarlo, Plots
using Interpolations
using DifferentialEquations
using ModelingToolkit
using OrdinaryDiffEq

using Distributions, Random
@variables t
D = Differential(t)

global text = "add_equation!(eqs, var1 ~ var2 * par1 * par2 * par3)
add_equation!(eqs, var2 ~ var1 + par1)"

y = (0.0, 10.0)

xranges= (0.0,10.0)

_params = Dict{Symbol,Float64}(
    :par1 => 1.0,
    :par2 => 1.0,
    :par3 => 1.0,
)
getparameters() = copy(_params)

_variables = Dict{Symbol,Float64}(
    :var1 => 1.0,
    :var2 => 2.0,
    
)
getinitialisations() = copy(_variables)

function system_perturbed(; name, v = _variables, p =_params)
    @parameters par1 = p[:par1]
    @parameters par2 = p[:par2]
    @parameters par3 = p[:par3]

    @variables var1(t) = v[:var1]
    @variables var2(t) = v[:var2]
    @variables X2(t) 
    eqs = []

    #add_equation!(eqs, D(var1) ~ -X2 * par1*par2*par3)
    #add_equation!(eqs, D(var2) ~ 1+X2 * par1*par2*par3)
    add_equation!(eqs, var1 ~ var2 * par1 * par2 * par3)
    #add_equation!(eqs, X2 ~ WorldDynamics.interpolate(t, y, xranges) )
    return ODESystem(eqs; name=name)
end



function solve(system::ODESystem, timespan; solver=AutoVern9(Rodas5()), kwargs...)
    sys = structural_simplify(system)

    prob = ODEProblem(sys, [], timespan)
    sol = ModelingToolkit.solve(prob, solver; kwargs...)

    return sol
end


function variables_index(sol)
    #A = Array(sol)
    #return [ x[1] for x in sol ]
    return sol[1]
end

function variables_index(sys)
    nsp_v = ModelingToolkit.namespace_variables(sys)
    dictionaryVariablesIndex = Dict{Any,Any}()
    dictionaryIndexVariables = Dict{Any,Any}()
    index = 0
    for i in nsp_v
        index = index +1
        dictionaryVariablesIndex[i]=index
        dictionaryIndexVariables[index]=i
        #println("riga 1 : ", dictionaryVariablesIndex[i], "  ", sol[i][1])
        #println("   ")
        #println("riga 2 : ", i, "  ", sol[i][1])
        #println("   ")
        #println("riga 3 : ", dictionaryIndexVariables[index], "  ", sol[dictionaryIndexVariables[index]][1])
    end
    return [dictionaryVariablesIndex, dictionaryIndexVariables]
end

function return_initial_condition_by_index(sol, dict, index)
    dictionaryIndexVariables = dict[2]
    return sol[dictionaryIndexVariables[index]][1]
end

function return_initial_condition_by_name(sol, arg)
    initial_condition_variable = sol[arg][1]
    return  initial_condition_variable 
end

function dict_name_and_initial_conditions(sol, sys)
    nsp_v = ModelingToolkit.namespace_variables(sys)
    dictionaryNameInitialCondition = Dict{Any,Any}()
    for i in nsp_v
        dictionaryNameInitialCondition[i] = sol[i][1]
    end
    return dictionaryNameInitialCondition
end

function variable_index_name_value(_variables)
    
    dictionaryVariablesIndex = Dict{Any,Any}()
    dictionaryIndexVariables = Dict{Any,Any}()
    dictionaryIndexValue = Dict{Any,Any}()
    index = 0
    for (k,v) in _variables
        index = index +1
        dictionaryVariablesIndex[k]=index
        dictionaryIndexVariables[index]=k
        dictionaryIndexValue[index] = v
    end
    return [dictionaryVariablesIndex, dictionaryIndexVariables, dictionaryIndexValue]
end 

function parameters_index_namespace(sys)
    nsp_p = ModelingToolkit.namespace_parameters(sys)
    dictionaryParametersIndex = Dict{Any,Any}()
    dictionaryIndexParameters = Dict{Any,Any}()
    index = 0
    for i in nsp_p
        index = index +1
        dictionaryParametersIndex[i]=index
        dictionaryIndexParameters[index]=i
    end
    return [dictionaryParametersIndex, dictionaryIndexParameters]
end


function params_index_name_value(_params)
    
    dictionaryParametersIndex = Dict{Any,Any}()
    dictionaryIndexParameters = Dict{Any,Any}()
    dictionaryIndexValue = Dict{Any,Any}()
    index = 0
    for (k,v) in _params
        index = index +1
        dictionaryParametersIndex[k]=index
        dictionaryIndexParameters[index]=k
        dictionaryIndexValue[index] = v
    end
    return [dictionaryParametersIndex, dictionaryIndexParameters, dictionaryIndexValue]
end 
   



function convert_equations_variables(sys, dict_var)
    equations = ModelingToolkit.get_eqs(sys)
    f =""
    for e in equations
       print(e)
    end

    return f
end

function convesion_function(sys)
   for i in sys
    println(i)
   end
end


#Functions to translate the equations 


function add_return_variable()
    #e = "add_equation!(eqs, GSGDP ~ GS / NI)"
    e = split(text, "\n" )
    variable_equation = []
    all_components = []
    
    for i in e
        
        e_split = split.(i, " ~ " )
        e_all_components = split.(e_split[2], " ")
        
        #println("all component", e_all_components)
        push!(all_components, e_all_components)
        e_s_s= split(e_split[1], ", ")

        push!(variable_equation, e_s_s[2])
    #print(variabile_equation)
    end
    return [variable_equation, all_components]
end


function from_add_create_initial_du_array()
    array_iv= add_return_variable()[1] #split the text of equations
    variable_index = variable_index_name_value(_variables)[1] #returns the index of the variable
    println(variable_index)
    
    du = []
    for i in array_iv
        for k in keys(variable_index)
            if i==string(k)
                
                insert!(du, variable_index[k], variable_index[k])
            end
        end
    end 
    return du
    
end

function from_add_create_equation()
    du = from_add_create_initial_du_array()
    array_eq= add_return_variable()[2] #split the text of equations
    variable_index = variable_index_name_value(_variables)[1] #returns the index of the variable
    #println(variable_index)
    
    for single_element in array_eq
        #println("Single eq", single_element)
        
        index = findfirst(==(single_element), array_eq)
        println(index)
        for e in single_element
            e = strip(e, [')'])
            c = translate(e)
            println("Element equation: ", c)
            
        end
    end
end



function translate(e)
    u = []
    p = []
    variable_index = variable_index_name_value(_variables)[1]
    parameter_index = params_index_name_value(_params)[1]
    for (kv,vv) in variable_index
        for (kp, vp) in parameter_index
            
            
            if e == string(kv) 
                insert!(u,variable_index[kv],variable_index[kv] )
               
            end

            if e == string(kp)
                insert!(p, parameter_index[kp], parameter_index[kp])
            end
        end
    end
    return [u,p]
end