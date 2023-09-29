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