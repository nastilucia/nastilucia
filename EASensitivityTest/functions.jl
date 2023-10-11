using IfElse
using Formatting
using Graphs
using Latexify
using PlotlyJS
using Printf

using WorldDynamics

function add_equation!(eqs, equation)
   append!(eqs, [equation])
end

function delay_n!(eqs, x, rt, lv, delay, order)
   append!(eqs, [rt[1] ~ lv[1] / (delay / order)])
   append!(eqs, [D(lv[1]) ~ x - rt[1]])
   for d in 2:order
      append!(eqs, [rt[d] ~ lv[d] / (delay / order)])
      append!(eqs, [D(lv[d]) ~ rt[d-1] - rt[d]])
   end
end

ramp(x, slope, startx, endx) = IfElse.ifelse(x > startx, IfElse.ifelse(x < endx, slope * (x - startx), slope * (endx - startx)), 0)

function smooth!(eqs, x, input, delay_time)
   append!(eqs, [D(x) ~ (input - x) / delay_time])
end

clip(returnifgte, returniflt, inputvalue, threshold) = IfElse.ifelse(inputvalue ≥ threshold, returnifgte, returniflt)

step(inputvalue, returnifgte, threshold) = clip(returnifgte, zero(returnifgte), inputvalue, threshold)


pulse(inputvalue, start, width) = IfElse.ifelse(inputvalue >= start, 1, 0) * IfElse.ifelse(inputvalue < (start + width), 1, 0)

interpolate(x, x₁, xₙ, y₁, yₙ) = y₁ + (x - x₁) * ((yₙ - y₁) / (xₙ - x₁))

function interpolate(x, yvalues::Tuple{Vararg{Float64}}, xrange::Tuple{Float64,Float64})
   interpolate(x, collect(yvalues), collect(LinRange(xrange[1], xrange[2], length(yvalues))))
end

function interpolate(x, yvalues::Vector{Float64}, xvalues::Vector{Float64})
   # y gets the min y value if less than the min x range
   #   or the max y value if greater than the max x range
   y = (x < xvalues[1]) * yvalues[1] + (x ≥ xvalues[end]) * yvalues[end]

   # in case x is inside the range, y gets the interpolated value
   for i ∈ 1:length(yvalues)-1
      y += (x ≥ xvalues[i]) * (x < xvalues[i+1]) * interpolate(x, xvalues[i], xvalues[i+1], yvalues[i], yvalues[i+1])
   end

   return y
end

function withlookup(x, pairs::Vector{Tuple{Float64,Float64}})
   interpolate(x, map(t -> t[end], pairs), map(t -> t[1], pairs))
end

##############################################################################
# Functions supporting documentation and analysis of ODE systems and solutions
##############################################################################
function is_lhs_var(v, eq)
   l = replace(string(eq.lhs), "Differential(t)(" => "")
   l = replace(l, "))" => ")")
   return string(v) == l
end

function used_by_vars(v, sa)
   ubv = []
   for s = 1:lastindex(sa)
      vars = states(sa[s])
      eqs = equations(sa[s])
      eq_deps = equation_dependencies(sa[s])
      for i in 1:lastindex(eq_deps)
         if (issubset(string.([v]), string.(eq_deps[i])))
            l = replace(string(eqs[i].lhs), "Differential(t)(" => "")
            l = replace(l, "))" => ")")
            push!(ubv, l)
         end
      end
   end
   return ubv
end

function used_by_vars(p, eqs, eq_deps)
   ubv = []
   for i in 1:lastindex(eq_deps)
      if (issubset(string.([p]), string.(eq_deps[i])))
         l = replace(string(eqs[i].lhs), "Differential(t)(" => "")
         l = replace(l, "))" => ")")
         push!(ubv, l)
      end
   end
   return ubv
end

function clean_latex(s, dp)
   s = replace(s, "mathrm" => "mathtt")
   s = replace(s, "mathtt{d}" => "mathrm{d}")
   s = replace(s, "\\mathrm{d} \\cdot" => "\\mathrm{d}")
   s = replace(s, " " => "")
   s = replace(s, "\\cdote" => "\\cdot e")
   s = "\\(" * split(s, "\$")[2] * "\\)"
   for i in 1:lastindex(dp)
      s = replace(s, dp[i] => "\\mathtt{" * dp[i] * "}")
   end
   return s
end

