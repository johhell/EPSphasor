import  NLsolve

using TimerOutputs
using Test
using Modia: SimulationOptions, emptyResult!, derivatives!, timeEventCondition!, affectTimeEvent!, outputs!,  reinitEventHandler, propagateEvaluateAndInstantiate!, eventIteration!, get_xe, hasParticles, resizeLinearEquations!, updateEquationInfo!


using Modia
using DataFrames





#***************************************************************************************
#***************************************************************************************
#***************************************************************************************

printstyled("!!override!!  function Modia.init!  -- VECTOR 'SIM8.jl'\n",color=:light_yellow)

#NEU
function Modia.init!(m::SimulationModel{FloatType,TimeType})::Bool where {FloatType,TimeType}
    emptyResult!(m)
    eh = m.eventHandler
    reinitEventHandler(eh, m.options.stopTime, m.options.logEvents)
    eh.firstInitialOfAllSegments = true

	# Apply updates from merge Map and propagate/instantiate/evaluate the resulting evaluatedParameters
    if length(m.options.merge) > 0
        m.parameters = mergeModels(m.parameters, m.options.merge)
        m.evaluatedParameters = propagateEvaluateAndInstantiate!(FloatType, m.unitless, m.modelModule, m.parameters, m.equationInfo, m.previous_dict, m.previous, m.pre_dict, m.pre, m.hold_dict, m.hold)
        if isnothing(m.evaluatedParameters)
            return false
        end

        # Resize linear equation systems if dimensions of vector valued tearing variables changed
        resizeLinearEquations!(m, m.options.log)

        # Resize state vector memory
        m.x_start = updateEquationInfo!(m.equationInfo, FloatType)
        nx = length(m.x_start)
        resize!(m.x_init, nx)
        resize!(m.der_x, nx)
        eqInfo = m.equationInfo
        m.x_vec = [zeros(FloatType, eqInfo.x_info[i].length) for i in eqInfo.nxFixedLength+1:length(eqInfo.x_info)]
    end

    # Initialize auxiliary arrays for event iteration
    m.x_init .= 0
    m.der_x  .= 0

    # Log parameters
    if m.options.logParameters
        parameters = m.parameters
        @showModel parameters
    end
    if m.options.logEvaluatedParameters
        evaluatedParameters = m.evaluatedParameters
        @showModel evaluatedParameters
    end

    if m.options.logStates
        # List init/start values
        x_table = DataFrames.DataFrame(state=String[], init=Any[], unit=String[], nominal=Float64[])
        for xe_info in m.equationInfo.x_info
            xe_init = get_xe(m.x_start, xe_info)
            if hasParticles(xe_init)
                xe_init = string(minimum(xe_init)) * " .. " * string(maximum(xe_init))
            end
            push!(x_table, (xe_info.x_name, xe_init, xe_info.unit, xe_info.nominal))
        end
        show(stdout, x_table; allrows=true, allcols=true, rowlabel = Symbol("#"), summary=false, eltypes=false)
        println("\n")
    end

    # Initialize model, linearEquations and compute and store all variables at the initial time
    if m.options.log
        println("      Initialization at time = ", m.options.startTime, " s")
    end

    # Perform initial event iteration
    m.nGetDerivatives = 0
    m.nf = 0
    m.isInitial   = true
    eh.initial    = true
#    m.storeResult = true
#    m.getDerivatives!(m.der_x, m.x_start, m, startTime)
#    Base.invokelatest(m.getDerivatives!, m.der_x, m.x_start, m, startTime)
    for i in eachindex(m.x_init)
        m.x_init[i] = deepcopy(m.x_start[i])
    end


##------NEUNEU------------------------------------------------------------------------------


ListeEIN = Dict{String, Any}()
ListeAUS = Dict{String, Any}()

for info in m.equationInfo.x_info
    ListeEIN[info.x_name] = info
    ListeAUS[info.der_x_name] = info
end



startValue = Vector{Float64}()
inputIndex = Vector{Any}()

logINITvalues = false

function report(txt::String, color::Symbol)
    if logINITvalues
        printstyled(txt, color=color)
    end
end

