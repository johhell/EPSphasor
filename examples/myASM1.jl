module MYASM1

using Modia


setLogMerge(false)


include("../src/ModelMechanic.jl")
include("../src/ModelEPSphasor.jl")


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


ASMtest = Model(
    LOAD = parameter | Map(value=0.0, fixed=false),
    wReference= parameter | 1.0 | Var(info = "ref. Frame"),
    Omegarated=100.0*pi,

    GridVolts   = EPSphasor.VoltageSource,
    GC          = EPSphasor.GroundVec,
    asmUnit     = EPSphasor.InductionMachine,
    transformer = EPSphasor.Transformer | Map( xt=0.10, rt=0.1/40.0, Strafo=119e6),
    meterGRID   = EPSphasor.Meter,
    meterGEN    = EPSphasor.Meter,
    varvolts    = VarVolts | Map(Vmin=0.7),

    FIXED = Mechanic.Fixed,

    J = Mechanic.Inertia | Map(
        J=3.0,
        w=Var(init=0.4),
        phi=Var(init=0.0),
        ),

    equations = :[
        J.flange_b.tau = LOAD
    ],

    connect = :[
        (GridVolts.V, varvolts.y)    
        (GridVolts.p, meterGRID.n)
        (meterGRID.p, transformer.pin1)
        (transformer.pin2, meterGEN.n)
        (meterGEN.p, asmUnit.p)
        (asmUnit.Flange_a, J.flange_a)
        (asmUnit.Flange_b, FIXED.flange)
        
        (GridVolts.n, GC.p)
    ]
)


instModel = @instantiateModel(ASMtest, 
    unitless=true,
    log=false,
    logTiming=false,
    logDetails=false,
    logCode=false,
    logStateSelection=false,
#     saveCodeOnFile="CODE.txt",
)


# include("../src/Utils.jl")
# TemplateInit(instModel)


end  # module MYGEN2