function eqs_exceptions()
   return Dict{String,String}(
      "IEST" => "\\(\\mathtt{withlookup}\\left(\\frac{\\mathtt{INEQ}(t)}{\\mathtt{AI}}, [(0.0, 1.0), (1.0, 1.0), (2.0, 0.0)]\\right)\\)",
      "PSESTR" => "\\(\\mathtt{withlookup}\\left(\\frac{\\mathtt{PSSGDP}(t)}{\\mathtt{SPS}}, [(0.0, 0.0), (1.0, 1.0)]\\right)\\)",
      "NN2OE" => "\\(\\mathtt{withlookup}(t, [(1980.0, 0.009), (2020.0, 0.009), (2099.27, 0.0)])\\)",
      "N2OFPP" => "\\(\\mathtt{withlookup}(t, [(1980.0, 0.43), (2000.0, 0.64), (2010.0, 0.73), (2020.0, 0.8), (2100.0, 1.0)])\\)",
      "NCH4E" => "\\(\\mathtt{withlookup}(t, [(1980.0, 0.19), (2020.0, 0.19), (2100.0, 0.19)])\\)",
      "CH4FPP" => "\\(\\mathtt{withlookup}(t, [(1980.0, 0.82), (2000.0, 0.94), (2020.0, 1.01), (2100.0, 1.1)])\\)",
      "CO2FPP" => "\\(\\mathtt{withlookup}(t, [(1980.0, 0.0032), (1990.0, 0.0041), (2000.0, 0.0046), (2020.0, 0.0051), (2100.0, 0.006)])\\)",
      "FOG" => "\\(\\mathtt{withlookup}(t, [(1980.0, 0.18), (2000.0, 0.36), (2020.0, 0.39), (2050.0, 0.37), (2100.0, 0.0)])\\)",
      "REHE" => "\\(\\mathtt{withlookup}(\\mathtt{OW}(t), [(0.0, 1.0), (1.2, 4.8), (2.0, 8.6), (2.9, 14.0), (5.2, 40.0)])\\)",
      "TPPUEBEE" => "\\(\\mathtt{withlookup}(\\mathtt{GDPP}(t), [(0.0, 0.0), (10.0, 4.0), (20.0, 7.0), (30.0, 9.0), (50.0, 12.0), (65.0, 13.0)])\\)",
      "TPPUFFNEUBEE" => "\\(\\mathtt{withlookup}(\\mathtt{GDPP}(t), [(0.0, 0.3), (15.0, 2.0), (25.0, 3.1), (35.0, 4.0), (50.0, 5.0)])\\)",
      "NC" => "\\(\\mathtt{withlookup}(t, [(1980.0, 75.0), (2000.0, 310.0), (2020.0, 310.0), (2098.9, 310.0)])\\)",
      "BIUS" => "\\(\\mathtt{withlookup}(t, [(1980.0, 0.0), (1990.0, 0.0), (2000.0, 0.0), (2020.0, 0.0), (2100.0, 0.0)])\\)",
      "TFUCA" => "\\(\\mathtt{withlookup}(\\mathtt{DCYCA}(t), [(1.0, 0.0), (2.0, 40.0), (2.5, 50.0), (3.0, 60.0), (3.5, 70.0), (4.5, 100.0), (6.5, 200.0), (10.0, 600.0)])\\)",
      "TUCP" => "\\(\\mathtt{withlookup}(\\mathtt{GDPP}(t), [(0.0, 400.0), (6.1, 680.0), (8.7, 780.0), (13.9, 950.0), (20.0, 1050.0), (30.0, 1150.0), (40.0, 1250.0), (60.0, 1350.0), (100.0, 1550.0)])\\)",
      "TURMP" => "\\(\\mathtt{withlookup}(\\mathtt{GDPP}(t), [(0.0, 0.0), (6.1, 6.0), (8.8, 8.5), (14.0, 13.0), (30.0, 27.0), (40.0, 32.0), (50.0, 33.0), (100.0, 25.0)])\\)",
      "ROCWSO" => "\\(\\mathtt{withlookup}\\left(\\frac{\\mathtt{PURA}(t)}{\\mathtt{AUR}(t)}, [(0.0, 0.06), (0.5, 0.02), (1.0, 0.0), (1.5, -0.007), (2.0, -0.01)]\\right)\\)",
      "ISR" => "\\(\\mathtt{ISR}\\left(t\\right)=\\mathtt{NSR}\\cdot\\left(1+\\mathtt{INSR}\\cdot\\left(-1+\\frac{\\mathtt{PI}\\left(t\\right)}{\\mathtt{IT}}\\right)+\\mathtt{UNSR}\\cdot\\left(-1+\\frac{\\mathtt{PU}\\left(t\\right)}{\\mathtt{UT}}\\right)\\right)\\)",
      "DEATHS" => "\\(\\mathtt{DEATHS}\\left(t\\right)=\\mathtt{delayn}\\left(\\mathtt{PASS60}, \\mathtt{LE60}, \\mathtt{init}(\\mathtt{DEATHS}), \\mathtt{ORDER}\\right)\\)",
      "PASS20" => "\\(\\mathtt{PASS20}\\left(t\\right)=\\mathtt{delayn}\\left(\\mathtt{BIRTHS}, 20, \\mathtt{init}(\\mathtt{PASS20}), \\mathtt{ORDER}\\right)\\)",
      "PASS40" => "\\(\\mathtt{PASS40}\\left(t\\right)=\\mathtt{delayn}\\left(\\mathtt{PASS20}, 20, \\mathtt{init}(\\mathtt{PASS40}), \\mathtt{ORDER}\\right)\\)",
      "PASS60" => "\\(\\mathtt{PASS60}\\left(t\\right)=\\mathtt{delayn}\\left(\\mathtt{PASS40}, 20, \\mathtt{init}(\\mathtt{PASS60}), \\mathtt{ORDER}\\right)\\)",
      "IPP" => "\\(\\mathtt{IPP}\\left(t\\right)=\\mathtt{ifelse}\\left(\\left(\\mathtt{EIPF}>0\\right),\\mathtt{EIP},\\mathtt{RD}\\left(t\\right)\\right)\\)",
   )
