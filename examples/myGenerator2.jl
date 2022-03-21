module MYGEN2

using Modia


setLogMerge(false)


include("../src/ModelMechanic.jl")
include("../src/ModelEPSphasor.jl")
include("../src/ModelController.jl")


##################################

VarVolts = Model(   # Voltage dip
    Tstart = 0.0,
    dT = 0.15,
    Vmin = 0.0,
    y = output,
    equations = :[ 
        y = if after(Tstart) && !after(Tstart+dT); Vmin else; 1.0 end; 
    ]
)


SMtest = Model(
    Project = parameter | Map(value="HALLO"),
    LOAD = parameter | Map(value=0.777, fixed=false),
    VEXC = parameter | Map(value=1.444, fixed=false),

    wReference= parameter | 1.0 | Var(info = "ref. Frame"),
    Omegarated=100.0*pi,
    
    INtorque   = Var(input=true, value= 0.0, comment="delta Torque"),
    INexc      = Var(input=true, value= 0.0, comment="delta setpoint volt"),
    
    OUTspeed = Var(output=true, comment="synUnit.SM.w"),
# OUT1 = Var(output=true, comment="J.w - ERROR"),   #geht nicht >> J.w ist StateVar
    OUTpower = Var(output=true, comment="meterGEN.powerElRe"),
    OUTvoltage = Var(output=true, comment="meterGEN.voltage"),

    GridVolts  = EPSphasor.VoltageSource,
    GC = EPSphasor.GroundVec,
#     synUnit = EPSphasor.SYNunit,    # = ExcCONST
    synUnit = EPSphasor.SYNunit | Map(exciter = redeclare | Controller.ExcST8C),
    transformer = EPSphasor.Transformer | Map( xt=0.10, rt=0.1/40.0, Strafo=119e6),

    meterGRID   = EPSphasor.Meter,
    meterGEN    = EPSphasor.Meter,
    varvolts    = VarVolts,


    J = Mechanic.Inertia | Map(
        J=3.0,
        w=Var(init=1.0),
        phi=Var(init=0.0),
        ),

    equations = :[
        J.flange_b.tau = LOAD + INtorque
        OUTspeed = synUnit.SM.w
#         OUT1 = J.w # J.w   geht nicht ->  ist State VAR!!
        OUTpower = meterGEN.powerRe
        OUTvoltage = meterGEN.voltage
        synUnit.VoltageREF = VEXC + INexc
#         wReference = synUnit.SM.w
    ],

    connect = :[
        (GridVolts.V, varvolts.y)
        (GridVolts.p, meterGRID.n)
        (meterGRID.p, transformer.pin1)
        (transformer.pin2, meterGEN.n)
        (meterGEN.p, synUnit.pin)
        (synUnit.flange, J.flange_a)
        (GridVolts.n, GC.p)
    ]
)


instModel = @instantiateModel(SMtest, 
    unitless=true,
    log=false,
    logTiming=false,
    logDetails=false,
    logCode=false,
    logStateSelection=false,
#     saveCodeOnFile="CODE.txt",
)




end  # module MYGEN2
