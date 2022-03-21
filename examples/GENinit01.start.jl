
EIN = (
    ("transformer.X.ix", [0.0, 0.0]),
    ("synUnit.SM.Psi", [1.0, 0.0]),
    ("synUnit.SM.Psi1", [1.0, 0.0]),
    ("synUnit.SM.phiKR", 0.0), 
    ("synUnit.SM.Psifd", 1.20), 
    ("synUnit.exciter.transducer.x", 1.0), 
    ("synUnit.exciter.PI1.Integr.x", 0.0), 
    ("synUnit.exciter.PI1f.x", 0.0), 
    ("synUnit.exciter.PT1a.Integr.x", 0.0),
    (:VEXC, 1.01),
    (:LOAD, 0.5),
)



AUS = (
#     ("der(transformer.X.ix)", [0.0, 0.0]),
    ("der(synUnit.SM.Psi)", [0.0, 0.0]),
    ("der(synUnit.SM.Psi1)", [0.0, 0.0]),
    ("der(synUnit.SM.Psifd)", 0.0),
    ("der(synUnit.exciter.transducer.x)", 0.0), 
    ("der(synUnit.exciter.PI1.Integr.x)", 0.0), 
    ("der(synUnit.exciter.PI1f.x)", 0.0), 
    ("der(synUnit.exciter.PT1a.Integr.x)", 0.0),
    ("der(J.w)", 0.0),
    ("meterGEN.powerRe", 0.8),
    ("meterGEN.powerIm", 0.3),
    ("transformer.X.derINI1", 0.0),
    ("transformer.X.derINI2", 0.0),

)