end

function dep_exceptions()
   return Dict{String,Array{String}}(
      "PASS20(t)" => ["BIRTHS(t)"],
      "PASS40(t)" => ["PASS20(t)"],
      "PASS60(t)" => ["PASS40(t)"],
      "DEATHS(t)" => ["PASS60(t)"],
   )
end

function used_by_exceptions()
   return Dict{String,String}(
      "BIRTHS(t)" => "PASS20(t)",
      "PASS20(t)" => "PASS40(t)",
      "PASS40(t)" => "PASS60(t)",
      "PASS60(t)" => "DEATHS(t)",
   )
end

function write_html_head(f)
   write(f, "<head>\n")
   write(f, "  <script src=\"https://polyfill.io/v3/polyfill.min.js?features=es6\"></script>\n")
   write(f, "  <script id=\"MathJax-script\" async src=\"https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js\"></script>\n")
   write(f, "  <style>\n")
   write(f, "      .styled-table {\n")
   write(f, "          border-collapse: collapse;\n")
   write(f, "          border-radius: 10px;\n")
   write(f, "          margin: 25px 0;\n")
   write(f, "          font-size: 1.5em;\n")
   write(f, "          font-family: sans-serif;\n")
   write(f, "          min-width: 400px;\n")
   write(f, "          box-shadow: 0 0 20px rgba(0, 0, 0, 0.15);\n")
   write(f, "          overflow:hidden;\n")
   write(f, "      }\n")
   write(f, "      .styled-table thead tr {\n")
   write(f, "          background-color: #009879;\n")
   write(f, "          color: #ffffff;\n")
   write(f, "          text-align: left;\n")
   write(f, "      }\n")
   write(f, "      .styled-table th,\n")
   write(f, "      .styled-table td {\n")
   write(f, "          padding: 12px 15px;\n")
   write(f, "      }\n")
   write(f, "      .styled-table tbody tr {\n")
   write(f, "          border-bottom: 1px solid #dddddd;\n")
   write(f, "      }\n")
   write(f, "      .styled-table tbody tr:nth-of-type(even) {\n")
   write(f, "          background-color: #f3f3f3;\n")
   write(f, "      }\n")
   write(f, "      .styled-table tbody tr:last-of-type {\n")
   write(f, "          border-bottom: 2px solid #009879;\n")
   write(f, "      }\n")
   write(f, "      .styled-table tbody tr.active-row {\n")
   write(f, "          font-weight: bold;\n")
   write(f, "          color: #009879;\n")
   write(f, "      }\n")
   write(f, "      h1 {\n")
   write(f, "         font-size: 70px;\n")
   write(f, "         font-weight: 600;\n")
   write(f, "         background-image: linear-gradient(to left, #553c9a, #b393d3);\n")
   write(f, "         color: transparent;\n")
   write(f, "         background-clip: text;\n")
   write(f, "         -webkit-background-clip: text;\n")
   write(f, "      }\n")
   write(f, "      h2 {\n")
   write(f, "         font-size: 50px;\n")
   write(f, "         font-weight: 400;\n")
   write(f, "         background-image: linear-gradient(to left, #009879, #009879);\n")
   write(f, "         color: transparent;\n")
   write(f, "         background-clip: text;\n")
   write(f, "         -webkit-background-clip: text;\n")
   write(f, "      }\n")
   write(f, "  </style>\n")
   write(f, "</head>\n\n")
end