report("\nINPUT values\n", :blue)
for ein in EIN
    if haskey(ListeEIN, ein[1])
        rec = ListeEIN[ein[1]]
        if rec.scalar
            report("\t STATE scalar : $(ein[1])\n", :green)
            push!(inputIndex, rec.startIndex)
            push!(startValue, ein[2])
        else
            report("\t STATE vector : $(ein[1]) \n", :light_green)
            for i = 1:rec.length
                push!(inputIndex, rec.startIndex+i-1)
                push!(startValue, ein[2][i])   # keine Prüfung der Länge
            end
        end
    elseif haskey(m.parameters, Symbol(ein[1]))
        report("\t         PARA : $(ein[1])\n", :cyan)
        push!(startValue, ein[2])
        push!(inputIndex, Symbol(ein[1]))
    else
        printstyled("\tnicht gefunden: $(ein[1])\n", color=:red)
    end
end

if logINITvalues
    @show length(inputIndex)
    @show inputIndex
    @show startValue
end


targetIndex = Vector{Int64}()
targetValue = Vector{Float64}()

#TODO
#TODO Überprüfung der Länge bei vec
#TODO

#INFO  INdex negativ für OUTPUT target

report("\nTARGET values\n", :blue)
for aus in AUS
    if haskey(ListeAUS, aus[1])
        rec = ListeAUS[aus[1]]
        if rec.scalar
            report("\t STATE scalar : $(aus[1])\n", :green)
            push!(targetIndex, rec.startIndex)
            push!(targetValue, aus[2])
        else
            report("\t STATE vector : $(aus[1])\n", :light_green)
            for i = 1:rec.length
                push!(targetIndex, rec.startIndex+i-1)
                push!(targetValue, aus[2][i])   # keine Prüfung der Länge
            end
        end
    elseif haskey(m.result_info, aus[1])
        report("\t       RESULT : $(aus[1])\n", :cyan)
        push!(targetIndex, -m.result_info[aus[1]].index)
        push!(targetValue, aus[2])
    else
        printstyled("\tnicht gefunden: $(aus[1])\n", color=:red)
    end

end

if logINITvalues
    @show length(targetIndex)
    @show targetIndex
    @show targetValue
end


function fromSolver2State!(m, Xsolver, Xstate)

    for (i,w) in enumerate(inputIndex)
        if typeof(w) == Symbol
            m.evaluatedParameters[w] = Xsolver[i]
        else
            Xstate[w] = Xsolver[i]
        end
    end
end


function fromState2Solver!(m, Xstate,resi)

    allVars= pop!(m.init_vars)
    for (i,t) in enumerate(targetIndex)
        if t>0 # state
            resi[i] = Xstate[t] - targetValue[i]
        else
            V = allVars[-t]  # Zielwert
            resi[i] = V - targetValue[i]
        end
    end
end


#------------------------------

        TSTART = m.options.startTime

        solver0 = Vector{Float64}(startValue)
        state0 = vec(deepcopy(m.x_init))
        fromSolver2State!(m, solver0, state0)
        resid = similar(state0)
        derivatives!(resid,state0,m,TSTART)

        Lu = []
        Ldu = []
        stateU = Array{Float64,1}(state0)
        statedU =Array{Float64,1}(zeros(length(m.x_init)))

        function F!(residual,solverU)
            fromSolver2State!(m, solverU, stateU)
            derivatives!(statedU,stateU,m, TSTART)
            fromState2Solver!(m, statedU, residual)
        end


        m.storeInit = true
        RES = NLsolve.nlsolve(F!,solver0, iterations=100, xtol = 0.0, ftol=1e-8, method=:newton, show_trace=false)
        if !NLsolve.converged(RES)
            @show RES
            error("!NLsolve.converged(RES)")
        end

        if logINITvalues
            @show RES
        else
            printstyled("Initialization: Function Calls (f): $(RES.f_calls) \n",color=:light_blue)
        end
        
        fromSolver2State!(m, RES.zero,stateU)
        m.storeInit = false


        m.nf = 0    # reset
        m.x_init = copy(stateU)


##-Ende -----NEUNEU--------------------------------------------------------------------------



    eventIteration!(m, m.x_init, m.options.startTime)
    m.success     = false   # is set to true at the first outputs! call.
    eh.initial    = false
    m.isInitial   = false
    m.storeResult = false
    eh.afterSimulationStart = true
    return true
end






#***************************************************************************************
#***************************************************************************************
#***************************************************************************************


