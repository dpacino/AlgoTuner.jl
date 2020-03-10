module AlgoTuner

import Random
using Random
using Pkg
# INTERFACE RELATED TYPES AND FUNCTION

rng = MersenneTwister(1234)

@enum TunerVerbosity Silent IncumbentOnly ShowAll ShowDebug

struct FuncParam{T<:Number}
    name::String
    LB::T
    UB::T
end

mutable struct FuncCommand
    cmd::Function
    params::Array{FuncParam,1}
    param_init_vals::Array{Number,1}
end

function createRuntimeCommand(func::Function)
    return FuncCommand(func,[],[])
end

function addParam(::Type{T},func::FuncCommand, name::String, LB::T, UB::T) where {T<:Number}
    if LB >= UB
        error("LB should be smaller than UB")
    end
    push!(func.params, FuncParam(name,LB,UB))
    if typeof(LB)<:Integer
        push!(func.param_init_vals, rand(rng,LB:UB))
    else
        push!(func.param_init_vals, LB+rand(rng)*(UB-LB))
    end
end

addParam(func::FuncCommand, name::String, LB::Float64, UB::Float64) = addParam(Float64,func, name, LB, UB)


function addIntParam(func::FuncCommand, name::String, LB::Integer, UB::Integer)
    addParam(Int64,func,name,LB,UB)
end

function addFloatParam(func::FuncCommand, name::String, LB::Number, UB::Number)
        addParam(Float64,func,name,convert(Float64,LB),convert(Float64,UB))
end

function addInitialValues(func::FuncCommand, values)
    if length(values)!=length(func.params)
        error("The number of initialized parameters should be $(length(func.params))")
    end
    #func.param_init_vals=deepcopy(values)
    for i in 1:length(func.params)
        if typeof(func.params[i].LB)<:Integer
            func.param_init_vals[i]=convert(Int64,values[i])
        else
            func.param_init_vals[i]=convert(Float64,values[i])
        end
    end
end

function runCommand(func::FuncCommand, seed, instance, values)
    return Base.invokelatest(func.cmd, seed, instance, values...)
end

# PARAMETER TUNING FUNCTIONS

function execute(func::FuncCommand, instances::Array{String,1}, paramValues, sampleSize, seeds)
    cost = 0;
    for inst in instances
        sampleCost=0
        for s in 1:sampleSize
            sampleCost+=runCommand(func,seeds[s],inst,paramValues)
        end
        cost+=(sampleCost/sampleSize)
    end
    cost/=length(instances)
    return cost;
end

function randomMoveOperator(func::FuncCommand, parVals)
    #select a parameter at random
    p = rand(rng,1:length(func.params))
    param = func.params[p]
    if rand(rng)>=0.5 #increase value
        if param.pType == IntParam
            return (p,rand(rng,parVals[p]:trunc(Int64,param.UB)))
        else
            return (p,parVals[p]+rand(rng)*(param.UB-parVals[p]))
        end
    else # descrease value
        if param.pType == IntParam
            v =rand(rng,trunc(Int64,param.LB):parVals[p])
            #println(param.LB," ",parVals[p], " -> ",v)
            return (p,v)
        else
            v = param.LB+rand(rng)*(parVals[p]-param.LB)
            #println(param.LB," ",parVals[p], " -> ",v)
            return (p,v)
        end
    end
end

function printParamValues(func::FuncCommand, values)
    println("   |")
    for p in 1:length(func.params)
        println("   |-- $(func.params[p].name) = $(values[p])")
    end
    println("   *")
end

function logIncumbent(timestamp,func::FuncCommand,cost,paramValues,verbosity::TunerVerbosity)
    if verbosity>Silent
        println("AlgoTuner($timestamp) - New incumbent with cost $cost")
        printParamValues(func,paramValues)
    end
end

function logInitIncumbent(timestamp,func::FuncCommand,cost,paramValues,verbosity::TunerVerbosity)
    if verbosity>Silent
        println("AlgoTuner($timestamp) - Start incumbent with cost $cost")
        printParamValues(func,paramValues)
    end