function var_dependencies(sa, sn, si)
   println(uppercase(sn[si]), " dependencies")
   sys_vars = states(sa[si])
   sys_eqs = equations(sa[si])
   sys_eq_v_deps = equation_dependencies(sa[si])
   sys_eq_p_deps = equation_dependencies(sa[si], variables=parameters(sa[si]))
   sys_vd_graph = variable_dependencies(sa[si])
   eq_exceps = eqs_exceptions()
   de_exceps = dep_exceptions()
   ub_exceps = used_by_exceptions()
   var_system_name::Dict{String,String} = Dict{String,String}()
   for var in sort(ModelingToolkit.get_states(sa[si]), by=x -> string(x))
      desc = ModelingToolkit.getdescription(var)
      if (desc != "" && !startswith(desc, "LV functions") && !startswith(desc, "RT functions"))
         dep_on_v = []
         for i in 1:lastindex(sys_eqs)
            if (is_lhs_var(var, sys_eqs[i]))
               if (get(de_exceps, string(var), "") == "")
                  dep_on_v = string.(sys_eq_v_deps[i])
               else
                  dep_on_v = de_exceps[string(var)]
               end
               break
            end
         end
         for i in 1:lastindex(dep_on_v)
            vs = var_system(dep_on_v[i], sa, sn)
            @assert (vs != "") "Variable " * dep_on_v[i] * " has no system"
            va = replace(dep_on_v[i], "(t)" => "")
            if (vs != sn[si])
               if (get(var_system_name, va, "") == "")
                  var_system_name[va] = uppercase(vs)
               end
            end
         end
      end
   end
   for k in keys(var_system_name)
      println(k, " from ", var_system_name[k])
   end
end

function write_html()
   sa = systems()
   sn = sector_names()
   for s in 1:lastindex(sa)
      println(sn[s])
      write_html(sa, sn, s)
   end
end

function write_html(sa, sn, si)
   mkpath("output/html/")
   open("output/html/" * sn[si] * ".html", "w") do f
      write(f, "<html>\n")
      write_html_head(f)
      write(f, "<body style=\"text-align:center\">\n\n\t<h1>The ", uppercase(sn[si]), " sector</h1>\n")
      write(f, "\t<h2 style=\"text-align:left\">The variables</h2>\n")
      write_html_vars(sa, sn, si, f)
      write(f, "\n\t<h2 style=\"text-align:left\">The parameters</h2>\n")
      write_html_pars(sa[si], f)
      write(f, "</body>\n</html>")
   end
end

function write_html_vars(sa, sn, si, f)
   sys_vars = states(sa[si])
   sys_eqs = equations(sa[si])
   sys_eq_v_deps = equation_dependencies(sa[si])
   sys_eq_p_deps = equation_dependencies(sa[si], variables=parameters(sa[si]))
   sys_vd_graph = variable_dependencies(sa[si])
   eq_exceps = eqs_exceptions()
   de_exceps = dep_exceptions()
   ub_exceps = used_by_exceptions()
   write(f, "<table class=\"styled-table\">\n\t<thead>\n\t\t<tr>\n\t\t\t<th>Vensim name</th>\n\t\t\t<th>Name</th>\n\t\t\t<th>Used variables</th>\n\t\t\t<th>Used parameters</th>\n\t\t\t<th>Variables using it</th>\n\t\t\t<th>Initial value</th>\n\t\t\t<th>Equation</th>\n\t\t</tr>\n\t</thead>\n\t<tbody>\n")
   for var in sort(ModelingToolkit.get_states(sa[si]), by=x -> string(x))
      desc = ModelingToolkit.getdescription(var)
      if (desc != "" && !startswith(desc, "LV functions") && !startswith(desc, "RT functions"))
         ltx = "\\mathrm{NA}"
         dep_on_v = []
         dep_on_p = []
         for i in 1:lastindex(sys_eqs)
            if (is_lhs_var(var, sys_eqs[i]))
               if (get(de_exceps, string(var), "") == "")
                  dep_on_v = string.(sys_eq_v_deps[i])
               else
                  dep_on_v = de_exceps[string(var)]
               end
               dep_on_p = string.(sys_eq_p_deps[i])
               ltx = clean_latex(latexinline(sys_eqs[i]; cdot=true, fmt=x -> format(round(x, sigdigits=2))), dep_on_p)
               break
            end
         end
         used_by = used_by_vars(var, sa)
         if (get(ub_exceps, string(var), "") != "")
            push!(used_by, ub_exceps[string(var)])
         end
         acronym = replace(string(var), "(t)" => "")
         write(f, "\t<tr id=\"", acronym, "\">\n")
         if (get(eq_exceps, acronym, "") != "")
            ltx = eq_exceps[acronym]
         end
         write(f, "\t\t<td>", desc, "</td>\n")
         write(f, "\t\t<td><code>", acronym, "</code></td>\n")
         write(f, "\t\t<td>")
         for i in 1:lastindex(dep_on_v)
            vs = var_system(dep_on_v[i], sa, sn)
            @assert (vs != "") "Variable " * dep_on_v[i] * " has no system"
            va = replace(dep_on_v[i], "(t)" => "")
            if (vs == sn[si])
               write(f, "<a href=#", va, "><code>", va, "</code></a> ")
            else
               write(f, "<a href=\"", vs, ".html#", va, "\"><code>", va, "</code></a> ")
            end
         end
         write(f, "</td>\n")
         write(f, "\t\t<td>")
         for i in 1:lastindex(dep_on_p)
            write(f, "<a href=#", dep_on_p[i], "><code>", dep_on_p[i], "</code></a> ")
         end
         write(f, "</td>\n")
         write(f, "\t\t<td>")
         for i in 1:lastindex(used_by)
            if (!startswith(used_by[i], "(LV_") && !startswith(used_by[i], "(RT_"))
               vs = var_system(used_by[i], sa, sn)
               @assert (vs != "") "Variable " * used_by[i] * " is used by variable " * acronym * " but has no associated system"
               va = replace(used_by[i], "(t)" => "")
               if (vs == sn[si])
                  write(f, "<a href=#", va, "><code>", va, "</code></a> ")
               else
                  write(f, "<a href=\"", vs, ".html#", va, "\"><code>", va, "</code></a> ")
               end
            end
         end
         write(f, "</td>\n")
         try
            v = round(ModelingToolkit.getdefault(var), digits=4)
            write(f, "\t\t<td>", string(v), "</td>\n")
         catch err
            write(f, "\t\t<td></td>\n")
         end
         write(f, "\t\t<td>", ltx, "</td>\n")
         write(f, "\t</tr>\n")
      end
   end
   write(f, "\t</tbody>\n</table>\n")
