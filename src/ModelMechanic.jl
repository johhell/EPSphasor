module Mechanic

using Modia


Flange = Model(
    phi = potential,
    tau = flow
)

Fixed = Model(
    flange = Flange,
    equations = :[
        flange.phi = 0.0]
)


PU2Abs = Model(
    flange_pu = Flange,
    flange_SI = Flange,
    Speedrad = 1.0,
    Tbase = 1.0,
    NoPolepairs = 1,
    speedpu = Var(),
    mechpower = Var(),
    mechPower = Var(),
    equations = :[
        flange_SI.phi = Speedrad * flange_pu.phi
        0.0 = Tbase * flange_pu.tau + flange_SI.tau
        speedpu = der(flange_pu.phi)
        mechpower = flange_pu.tau * speedpu
        mechPower = mechpower * Tbase * Speedrad
    ]
)


Inertia = Model(
    flange_a = Flange,
    flange_b = Flange,
    J = 1.0,
    phi = Var(start=0.0),
    w = Var(),
    equations = :[
        phi = flange_a.phi
        phi = flange_b.phi
        w = der(phi)
        a = der(w)
        J * a = flange_a.tau + flange_b.tau ]
)


end
