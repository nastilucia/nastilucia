include("functions.jl")


using GlobalSensitivity, Statistics, OrdinaryDiffEq, QuasiMonteCarlo, Plots
using Interpolations
using DifferentialEquations
using ModelingToolkit

using Distributions, Random
@variables t
D = Differential(t)



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

    add_equation!(eqs, D(var1) ~ -X2 * par1*par2*par3)
    add_equation!(eqs, D(var2) ~ 1+X2 * par1*par2*par3)
    add_equation!(eqs, X2 ~ WorldDynamics.interpolate(t, y, xranges) )
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

function variables_index(sys, sol)
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