end

function write_html_pars(sys, f)
   sys_vars = states(sys)
   sys_eqs = equations(sys)
   sys_eq_v_deps = equation_dependencies(sys)
   sys_eq_p_deps = equation_dependencies(sys, variables=parameters(sys))
   sys_vd_graph = variable_dependencies(sys)
   write(f, "<table class=\"styled-table\">\n\t<thead>\n\t\t<tr>\n\t\t\t<th>Vensim name</th>\n\t\t\t<th>Name</th>\n\t\t\t<th>Is used by</th>\n\t\t\t<th>Value</th>\n\t\t</tr>\n\t</thead>\n\t<tbody>\n")
   for par in sort(ModelingToolkit.get_ps(sys), by=x -> string(x))
      desc = ModelingToolkit.getdescription(par)
      if (desc != "")
         used_by = used_by_vars(par, sys_eqs, sys_eq_p_deps)
         acronym = string(par)
         write(f, "\t<tr id=\"", acronym, "\">\n")
         write(f, "\t\t<td>", desc, "</td>\n")
         write(f, "\t\t<td><code>", acronym, "</code></td>\n")
         write(f, "\t\t<td>")
         for i in 1:lastindex(used_by)
            va = replace(used_by[i], "(t)" => "")
            write(f, "<a href=#", va, "><code>", va, "</code></a> ")
         end
         write(f, "</td>\n")
         try
            v = round(ModelingToolkit.getdefault(par), digits=4)
            write(f, "\t\t<td>", string(v), "</td>\n")
         catch err
            write(f, "\t\t<td></td>\n")
         end
         write(f, "\t</tr>\n")
      end
   end
   write(f, "\t</tbody>\n</table>\n")
end

function print_ps(sys)
   println("| Vensim name | Name | Value | Sector |")
   println("| --- | --- | --- | --- |")
   for s in ModelingToolkit.get_ps(sys)
      println("| ", ModelingToolkit.getdescription(s), " | `", string(s), "` | ", round(ModelingToolkit.getdefault(s), digits=4), " | ", nameof(sys), " |")
   end
end

function print_exo_vars(sys)
   println("| Vensim name | Name | Initial value |")
   println("| --- | --- | --- |")
   for s in ModelingToolkit.get_states(sys)
      desc = ModelingToolkit.getdescription(s)
      if (desc != "")
         desc_split = split(desc, ".")
         println("| ", desc_split[2], " | `", string(s), "` | ", desc_split[1], " |")
      end
   end
end

function read_vensim_dataset(fn, to_be_removed)
   f::IOStream = open(fn, "r")
   ds = Dict{String,Array{Float64}}()
   for line in eachline(f)
      split_line::Vector{String} = split(line, "\t")
      s = replace(split_line[1], "\"" => "")
      s = replace(s, to_be_removed => "")
      s = replace(s, " (Year)" => "")
      s = replace(s, "\$" => "dollar")
      v::Array{Float64} = Array{Float64}(undef, length(split_line) - 1)
      for i in 2:lastindex(split_line)
         v[i-1] = parse(Float64, split_line[i])
      end
      ds[lowercase(s)] = v
   end
   close(f)
   return ds
end

