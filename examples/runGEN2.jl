module MYGENrun2


using Modia
@usingModiaPlot
using StaticArrays



include("../src/Utils.jl")
include("../src/SIM8.jl")


# logData = true

GenDataMap = ReadDataSet("GENdata.yaml")
ZoneDataMap = ReadDataSet("ZONEdata.yaml")
ST8CMap = ReadDataSet("ST8Cdata.yaml")


instModel = Main.MYGEN2.instModel


include("GENinit01.start.jl")

function mySimulation(;SW1="TESTSW1", reuse=false)
    printstyled("\nNEW simulation\n",color=:light_blue)

    simulate!(instModel,
#         IDA(),
        CVODE_BDF(),
        startTime=-0.05,
        stopTime = 1.0,
        interval=2.123e-4,
        tolerance=1e-6,
        log=false,
        logStates=false,
        logEvents=false,
        logTiming = false,
        logParameters    = false,
        logEvaluatedParameters   = false,
        
        merge=Map(  
            transformer = ZoneDataMap["setGEN"],
            meterGEN    = ZoneDataMap["setGEN"],
            synUnit     = Map(exciter = ST8CMap[SW1], SM = GenDataMap["NONsat"]),
            varvolts    = Map(Tstart=1e-3),     # Event muss T>0.0

            # das GEHT NICHT !! J = Map(w=Var(init=38.0)),
            #  instModel.parameters[:J][:w]=39.0
        ),
    )
#     printstyled("total time for simulation: ", color = :yellow)

    

#      plot(instModel, [("synUnit.SM.voltage"), ( "synUnit.exciter.y"), ( "synUnit.SM.ifd")], figure=1)


     plot(instModel, [( "synUnit.exciter.y"),("synUnit.phiDEG")], prefix=ST8CMap[SW1][:Project] *"----", reuse=reuse, figure=1)
#      plot(instModel, [ ("synUnit.SM.tau")], figure=1)
#      plot(instModel, [("synUnit.SM.i"),("GridVolts.volts")], figure=2)
#       plot(instModel, [ ("GridVolts.amps")], figure=2)

end



# open("LOG.txt", "a") do io
#     redirect_stdout(io) do
        mySimulation()
        mySimulation(SW1="TESTSW0", reuse=true)
#     end
# end




Ergebnis(instModel, [
    "VEXC", 
    "LOAD", 
    "meterGRID.power", 
    "meterGEN.power", 
    "synUnit.SM.voltage",
    "synUnit.SM.ifd", 
    "synUnit.exciter.y", 
    "synUnit.phiDEG", 
    "J.w"])


printstyled(length(instModel.result_x[1,:]),"\n", color=:red)


# Speichern(instModel, ["time","synUnit.exciter.y", "synUnit.SM.ifd", "synUnit.SM.tau", "meterGEN.voltage", "meterGEN.current", "meterGRID.voltage", "synUnit.SM.phiKR"])


end
