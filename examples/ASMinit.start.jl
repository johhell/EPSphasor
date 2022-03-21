EIN = (
    ("asmUnit.Psi1", [0.0, -1.0] ),
    ("asmUnit.Psi2", [0.3, -0.9] ),
    ("transformer.X.ix", [0.0, 0.0] ),
    ("J.w", 1.0),
    (:LOAD, 0.5),
    
)


AUS = (
    ("der(asmUnit.Psi1)", [0.0, 0.0]),
    ("der(asmUnit.Psi2)", [0.0, 0.0]),
#     ("der(transformer.X.ix)", [0.0, 0.0]),  vector init coming soon
    ("der(J.w)", 0.0),
    ("transformer.X.derINI1", 0.0),
    ("transformer.X.derINI2", 0.0),
    ("meterGRID.powerRe", -0.8),
    
)
