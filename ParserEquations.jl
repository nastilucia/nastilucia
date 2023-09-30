global text = "add_equation!(eqs, GIC ~ GD * GBC)
add_equation!(eqs, GIPC ~ PGCIN - GPU)
add_equation!(eqs, GNI ~ (WT + OT + STO + STW + IC2022) - TP + ST)
add_equation!(eqs, GNISNI ~ GNI / NI)
add_equation!(eqs, GP ~ GD / GPP)
add_equation!(eqs, GPU ~ PGCIN * GCF) 
add_equation!(eqs, GS ~ GPU + GIPC)"


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


function from_add_create_initial_condition()
    array_iv= add_return_variable()[1]
    du = []
    
    for e in array_iv 
        
    end

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



"----------------------------------------------------------------------"

"This function takes in input a text, splitting it in equations using _n. Then it splits all the equations using the string eqs,
in this way we can ignore the first part of the equation. Then we split again the string using the symbol ~"

function new_add_return_variable()
    #e = "add_equation!(eqs, GSGDP ~ GS / NI)"
    e = split(text, "\n" )
   
    all_components = []
    
    for i in e
        e_split = split.(i, "eqs, " )
        e_all_components = split.(e_split[2], " ~ ")
        push!(all_components, e_all_components)
    end
    
    return all_components
end


function create_functions_from_allcomponents()
    all_components_e = new_add_return_variable()
    value = 0.5
    du = []
    u = []
    p = []
    math = []
    for element_eq in all_components_e
        for e in element_eq
            println("e: ",e )
            println("elem:  ", element_eq)
            #e = strip(e, [')'])
            #println("Element eq: ", element_eq, "e qui:    ", e)
            #translate(e,u,p,math)
        end
    end
   
    for i in all_components_e
        println("Sono qui: ", i[1])
        new_create_du(i[1], value, du)
    end

end


function new_create_du(e, value, du)
    variable_index = variable_index_name_value(_variables)[1] #returns the index of the variable
    println("quanti elementi", length(variable_index))
    
    
    for k in keys(variable_index)
        println("k: ", k)
        if e==string(k) 
            index = variable_index[k]
            insert!(du, index, value)
        end
    end
    
    return du
end


function translate(e, u, p, math)
    eq = []
    println("e: ", e)
    variable_index = variable_index_name_value(_variables)[1]
    parameter_index = params_index_name_value(_params)[1]
    for (kv,vv) in variable_index
        for (kp, vp) in parameter_index
            println("sono qui: ")
            
            if e == string(kv) 
                element_u = insert!(u,variable_index[kv],variable_index[kv] )
                println("element u    ", element_u)
                println("prova:   ", typeof(+))
            end

            if e == string(kp)
                insert!(p, parameter_index[kp], parameter_index[kp])
            end

            
        end
    end
    return eq
end