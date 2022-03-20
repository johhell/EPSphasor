
module Controller

using Modia
using Modia.StaticArrays


# Single-Input-Single-Output continuous control block
SISO = Model(
    u = input,
    y = output
)

# Gain
Gain = SISO | Model(
    k = 1.0,
    equations = :[
        y = k*u ]
)

# First-order transfer function block (= 1 pole)
FirstOrder = SISO | Model(
    k = 1.0,
    T = 1.0,
    x = Var(init=0.0),
    equations = :[
        der(x) = (k * u - x) / T
        y = x 
    ]
)

# Integrator
Integrator = SISO | Model(
    k = 1.0,
    x = Var(init=0.0),
    equations = :[
        der(x) = k * u
        y = x
    ]
)

# VoltagePin = Model(
#     vRe = potential,
#     vIm = potential,
# )

VoltagePin = Model(
    v = Var(potential=true, start= [0.0, 0.0]),
)


"""
function ComplexMulti(vRe::Float64,vIm::Float64, Thetap::Float64)::Float64

y = abs(V * exp(J Theta))

"""
function ComplexMulti(vRe::Float64,vIm::Float64, Kp::Float64, Thetap::Float64)::Float64
    return Kp*abs(Complex(vRe,vIm) * exp(Thetap*1.0im))
end


using LinearAlgebra


#FIXME
#FIXME
#FIXME
function Betrag1(A::Vector{Float64}):: Float64
    return norm(A)
end

function Betrag1(A::SVector{2}):: Float64
    return norm(A)
end


GENvolts = Model(   # für IEEE exciter model ; Xl = 0, Kii = 0 -> siehe Beispiel Parameterliste ST8C
    Kp = 1.0,
    Thetap = 0.0,
    vT = VoltagePin,
    y = output,
    equations = :[
#         y = ComplexMulti(vT.vRe, vT.vIm, Kp, Thetap)
        y = Kp* Controller.Betrag1(vT.v)
    ]
)


"""
# IEEEpart = Model()
Partial model with transducer and sum
interface: Verror

"""
IEEEpart = Model(
    vT = VoltagePin,    # Complex GEN volts

    TR= 0.0226,     # Regulator input filter time constant
    vS = input,     # PSS in
    vREF = input,   # setpoint in
    vGEN = input,   # GEN volts
    iFD = input,    # field current
    y = output,     # EXC out

    transducer = FirstOrder | Map(T=:TR, k=1.0, x=Var(init=1.0)),

    equations = :[
        transducer.u = vGEN
        Verror = vREF+vS-transducer.y
    ]
)



PInonwindup = SISO | Model(    # NO state events !!
    Ki = 1.0, 
    Kp = 1.0,
    A = -5.0,   # min
    B = 5.0,    # max
    limitA = Boolean | Map(init=false),
    limitB = Boolean | Map(init=false),    
    Integr = Integrator | Map(k=1.0),    
    equations = :[
        addy = u*Kp + Integr.y
        limitA = (addy<A)
        limitB = (addy>B)
        Integr.u = if  (limitA || limitB) ; 0.0; else; u*Ki; end;
        y = if limitB; B; elseif limitA; A; else; addy; end;
    ]
)


PInonwindup0 = SISO | Model(    # NO state events !!
    Kp = 1.0,
    Ki = 1.0, 
    A = -5.0,   # min
    B = 5.0,    # max
    Integr = Integrator | Map(k=1.0),
    equations = :[
        Integr.u =  u*Ki
        y = u*Kp + Integr.y
    ]
)




"""
# PT1nonwindup = SISO | Model()

Keine state machine möglich.
### temp. Lösung
wenn obere Grenze erreicht (B) dann `Integr.u=1e-10` , damit Grenze nicht unterschritten wird. `Integr.y` kann sich in der Simulation etwas ändern, und damit könnte Grenze unterschritten werden.
"""
PT1nonwindup = SISO | Model(    # NO state events !!
    K = 1.0,
    T = 0.5,
    A = -5.0,   # min
    B = 5.0,    # max
    limitA = Boolean | Map(init=false),
    limitB = Boolean | Map(init=false),

    Integr = Integrator | Map(k=:(1.0/T)),
    equations = :[
        Integr.u = if (limitA || limitB); null; else; feedback; end;
        null = limitA ? -1e-10 : 1e-10
        feedbackPOS = feedback>0.0
        limitA = (Integr.y<A) && !feedbackPOS
        limitB = (Integr.y>B) && feedbackPOS
        feedback = u - Integr.y
        y = Integr.y * K
    ]
)


PT1nonwindup0 = SISO | Model(    # NO state events !!
    K= 1.0,
    T = 0.5,
    A = -5.0,   # min
    B = 5.0,    # max

    Integr = Integrator | Map(k=:(1.0/T)),
    equations = :[
        Integr.u = u - Integr.y
        y = Integr.y * K
    ]
)



"""
# ExcCONST = IEEEpart | Model()
Konstante Erregung. `y = vREF + vS`

"""
ExcCONST = IEEEpart | Model(
    vS = Var(), 
    equations = :[
        y = vREF + vS
    ]
)




"""
# ExcST8C = IEEEpart | Model()
IEEE ST8C model


"""
ExcST8C = IEEEpart | Model(

    TR= 0.0226,         # Regulator input filter time constant
    Kp = 6.3,           # Potential circuit (voltage) gain coefficient
    Thetap = 0.0,       # Potential circuit phase angle (degrees)

    VPImin = 0.0,       # Minimum voltage regulator output
    VPImax = 1.8,       # Maximum voltage regulator output
    Kpr = 10.9,         # Voltage regulator proportional gain
    Kir = 14.29,        # Voltage regulator integral gain

    Kf = 0.452,         # Exciter field current feedback gain	// airgap base
    Tf = 0.005,         # Field current feedback time constant

    VAmin = -0.866,     # Minimum field current regulator output
    VAmax =  0.996,     # Maximum field current regulator output
    Kpa = 4.0,          # Field current regulator proportional gain
    Kia = 0.0,          # Field current regulator integral gain

    VRmin = -0.866,     # Minimum field current regulator output ??
    VRmax =  0.966,     # Maximum field current regulator output ??
    Ka = 1.0,           # Field current regulator proportional gain ??
    Ta = 0.0033,        # Controlled rectifier bridge equivalent time constant

    SW1 = true,         # Power source selector, A if true (from Gen voltage)

#TODO KEINE state events ==> VIEL SCHNELLER
    PI1 = PInonwindup | Map(A = :VPImin, B = :VPImax, Ki = :Kir, Kp = :Kpr),
    PIa = PInonwindup | Map(A = :VAmin,  B = :VAmax,  Ki = :Kia, Kp = :Kpa),
    PI1f = FirstOrder | Map(T=:Tf, k=:Kf),
    PT1a = PT1nonwindup | Map(A = :VRmin, B = :VRmax, K = :Ka, T = :Ta),   
    genVolts = GENvolts | Map(Kp = :Kp, Thetap = :Thetap),

    equations = :[
        PI1.u = Verror
        PI1f.u = iFD
        PIa.u = PI1.y - PI1f.y
        PT1a.u = PIa.y
        y = if SW1; genVolts.y *PT1a.y; else; Kp*PT1a.y; end;
        ],

    connect = :[
         (vT, genVolts.vT)
    ]

)


end