function check_descriptions_vars(vs_ds, sys)
   nsv = ModelingToolkit.namespace_variables(sys)
   for v in nsv
      d = ModelingToolkit.getdescription(v)
      if (d != "" && !startswith(d, "LV functions") && !startswith(d, "RT functions"))
         if (get(vs_ds, lowercase(ModelingToolkit.getdescription(v)), "") == "")
            println(ModelingToolkit.getdescription(v))
         end
      end
   end
end

function check_descriptions_ps(vs_ds, sys)
   nsp = ModelingToolkit.namespace_parameters(sys)
   for p in nsp
      d = ModelingToolkit.getdescription(p)
      if (d != "")
         if (get(vs_ds, lowercase(d), "") == "")
            println(d)
         end
      end
   end
end

function compare(a, b, pepsi)
   max_re = -1
   max_re_a = 0
   max_re_b = 0
   max_re_i = 0
   for i in 1:lastindex(a)
      if (pepsi >= 0)
         re = abs(a[i] - b[i]) / (abs(b[i]) + pepsi)
      else
         re = 0
         if (a[i] != 0 || b[i] != 0)
            re = (2 * abs(a[i] - b[i])) / (abs(a[i]) + abs(b[i]))
         end
      end
      if (re > max_re)
         max_re = max(max_re, re)
         max_re_a = a[i]
         max_re_b = b[i]
         max_re_i = i
      end
   end
   return max_re, max_re_a, max_re_b, max_re_i
end

function mre_sys(scen, sol, sys, vs_ds, pepsi, nt, verbose, do_plot, f)
   nsv = ModelingToolkit.namespace_variables(sys)
   max_re = 0.0
   for v in nsv
      d = ModelingToolkit.getdescription(v)
      if (d != "" && !startswith(d, "LV functions") && !startswith(d, "RT functions"))
         re, _, _, _ = Earth4All.compare(sol[v][1:nt], vs_ds[lowercase(d)], pepsi)
         max_re = max(max_re, re)
         if (verbose)
            println(d, "\t", re)
         end
         if (do_plot)
            savefig(compare_and_plot(scen, sol, d, v, vs_ds, 1980, 2100, nt, pepsi, true), "../figures/" * string(v) * ".png")
         end
         if (!isnothing(f))
            write(f, d * "\t" * string(re) * "\n")
         end
      end
   end
   return max_re
end

# function check_solution(sol, pepsi, nt, verbose, do_plot)
#    sector_name = ["climate", "demand", "energy", "finance", "foodland", "inventory", "labourmarket", "other", "output", "population", "public", "wellbeing"]
#    sector_system = system_array()
#    max_re = 0.0
#    for s in 1:lastindex(sector_name)
#       println("=========" * uppercase(sector_name[s]) * "=======")
#       vs_ds = read_vensim_dataset("../VensimOutput/tltl/" * sector_name[s] * ".txt")
#       re = mre_sys(sol, sector_system[s], vs_ds, pepsi, nt, verbose, do_plot)
#       println(re)
#       max_re = max(max_re, re)
#    end
#    println("=========MAXIMUM RE=======")
#    println(max_re)
#    return max_re
# end

function var_system(v, sa, sn)
   for s in 1:lastindex(sa)
      vars = states(sa[s])
      for i in 1:lastindex(vars)
         if (getdescription(vars[i]) != "" && string(vars[i]) == v)
            return sn[s]
         end
      end
   end
   return ""
end

function is_system_var(desc, sys)
   nsv = ModelingToolkit.namespace_variables(sys)
   for v in nsv
      d = ModelingToolkit.getdescription(v)
      if (d != "" && !startswith(d, "LV functions") && !startswith(d, "RT functions"))
         if (lowercase(d) == lowercase(desc))
            return true, v
         end
      end
   end
   return false, nothing
end

function compare_and_plot(scen, sol, desc, v, vs_ds, fy, ly, nt, pepsi, do_plot)
   r = compare(sol[v][1:nt], vs_ds[lowercase(desc)], pepsi)
   println(r, " at t=", sol.t[r[4]])
   if (do_plot)
      x = range(fy, ly, length=nt)
      trace1 = scatter(x=x, y=sol[v], name="WorldDynamics", line=attr(color="royalblue", dash="dash"))
      trace2 = scatter(x=x, y=vs_ds[lowercase(desc)], name="Vensim", line=attr(color="firebrick", dash="dot"))
      return plot([trace1, trace2], Layout(title=desc * " (" * scen * ")"))
   end
end

function systems()
   r = []
   @named cli = Earth4All.Climate.climate()
   @named dem = Earth4All.Demand.demand()
   @named ene = Earth4All.Energy.energy()
   @named fin = Earth4All.Finance.finance()
   @named foo = Earth4All.FoodLand.foodland()
   @named inv = Earth4All.Inventory.inventory()
   @named lab = Earth4All.LabourMarket.labour_market()
   @named oth = Earth4All.Other.other()
   @named out = Earth4All.Output.output()
   @named pop = Earth4All.Population.population()
   @named pub = Earth4All.Public.public()
   @named wel = Earth4All.Wellbeing.wellbeing()
   append!(r, [cli, dem, ene, fin, foo, inv, lab, oth, out, pop, pub, wel])
   return r
