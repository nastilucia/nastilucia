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
smooth_equation!(eqs, var2, var1, par1)
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

#split equations based on their characteristics 

function equation_one_by_one()
    equations = split(text, "\n" )
    chunk_array = []

    for e in equations
        println(e)
        if (string(e[1]) == "a")
            println("Add equation")
            add_split_equation(e, chunk_array)
            println(chunk_array)
        end
        if (string(e[1]) == "s")
            println("Smooth equation")
            smooth_translate_diff_eq(e, chunk_array)
        end
    end

end


#add_equation

function add_split_equation(e, chunk_array)
    
    #e = "add_equation!(eqs, GSGDP ~ GS / NI)"
    #e = split(text, "\n" )
   
    all_components = []
    #chunk_array = []
    """
    for i in e
        #e_split = split.(i, "eqs, " )
        e_split= getindex.(split.(i, "eqs, "), 2)
        e_split = chop(e_split, tail =1)
        
        
        push!(all_components, e_split)
    end
    """
    e_split= getindex.(split.(e, "eqs, "), 2)
    e_split = chop(e_split, tail =1)
    push!(all_components, e_split)
    
    for e_split in all_components
        println(e_split[1])
        if (string(e_split[1]) == "D" && string(e_split[2]) == "(" )
                
            #println("Go to write differential equations")
            write_differential_eq(e_split, chunk_array)
            
        end
        if  (string(e_split[1]) != "D" && string(e_split[2]) != "(" )
            #println("Go to another method")
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
            end
            if  (i in (keys(parameter_index)))
                new_chunk = new_chunk * "p["*string(parameter_index[i])*"]"
            end
        elseif (length(i) == 1)
            if (i == "~")
                new_chunk = new_chunk*" = "
            else
                new_chunk = new_chunk * " " * string(i)* " "
            end
        end
    
    end
    push!(chunk_array, new_chunk)
end


#add_equation
function write_differential_eq(e_split, chunk_array)
    variable_index = variable_index_name_value(_variables)[1]
    parameter_index = params_index_name_value(_params)[1]
    
    chunk = split.(e_split, " ")
    new_chunk = ""

    for i in chunk   
        if (length(i) >=2 )
            
            if (string(i[1])== "D" && string(i[2]) == "(")
                i_n = chop(i, head=2, tail =1)
                new_chunk = new_chunk * "du["*string(variable_index[i_n])*"]"
            end
        
            if (i in (keys(variable_index)))
                new_chunk = new_chunk * "u["*string(variable_index[i])*"]"
            end
            if  (i in (keys(parameter_index)))
                new_chunk = new_chunk * "p["*string(parameter_index[i])*"]"
            end

        
        elseif (length(i) == 1)
            if (i == "~")
                new_chunk = new_chunk*" = "
            else
                new_chunk = new_chunk * " " * string(i)* " "     
            end
        end 
    
    end
    push!(chunk_array, new_chunk)
    return chunk_array
end



#global e1 ="smooth!(eqs, var1, var1 * (var1 + var1 + var2) / 3, par3)"
#global e1 = "smooth!(eqs, var1, var2, par1)"
function smooth_translate_diff_eq(e, chunk_array)
    
    variable_index = variable_index_name_value(_variables)[1]
    parameter_index = params_index_name_value(_params)[1]
    new_chunk1 = ""
    new_chunk2 = ""
    new_chunk3 = ""
    chunk_n = split.(e, "eqs, ")
    println("chunk_n     ", chunk_n)
    println("chunk_n 2    ", chunk_n[2])
    chunk = chop(chunk_n[2], tail =1)
    chunk = split.(chunk, ", ")
    
    #Define e translate du[variable]
    if (string(chunk[1]) in (keys(variable_index)))
        new_chunk1 = new_chunk1 * "du["*string(variable_index[string(chunk[1])])*"]" * " = "
    end

    #define and translate chunk 2 

    s2 = chunk[2]
    s2 = split.(s2, " ")
    length_s2 = length(s2)

    if (length_s2 == 1)
        if (string(chunk[2]) in (keys(variable_index)))
            new_chunk2 = new_chunk2 * "u["*string(variable_index[string(chunk[2])])*"]" 
        end
    end

    if (length_s2 > 1)
        for i in s2
            println("i", i)
            if (length(i) > 1)
                if (string(first(i)) == "(")
                    i_n= replace(i, "("=>"")
                    if (i_n in (keys(variable_index)))
                        new_chunk2 = new_chunk2 * "(" * "u["*string(variable_index[i_n])*"]"
                    end
                    if  (i_n in (keys(parameter_index)))
                        new_chunk2 = new_chunk2 *  "(" * "p["*string(parameter_index[i_n])*"]"
                    end
                end 
                  
                if (string(last(i)) ==")")
                    i_n= chop(i, tail=1)
                    if (i_n in (keys(variable_index)))
                        new_chunk2 = new_chunk2 * "u["*string(variable_index[string(i_n)])*"])"
                    end
                    if  (string(i_n) in (keys(parameter_index)))
                        new_chunk2 = new_chunk2 * "p["*string(parameter_index[string(i_n)])*"])"
                    end 
                end
                if (string(last(i)) != ")" && string(first(i)) != "(")
                    if (i in (keys(variable_index)))
                        new_chunk2 = new_chunk2 * "u["*string(variable_index[i])*"]"
                    end
                    if  (i in (keys(parameter_index)))
                        new_chunk2 = new_chunk2 * "p["*string(parameter_index[i])*"]"
                    end 
                end
            end
            if (length(i) == 1)
            if (i == "~")   
                new_chunk2 = new_chunk2*" = "
            else
                new_chunk2 = new_chunk2 * " " * string(i)* " "
            end
            
            end
        end
    end

    
    
    #define and translate chunk 3
    if (string(chunk[3]) in (keys(parameter_index)))
        new_chunk3 = new_chunk3 * " / p["*string(parameter_index[string(chunk[3])])*"]"
       
    end
    
    
new_chunk_final = new_chunk1 * "(" *new_chunk2 * ")" * new_chunk3    
push!(chunk_array, new_chunk_final)
    
return chunk_array  
    

end
