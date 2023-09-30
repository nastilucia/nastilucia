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
add_equation!(eqs, var2 ~ var1 + par1)
add_equation!(eqs, D(var1) ~ par2 * var2)"

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
        dictionaryVariablesIndex[string(k)]=index
        dictionaryIndexVariables[index]=string(k)
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
        dictionaryParametersIndex[string(k)]=index
        dictionaryIndexParameters[index]=string(k)
        dictionaryIndexValue[index] = v
    end
    return [dictionaryParametersIndex, dictionaryIndexParameters, dictionaryIndexValue]
end 

function split_equation()
    #e = "add_equation!(eqs, GSGDP ~ GS / NI)"
    e = split(text, "\n" )
   
    all_components = []
    chunk_array = []
    
    for i in e
        #e_split = split.(i, "eqs, " )
        e_split= getindex.(split.(i, "eqs, "), 2)
        e_split = chop(e_split, tail =1)
        
        
        push!(all_components, e_split)
    end
    
    for e_split in all_components
        println(e_split[1])
        if (string(e_split[1]) == "D" && string(e_split[2]) == "(" )
                
            println("Go to write differential equations")
            write_differential_eq(e_split, chunk_array)
            
        end
        if  (string(e_split[1]) != "D" && string(e_split[2]) != "(" )
            println("Go to another method")
            write_not_differential_eq(e_split, chunk_array)

        end
        
        
    end
    
    return [all_components, chunk_array]
end

function write_not_differential_eq(e_split, chunk_array)
    variable_index = variable_index_name_value(_variables)[1]
    parameter_index = params_index_name_value(_params)[1]
    
    chunk = split.(e_split, " ")
    new_chunk = ""

    for i in chunk   
        if (length(i) >=2)
            if (i in (keys(variable_index)))
                new_chunk = new_chunk * "u["*string(variable_index[i])*"]"
                println("New chunk variable ", new_chunk)
            end
            if  (i in (keys(parameter_index)))
                new_chunk = new_chunk * "p["*string(parameter_index[i])*"]"
                println("New chunk parameter ", new_chunk)
            end
        elseif (length(i) == 1)
            if (i == "~")
                new_chunk = new_chunk*" = "
                println("New chunk math", new_chunk)
            else
                new_chunk = new_chunk * " " * string(i)* " "
            end
        end
    
    end
    push!(chunk_array, new_chunk)
end



function write_differential_eq(e_split, chunk_array)
    variable_index = variable_index_name_value(_variables)[1]
    parameter_index = params_index_name_value(_params)[1]
    
    chunk = split.(e_split, " ")
    new_chunk = ""

    for i in chunk   
        
        println("i: ", i)
       

        if (length(i) >=2 )
            
            if (string(i[1])== "D" && string(i[2]) == "(")
                println(" I qui : ", i )
                i_n = chop(i, head=2, tail =1)
                println("variable_name ", i_n)
               
                new_chunk = new_chunk * "du["*string(variable_index[i_n])*"]"
                println("New chunk variable ", new_chunk)
            end
        
            if (i in (keys(variable_index)))
                new_chunk = new_chunk * "u["*string(variable_index[i])*"]"
                println("New chunk variable ", new_chunk)
            end
            if  (i in (keys(parameter_index)))
                new_chunk = new_chunk * "p["*string(parameter_index[i])*"]"
                println("New chunk parameter ", new_chunk)
            end

        
        elseif (length(i) == 1)
            if (i == "~")
                
                new_chunk = new_chunk*" = "
                println("New chunk math", new_chunk)

            else
                new_chunk = new_chunk * " " * string(i)* " "
        
            end
        end 
    
    end
    push!(chunk_array, new_chunk)
    return chunk_array
end


