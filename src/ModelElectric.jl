
module Electric

using Modia


Pin = Model(
    v = potential,
    i = flow
)

OnePort = Model(
    p = Pin,
    n = Pin,
    equations = :[
        v = p.v - n.v
        0 = p.i + n.i
        i = p.i ],
)


ConstantVoltage = OnePort | Model( 
    V = 1.0, 
    equations = :[ v = V ] )


VarVoltage = OnePort | Model( 
    V = Var(input=true, start=1.0),
    equations = :[v = V] )


Ground = Model(
    p = Pin, 
    equations = :[ p.v = 0.0] )



end



