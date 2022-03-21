# 

module EPSphasor

include("ModelController.jl")
include("ModelMechanic.jl")
include("ModelElectric.jl")

using Modia
using Modia.StaticArrays



#**************************************************************************
#------------------

function MultiJ(A::SVector{2})::SVector{2}
    # return = A * J
    return [-A[2], A[1]]
end

#------------------

function Betrag(A::SVector{2}):: Float64
    return sqrt(A[1]*A[1]+A[2]*A[2])
end

function Betrag(A::Vector{Float64}):: Float64
    return sqrt(A[1]*A[1]+A[2]*A[2])
end

#------------------TODO ???

function MultiAconjB(A::SVector{2}, B::Vector{Float64})::SVector{2}
    # ret = A * conj(B)
    return [A[1]*B[1]+A[2]*B[2], -A[1]*B[2]+A[2]*B[1]]
end

function MultiAconjB(A::Vector{Float64}, B::SVector{2})::SVector{2}
    # ret = A * conj(B)
    return [A[1]*B[1]+A[2]*B[2], -A[1]*B[2]+A[2]*B[1]]
end

function MultiAconjB(A::SVector{2}, B::SVector{2})::SVector{2}
    # ret = A * conj(B)
    return [A[1]*B[1]+A[2]*B[2], -A[1]*B[2]+A[2]*B[1]]
end


#------------------TODO ???

function MultiAB(A::SVector{2}, B::Vector{Float64})::SVector{2}
    # ret = A * B
    return [A[1]*B[1]-A[2]*B[2], A[1]*B[2]+A[2]*B[1]]
end


function MultiAB(A::SVector{2}, B::SVector{2})::SVector{2}
    # ret = A * B
    return [A[1]*B[1]-A[2]*B[2], A[1]*B[2]+A[2]*B[1]]
end

function MultiAB(A::Vector{Float64}, B::Vector{Float64})
    # ret = A * B
    return [A[1]*B[1]-A[2]*B[2], A[1]*B[2]+A[2]*B[1]]
end

#------------------


PinVector = Model(
    v = Var(potential=true, start= SVector{2}(0.0, 0.0)),
    i = Var(flow=true, start= SVector{2}(0.0, 0.0)),
)



OnePin = Model( 
    p = PinVector,
    Omegarated=outer,
    wReference=outer,
    amps = Var(start=SVector{2}(0.0, 0.02)),
    volts = Var(start=SVector{2}(1.0, 0.01)),
    
    equations = :[
        volts = p.v
        amps = p.i
    ]
)



TwoPin = Model(
    p = PinVector,
    n = PinVector,
    Omegarated=outer,
    wReference=outer,
    volts = Var(start=SVector{2}(0.0, 0.0)),
    amps = Var(start=SVector{2}(0.0, 0.0)),
    Zero2 = parameter | SVector{2}(0.0, 0.0),

    equations = :[
        volts = p.v - n.v
        p.i + n.i = Zero2
        amps = p.i 
    ],
)



Resistor = TwoPin | Model(
    r = 1.11,
    equations = :[
        volts = r*amps
    ]
)


GroundVec = OnePin | Model(
    equations = :[
        volts =  [0.0, 0.0]
    ]
)


VoltageSource = TwoPin | Model(
    V = input | Map(start=1.0),
    w=Var(),
    rad=Var(start=0.0),
    equations = :[
        w=Omegarated*(1.0-wReference)
        w=der(rad)
        volts = V*[cos(rad), sin(rad)]
    ]
)

#=  MODELICA
  volts = x * (Complex(der(ix.re), der(ix.im)) / Omegarated + J * wReference * ix);
  volts = iparallel * rparallel;
  amps = iparallel + ix;

initial equation
  if SteadyState then
      der(ix.re)/Omegarated  + (wStart - wReference) * ix.im  = 0.0; 
      der(ix.im)/Omegarated  - (wStart - wReference) * ix.re  = 0.0;
   end if;
=#

Reactor = TwoPin | Model(
    x = 0.1,
    rparallel = parameter | Map(value=:(1000.0*x)), #TODO  Angenommen - für Übertragunsfunktion stabiler !!
    ix = Var(start=SVector{2}(0.0, 0.0)),
    equations = :[
        volts = x* (derIX + wReference * EPSphasor.MultiJ(ix) )
        volts = rparallel * ir
        amps = ix + ir
        derIX = der(ix)/Omegarated
        derINI1 = derIX[1] + (1.0 - wReference) * ix[2]
        derINI2 = derIX[2] - (1.0 - wReference) * ix[1]
    ]
)

