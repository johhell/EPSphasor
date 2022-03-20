# EPSphasor

A system for detailed simulation of **E**lectrical **P**ower **S**ystems with following features:

* variable speed of reference frame. 
* using ONLY per units system


## Installation

### Steady State initialization

Here a modification of `CodeGeneration.jl` is needed. A revised version named `A-CodeGeneration.jl` can be found in folder `system/`



## Examples
The simple example includes the following elements:

* Voltage source
* Transformer
* Synchronous machine (NON saturated)
* Exciter (IEEE ST8A model)
* Inertia

For the speed of the reference frame 3 (practical) options are possible:

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
