
# EPSphasor

A system for detailed simulation of **E**lectrical **P**ower **S**ystems with the following features:

* variable speed of reference frame. 
* using ONLY per units system

This approach was implemented in `MODELICA` and successfully used over some years.

## Installation

### Steady State initialization

**Limitations** This is not a general solution for the Initialization problem. The interface to the solver must be defined manually (see below).

Here a modification of `CodeGeneration.jl` is needed. A revised version named `A-CodeGeneration.jl` can be found in folder `system/`

To run steady state initialization the `init!` method is replaced in `SIM8.jl`.
Here only an additional block was included. No other modifications were done.

**The idea behind**

I found only one way to have access to the system of equations. This was the `derivatives!` method. 

As next I created an interface between `derivatives!` and a solver from `NLsolve`.

** file `GENinit01.start.jl`**

In the `EIN` section the input values (with start) can be found. In addition I defined parameters as input (in the example applied torque and voltage set-point for exciter)

In the `AUS` section the output values (with target) can be found. The value of additional targets I found in simulation results (that’s the reason for modification of `CodeGeneration.jl`). In my case the real and reactive power was defined.


```julia
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

```


## Examples
The simple example includes the following elements:

* Voltage source
* Transformer
* Synchronous machine (NON saturated)
* Exciter (IEEE ST8A model)
* Inertia

For the speed of the reference frame practically 3 options are possible:

* Synchronous Speed:
> `wReference= parameter | 1.0 | Var(info = "ref. Frame"),`

* Fixed on Rotor position
> in equations: `wReference = synUnit.SM.w`

* Standstill: Possible, but does not make sense



### Test case: Fault Ride Through

For a time period of `150ms` the grid voltage is reduced to zero.



### Run the example

**create & instantiate the model**: run `myGenerator2.jl`

**simulate** : run `runGEN2.jl`

## Author

- [Johann Hell](mailto:hans.hell@gmx.at)