end

function sector_names()
   return ["climate", "demand", "energy", "finance", "foodland", "inventory", "labourmarket", "other", "output", "population", "public", "wellbeing"]
end

function compare_and_plot_one_scenario(scen, sol, desc, fy, ly, nt, pepsi)
   sector_name = sector_names()
   sector_system = systems()
   for s in 1:lastindex(sector_name)
      isv, v = is_system_var(desc, sector_system[s])
      if (isv)
         println(desc * " is in the sector " * uppercase(sector_name[s]))
         vs_ds = Earth4All.read_vensim_dataset("VensimOutput/" * lowercase(scen) * "/" * sector_name[s] * ".txt", " : E4A-220501 " * scen)
         return compare_and_plot(scen, sol, desc, v, vs_ds, fy, ly, nt, pepsi, true)
      end
   end
   println("The variable ", desc, " does not exist in any system")
end

function compare_and_plot_two_scenarios(sol1, sol2, desc, fy, ly, nt, pepsi)
   sector_name = sector_names()
   sector_system = systems()
   for s in 1:lastindex(sector_name)
      isv, v = is_system_var(desc, sector_system[s])
      if (isv)
         println(desc * " is in the sector " * uppercase(sector_name[s]))
         vs_ds_tltl = Earth4All.read_vensim_dataset("VensimOutput/tltl/" * sector_name[s] * ".txt", " : E4A-220501 TLTL")
         vs_ds_gl = Earth4All.read_vensim_dataset("VensimOutput/gl/" * sector_name[s] * ".txt", " : E4A-220501 GL")
         r1 = compare(sol1[v][1:nt], vs_ds_tltl[lowercase(desc)], pepsi)
         sr1 = @sprintf "MRE in TLTL scenario: %4.4f (%4.1f)" r1[1] sol1.t[r1[4]]
         println(sr1)
         r2 = compare(sol2[v][1:nt], vs_ds_gl[lowercase(desc)], pepsi)
         sr2 = @sprintf "MRE in GL scenario: %4.4f (%4.1f)" r2[1] sol2.t[r2[4]]
         println(sr2)
         x = range(fy, ly, length=nt)
         trace1 = scatter(x=x, y=vs_ds_tltl[lowercase(desc)], name="Vensim (TLTL)", line=attr(color="red"))
         trace2 = scatter(x=x, y=sol1[v], name="WorldDynamics (TLTL)", line=attr(color="blue"))
         trace3 = scatter(x=x, y=vs_ds_gl[lowercase(desc)], name="Vensim (GL)", line=attr(color="magenta"))
         trace4 = scatter(x=x, y=sol2[v], name="WorldDynamics (GL)", line=attr(color="black"))
         p = plot([trace1, trace2, trace3, trace4], Layout(title=desc * " (" * uppercase(sector_name[s]) * " sector)<br>" * sr1 * ". " * sr2))
         mkpath("html")
         savefig(p, "html/" * string(v) * ".html")
         return p
      end
   end
   println("The variable ", desc, " does not exist in any system")
end

function compare_and_plot(sol1, n1, sol2, n2, desc, fy, ly, nt1, nt2, pepsi, do_plot)
   sector_name = sector_names()
   sector_system = systems()
   for s in 1:lastindex(sector_name)
      isv, v = is_system_var(desc, sector_system[s])
      if (isv)
         println(desc * " is in the sector " * uppercase(sector_name[s]))
         r = compare(sol1[v], sol2[v], pepsi)
         println(r)
         if (do_plot)
            x1 = range(fy, ly, length=nt1)
            x2 = range(fy, ly, length=nt2)
            trace1 = scatter(x=x1, y=sol1[v], name=n1, line=attr(color="royalblue", dash="dash"))
            trace2 = scatter(x=x2, y=sol2[v], name=n2, line=attr(color="firebrick", dash="dot"))
            return plot([trace1, trace2], Layout(title=desc))
         end
      end
   end
   println("The variable ", desc, " does not exist in any system")
end

function plot_two_sols(sol1, scen1, sol2, scen2, desc, fy, ly, nt)
   sector_name = sector_names()
   sector_system = systems()
   for s in 1:lastindex(sector_name)
      isv, v = is_system_var(desc, sector_system[s])
      if (isv)
         println(desc * " is in the sector " * uppercase(sector_name[s]))
         x = range(fy, ly, length=nt)
         trace1 = scatter(x=x, y=sol1[v], name=scen1, line=attr(color="royalblue", dash="dash"))
         trace2 = scatter(x=x, y=sol2[v], name=scen2, line=attr(color="firebrick", dash="dot"))
         return plot([trace1, trace2], Layout(title=desc))
      end
   end
   println("The variable ", desc, " does not exist in any system")