#=  MODELICA
equation
  amps * b = Complex(der(volts.re), der(volts.im)) / localPARA.Omegarated + J * wReference * volts;

initial equation
  if SteadyState then
    der(volts.re)  + (localPARA.wStart - wReference) * volts.im * localPARA.Omegarated = 0.0;
    der(volts.im)  - (localPARA.wStart - wReference) * volts.re * localPARA.Omegarated = 0.0;
  end if;
=#

Capacitor = TwoPin | Model(
    b = 3.0,
    equations = :[
        amps*b = derV + wReference*EPSphasor.MultiJ(volts)
        derV = der(volts)/Omegarated
        derINI1 = derV[1] + (1.0-wReference) * volts[2]
        derINI2 = derV[2] - (1.0-wReference) * volts[1]
    ]
)


Meter = TwoPin | Model( 
    Srated = 100.0e6,
    Vrated = 15.0e3,
    Irated = parameter | Map(value=:(Srated/Vrated/sqrt(3.0))),
    power = Var(start=SVector{2}(0.0, 0.0)),
    equations = :[
        volts =  Zero2
        current = EPSphasor.Betrag(amps)
        voltage = EPSphasor.Betrag(p.v)
        power = EPSphasor.MultiAconjB(p.v, amps)
        powerRe = power[1]
        powerIm = power[2]
        Voltage = voltage * Vrated
        Current = current * Irated
        PQ = power * Srated
        S = EPSphasor.Betrag(PQ)
    ]
)



##################################


TransformerIdeal = Model(
    ratio=1.0,
    pin1 = PinVector,
    pin2 = PinVector,
    equations = :[
        pin1.v = ratio * pin2.v
        pin1.i * ratio = -pin2.i
    ]
)


Transformer = Model(
    Srated = 100.0e6,
    Strafo = 100.0e6,
    xt = 0.1,
    rt = 0.1 / 40,
    ratio = 1.0,
    rFe = 1000.0,   #TODO besser sind core losses
    Omegarated=Var(_outer=true, _inner=true),
    wReference=Var(_outer=true, _inner=true),
    pin1 = PinVector,
    pin2 = PinVector,
    X = Reactor | Map(x= :(xt*Srated/Strafo)),
    R = Resistor| Map(r = :(rt*Srated/Strafo)),
    trafoIdeal = TransformerIdeal | Map(ratio = :(ratio)),
    RFe = Resistor | Map(r = :(rFe *Srated / Strafo)),
    Gnd = GroundVec,
    connect = :[
        (pin1, trafoIdeal.pin1)
        (trafoIdeal.pin2, R.p)
        (R.n, X.p, RFe.p)
        (X.n, pin2)
        (Gnd.p, RFe.n)
    ]
)


#########################################


MachinePart = OnePin | Model(
    Flange_a = Mechanic.Flange,
    Flange_b = Mechanic.Flange,
    power = Var(start=SVector{2}(0.0, 0.0)),
    
    # mech interface
    equations = :[
        phi = Flange_a.phi - Flange_b.phi
        tau = Flange_a.tau
        tau = -Flange_b.tau
        der(phi) = w
        powerMech = w * tau
        current = EPSphasor.Betrag(amps)
        voltage = EPSphasor.Betrag(volts)
        power = EPSphasor.MultiAconjB(volts, amps)
    ]
)