end

function logBestIncumbent(timestamp,func::FuncCommand,cost,paramValues,verbosity::TunerVerbosity)
    if verbosity>=Silent
        println("AlgoTuner($timestamp) - Best incumbent with cost $cost")
        printParamValues(func,paramValues)
    end
end

function logStep(timestamp,func::FuncCommand,paramValues,verbosity::TunerVerbosity)
    if verbosity>=ShowAll
        println("AlgoTuner($timestamp) - Benchmarking with:")
        printParamValues(func,paramValues)
    end
end

function logDebug(timestamp, text, verbosity::TunerVerbosity)
    if verbosity>=ShowDebug
        println("AlgoTuner($timestamp) - $(text)")
    end
end

function logDebug(text, verbosity::TunerVerbosity)
    if verbosity>=ShowDebug
        println("AlgoTuner(debug) - $(text)")
    end
end

function logText(timestamp, text)
    println("AlgoTuner($timestamp) - $(text)")
end


# Expects that func retuns a cost an that the algorithm is minimizing
function tune(func::FuncCommand, instances::Array{String,1},
              timeLimit::Int64, sampleSize::Int64, seeds::Array{Int64,1}, verbosity::TunerVerbosity=ShowAll)

    if length(instances)==0
        error("At least one instance should be passed")
    elseif sampleSize<=0
        error("sampleSize should be positive and preferably between 1 and 10.")
    elseif length(seeds)!=sampleSize
        error("The numbre of seeds must match the sample size")
    elseif timeLimit<=0
        error("timeLimit must be a positive integer.")
    elseif length(func.params)==0
        error("at least one parameter must be added")
    end


    T::Float64=1000
    α::Float64=0.99999999
    τ::Float64=0.01

    t1::Float64=time_ns()
    elapsed_time::Float64=0.0

    #println(read("Project.toml", String))

    #ver="0.1.3"
    logText(elapsed_time,"----------------------------------------------------")
    logText(elapsed_time,"                AlgoTuner ver. $(version())")
    logText(elapsed_time,"----------------------------------------------------")
    logText(elapsed_time," Verbosity level: $(verbosity)")
    logText(elapsed_time," Time limit: $(timeLimit)")
    logText(elapsed_time," Sample size: $(sampleSize)")
    logText(elapsed_time," Testing: $(length(func.params)) parameters")
    logText(elapsed_time,"        : $(length(instances)) instances")
    logText(elapsed_time,"----------------------------------------------------")
    it = 1
    curParValues = deepcopy(func.param_init_vals)
    bestParValues = deepcopy(func.param_init_vals)
    curCost = execute(func,instances,curParValues,sampleSize,seeds)
    bestCost = curCost
    logInitIncumbent(elapsed_time,func,bestCost,bestParValues, verbosity)

    while T>τ
        p,value = randomMoveOperator(func,curParValues)
        parValues = deepcopy(curParValues)
        parValues[p]=value
        logStep(elapsed_time,func,parValues,verbosity)
        cost = execute(func,instances,parValues,sampleSize,seeds)
        if cost <= curCost
            curCost=cost
            curParValues = deepcopy(parValues)
            if curCost<bestCost
                bestCost = curCost
                bestParValues = deepcopy(curParValues)
                logIncumbent(elapsed_time,func,bestCost,bestParValues, verbosity)
            end
        else
            prob=rand(rng)
            ex=exp(-(cost-curCost)/T)
            if prob < ex
                curCost=cost
                curParValues = deepcopy(parValues)
            end
        end
        T=T*α
        it+=1
        elapsed_time=(time_ns()-t1)/1.0e9
        #println("Time: $(elapsed_time) - Cost: $(curCost) - T: $(T) - ",curParValues)
        if elapsed_time>=timeLimit
            break;
        end
    end
    logBestIncumbent(elapsed_time,func,bestCost,bestParValues, verbosity)
end

version() = VersionNumber(Pkg.TOML.parsefile(joinpath(@__DIR__, "..", "Project.toml"))["version"])

end # module