end

function save_all_mre(scen, sol, pepsi, fn)
   max_re = 0
   sa = system_array()
   sn = sector_name()
   open("output/" * fn * ".csv", "w") do f
      for s in 1:lastindex(sn)
         vs_ds = Earth4All.read_vensim_dataset("VensimOutput/" * lowercase(scen) * "/" * sn[s] * ".txt", " : E4A-220501 " * scen)
         re = Earth4All.mre_sys(scen, sol, sa[s], vs_ds, pepsi, length(sol.t), false, false, f)
         @printf "Maximum MRE of %s: %4.9f\n" uppercase(sn[s]) re
         max_re = max(max_re, re)
      end
   end
   @printf "Maximum total MRE: %4.9f\n" max_re
end

function write_usage_graph(fn, ian)
   sa = systems()
   sn = sector_names()
   ne = 0
   acronym_id = Dict{String,Int64}()
   for i in 1:lastindex(sa)
      ne = ne + num_edges(sa, i, acronym_id)
   end
   mkpath("output/graphs/")
   open("output/graphs/" * ian * ".txt", "w") do f
      for k in sort(collect(keys(acronym_id)), by=x -> acronym_id[x])
         write(f, string(acronym_id[k]), ":", k, "\n")
      end
   end
   open("output/graphs/" * fn * ".txt", "w") do f
      write(f, string(length(acronym_id)), ",", string(ne), ",d,graph\n")
      for i in 1:lastindex(sa)
         write_usage_graph(sa, sn, i, acronym_id, f)
      end
   end
end

function num_edges(sa, si, ai)
   nv = length(ai)
   ne = 0
   sys_vars = states(sa[si])
   sys_eqs = equations(sa[si])
   sys_eq_v_deps = equation_dependencies(sa[si])
   de_exceps = dep_exceptions()
   for var in sort(sys_vars, by=x -> string(x))
      desc = ModelingToolkit.getdescription(var)
      if (desc != "" && !startswith(desc, "LV functions") && !startswith(desc, "RT functions"))
         acronym = replace(string(var), "(t)" => "")
         nv = nv + 1
         ai[acronym] = nv
         dep_on_v = []
         for i in 1:lastindex(sys_eqs)
            if (is_lhs_var(var, sys_eqs[i]))
               if (get(de_exceps, string(var), "") == "")
                  dep_on_v = string.(sys_eq_v_deps[i])
               else
                  dep_on_v = de_exceps[string(var)]
               end
               break
            end
         end
         for i in 1:lastindex(dep_on_v)
            if (!startswith(dep_on_v[i], "(RT_"))
               ne = ne + 1
            end
         end
      end
   end
   return ne
end

function write_usage_graph(sa, sn, si, ai, f)
   sys_vars = states(sa[si])
   sys_eqs = equations(sa[si])
   sys_eq_v_deps = equation_dependencies(sa[si])
   de_exceps = dep_exceptions()
   for var in sort(sys_vars, by=x -> string(x))
      desc = ModelingToolkit.getdescription(var)
      if (desc != "" && !startswith(desc, "LV functions") && !startswith(desc, "RT functions"))
         dep_on_v = []
         for i in 1:lastindex(sys_eqs)
            if (is_lhs_var(var, sys_eqs[i]))
               if (get(de_exceps, string(var), "") == "")
                  dep_on_v = string.(sys_eq_v_deps[i])
               else
                  dep_on_v = de_exceps[string(var)]
               end
               break
            end
         end
         acronym = replace(string(var), "(t)" => "")
         for i in 1:lastindex(dep_on_v)
            if (!startswith(dep_on_v[i], "(RT_"))
               va = replace(dep_on_v[i], "(t)" => "")
               write(f, string(ai[acronym]), ",", string(ai[va]), "\n")
            end
         end
      end
   end
end

function fig_e4a(sol, tit; kwargs...)
   @variables t
   @named cli = Climate.climate()
   @named pop = Population.population()
   @named dem = Demand.demand()
   @named wel = Wellbeing.wellbeing()

   variables = [
      (wel.AWBI, 0, 4, "Average WellBeing Index"),
      (dem.INEQ, 0, 1, "Inequality"),
      (cli.OW, 0, 4, "Observed warming"),
      (pop.POP, 0, 10000, "Population"),
      (pop.GDPP, 0, 60, "GDP per person"),
      (wel.STE, 0, 4, "Social tension"),
   ]

   return WorldDynamics.plotvariables(sol, (t, 1980, 2100), variables; title=tit, kwargs...)
end
