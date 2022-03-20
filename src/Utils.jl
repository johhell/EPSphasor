using JSON
using OrderedCollections: OrderedDict
using DataStructures
using Printf
using StaticArrays
import YAML

    
########################################################

logData = false

function ReadDataSet(filename::String)
    if logData
        printstyled("     Datafile: ", color=:green)
        printstyled(filename,"\n", color=:white)
    end
    
    if uppercase(filename[end-3:end]) == "JSON"
        f = open(filename, "r")
        dicttxt = read(f,String)
        close(f)
        DataDict=JSON.parse(dicttxt, dicttype=DataStructures.OrderedDict)
    elseif uppercase(filename[end-3:end]) == "YAML"
        DataDict = YAML.load_file(filename)
    else
        error("AUS und AUS")
    end

    setDict = OrderedDict{String, Any}()

    # OrderedDict für Reihenfolge wie in der Datei
    isZONE = DataDict["description"]["type"]=="ZONEdata"
    for (key, value) in DataDict
        if key=="description"; continue;    end
        valueDict = OrderedDict{Symbol, Any}()
        setDict[key] = valueDict
        for (key1, value1) in value
            valueDict[Symbol(key1)] = value1
        end
        if logData        
            printstyled("  data set ID: ", color=:cyan)
            printstyled(key,"  ", color=:white)
            printstyled("(Prj: ",valueDict[:Project],")\n", color=:light_black)
        end
#         println()
        if isZONE
             valueDict[:Omegarated] = valueDict[:frated]*2.0*pi
             valueDict[:Speedrad] = valueDict[:Omegarated]/valueDict[:NoPolepairs]
             valueDict[:Irated] = valueDict[:Srated]/valueDict[:Vrated]/sqrt(3.0)
             valueDict[:Zbase] = valueDict[:Vrated]*valueDict[:Vrated]/valueDict[:Srated]
             valueDict[:Tbase] = valueDict[:Srated]/valueDict[:Speedrad]
             valueDict[:Speedrpm] = valueDict[:frated]*60.0/valueDict[:NoPolepairs]
        end
        valueDict[:_class] = :Map
    end
    println()
    return setDict
end

########################################################


function Ergebnis(tttt, liste::Vector{String})
    printstyled(lpad("[signal name]",21), color=:light_green)
    printstyled("      [1]", color=:green)
    printstyled("    [end]", color=:cyan)
    printstyled("     [min : max] \n", color=:light_yellow)
    for w in liste
        if !haskey(tttt.result_info, w) && !haskey(tttt.evaluatedParameters, Symbol(w))
            printstyled(lpad(w,21),"\n", color=:red)
            continue
        end
        daten = get_result(tttt,w)
        L1 = length(daten)
        L2 = length(daten[1])        
        RES = Array{Float64,2}(zeros(L1,L2))    # für MIN/MAX notwendig.
        for i = 1:L1
            for j = 1:L2
                RES[i,j] = daten[i][j]
            end
        end

        if L2 == 1
            printstyled(lpad(w,21), color=:light_green)
            printstyled(@sprintf("  %7.4g",RES[1]), color=:green)
            printstyled(@sprintf("  %7.4g",RES[end]), color=:cyan)
            printstyled(@sprintf("  %7.4g :%7.4g\n",minimum(RES),maximum(RES)), color=:light_yellow)
        else
            for iz =1:L2
                printstyled(lpad(w*"[$iz]",21), color=:light_green)
                printstyled(@sprintf("  %7.4g",RES[1,iz]), color=:green)
                printstyled(@sprintf("  %7.4g",RES[end,iz]), color=:cyan)
                printstyled(@sprintf("  %7.4g :%7.4g\n",minimum(RES,dims=1)[iz],maximum(RES,dims=1)[iz]), color=:light_yellow)
            end

        end
    end
end


function ergebnis(tttt, w::String)
    if length(w)==0
    else
        daten = get_result(tttt,w)
        datenlg = length(daten[1])
        if datenlg == 1
            printstyled(lpad(w,21), color=:light_green)
            printstyled(@sprintf("  %7.4g",daten[1]), color=:green)
            printstyled(@sprintf("  %7.4g",daten[end]), color=:cyan)
            printstyled(@sprintf("  %7.4g :%7.4g\n",minimum(daten),maximum(daten)), color=:light_yellow)
        else
            for iz =1:datenlg
                printstyled(lpad(w*"[$iz]",21), color=:light_green)
                printstyled(@sprintf("  %7.4g",daten[1][iz]), color=:green)
                printstyled(@sprintf("  %7.4g",daten[end][iz]), color=:cyan)
                printstyled("      coming soon\n", color=:light_black)
#                 printstyled(@sprintf("  %7.4g :%7.4g\n",minimum(daten[:][iz]),maximum(daten[:][iz])), color=:light_yellow)
            end

        end
    end
end



function Speichern(mod, liste::AbstractArray= [])

    datei = "myfile.txt"
    if length(liste)==0
        printstyled("Länge der Liste = 0!!\n", color=:red)
        return
    end
    df=get_result(mod)
    open(datei, "w") do io
        show(io, MIME("text/csv"), df[!,liste])
        printstyled(@sprintf("save CSV in file: %s with %d colums, %s rows\n",datei, length(liste),nrow(df)), color=:green)
    end
end




function TemplateInit(instModel; tempName="Start.Template.jl")::Nothing

    function StartWert(wert::Float64)::String
        return string(wert)
    end

    function StartWert(wert::SVector{2, Float64})::String   #FIXME Länge 2 ist angenommen
        w = "["
        lg = length(wert.data)
        for i= 1:lg
            w = w * string(wert.data[i]) 
            if i<lg
                w = w * ", "
            end
        end
        w = w * "]"
        return w
    end

    Etxt = "EIN = (\n"
    Atxt = "AUS = (\n"

    for Z in instModel.equationInfo.x_info

        TXT1 = "    (\"$(Z.x_name)\", " * StartWert(Z.startOrInit) * " ),\n"
        if Z.scalar
            TXT2 = "    (\"$(Z.der_x_name)\", 0.0),\n"
        elseif Z.length==2
            TXT2 = "    (\"$(Z.der_x_name)\", [0.0, 0.0]),\n"
        else
            printstyled("ERROR - $(Z_xname)  length >2\n", color=:red)
        end
        Etxt = Etxt * TXT1
        Atxt = Atxt * TXT2
    end



    Etxt = Etxt * ")\n\n\n"
    Atxt = Atxt * ")\n"

    Ausgabe = ""

    open(tempName, "w") do io
        print(io, Etxt)
        print(io, Atxt)
    end

    nothing

end