SynchrPart = MachinePart | Model(
    Omegarated=Var(_outer=true, _inner=true),
    wReference=Var(_outer=true, _inner=true),
    ra = 0.0024,
    xd = 1.186,
    xq = 0.699,
    xl = 0.1165,
    r1d = 0.0171,
    r1q = 0.011,
    x1d = 0.2981,
    x1q = 0.1165,
    xad = parameter | Map(value=:(xd - xl)),
    xaq = parameter | Map(value=:(xq - xl)),
    xadq = parameter | Map(value=:([xad  0.0; 0.0  xaq])),
    r1dq = parameter | Map(value=:([r1d  0.0; 0.0  r1q])),
    x1dq = parameter | Map(value=:([x1d  0.0; 0.0  x1q])),

    Psifd = Var(init=1.234),
    imagn = Var(start=SVector{2}(0.0, 0.0)),
    Psi  = Var(init=SVector{2}(1.0, 0.0)),
    Psi1 = Var(init=SVector{2}(1.0, 0.0)),
    Psim = Var(start=SVector{2}(1.0, 0.0)),
    i = Var(start=SVector{2}(0.0, 0.0)),
    v = Var(start=SVector{2}(0.0, 0.0)),
    i1 = Var(start=SVector{2}(0.0, 0.0)),
    TR = Var(start=SVector{2}(0.0, 0.0)),

    phiKR = Var(start=0.0),
    tau = Var(start = 0.0),
    
    equations = :[
        # reference frame transformation
        der(phiKR) = (w - wReference)*Omegarated
#         TR = [cos(phiKR - PIhalf), sin(phiKR - PIhalf)]
        TR = [sin(phiKR), -cos(phiKR)]  # vereinfacht
        amps = EPSphasor.MultiAB(i, TR)
        volts = EPSphasor.MultiAB(v, TR)

        # flux
        Psi = Psim+i*xl
        Psim = xadq*imagn
        Psi1 = Psim + [Psif1d, 0.0] + x1dq*i1
        #voltage
        v = ra*i + der(Psi)/Omegarated + EPSphasor.MultiJ(Psi)
        
        [0.0, 0.0] = r1dq*i1 + der(Psi1)/Omegarated
        # torque
        tau = -i[2]*Psi[1] + i[1]*Psi[2]
    ],

)



SynchronousMachineNONsat = SynchrPart | Model(

    Plus    = Electric.Pin,
    Minus   = Electric.Pin,

    rfd	= 0.00037,
    xfd	= 0.2181,
    xf1d = 0.0011,

    equations = :[
        # excitation
        imagn = i + i1 + [ifd, 0.0]
        ifd = Plus.i
        Plus.i + Minus.i = 0
        uF = Plus.v - Minus.v

        Psifd = Psif1d + ifd*xfd + xad*imagn[1]
        Psif1d = xf1d * (i1[1]+ifd) 
        uF*rfd/xad = rfd*ifd + der(Psifd)/Omegarated
    ]
)




InductionPart = MachinePart | Model(
    Omegarated=Var(_outer=true, _inner=true),
    wReference=Var(_outer=true, _inner=true),
    x1s = 0.1708,
    x2s = 0.1216,
    xh = 3.2,
    r1 = 0.0139,
    r2 = 0.0117,
    Psi1 = Var(start=SVector{2}(0.0, -1.0)),
    Psi2 = Var(start=SVector{2}(0.3, -0.9)),
    Psim = Var(start=SVector{2}(0.2, -0.9)),
    imagn = Var(start=SVector{2}(0.0,  0.3)),

    equations = :[
        i1 = amps
        u1 = volts
        imagn = i1 + i2
        # flux
        Psim  = xh * imagn
        Psi1 = x1s * i1 + Psim
        Psi2 = Psim + x2s * i2
        # voltages
        u1 = r1*i1 + der(Psi1)/Omegarated  + wReference*EPSphasor.MultiJ(Psi1)
        u2 = r2*i2 + der(Psi2)/Omegarated  + (wReference-w)*EPSphasor.MultiJ(Psi2)
        # torque
        tau = -i1[2]*Psi1[1] + i1[1]*Psi1[2]
    ]
)


InductionMachine = InductionPart | Model(

    equations = :[
        u2 = [0.0, 0.0]
    ]
)


#########################################


SYNunit = Model(

    VoltageREF  = Var(input=true),

    flange = Mechanic.Flange,
    pin = PinVector,

    kRAD = 180.0/pi,

    Omegarated=Var(_outer=true, _inner=true),
    wReference=Var(_outer=true, _inner=true),

    SM = SynchronousMachineNONsat,
    EXC = Electric.VarVoltage,
    Gnd = Electric.Ground,
    exciter = Controller.ExcCONST,
#     exciter = Controller.ExcST8C,
    FIXED= Mechanic.Fixed,

    equations = :[
        exciter.vREF = VoltageREF
        exciter.vGEN = SM.voltage
        exciter.vS = 0.0
        exciter.iFD = SM.ifd
        phiDEG = SM.phiKR*kRAD
        exciter.vT.v = SM.volts
    ],

    connect = :[
        (pin, SM.p)
        (EXC.V, exciter.y)
        (EXC.p, SM.Plus)
        (EXC.n, SM.Minus, Gnd.p)
        (SM.Flange_b, FIXED.flange)
        (SM.Flange_a, flange)
    ]  
)

end   #module
