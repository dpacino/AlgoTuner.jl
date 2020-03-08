module AlgoTuner

import Random
using Random
# INTERFACE RELATED TYPES AND FUNCTION

rng = MersenneTwister(1234)

@enum ParamType IntParam FloatParam

struct FuncParam
    pType::ParamType
    name::String
    LB::Float64
    UB::Float64
end

mutable struct FuncCommand
    cmd::Function
    params::Array{FuncParam,1}
    param_init_vals::Array{Float64,1}
end

function createRuntimeCommand(func::Function)
    return FuncCommand(func,[],[])
end

function addIntParam(func::FuncCommand, name::String, LB, UB)
    push!(func.params, FuncParam(IntParam,name,LB,UB))
    push!(func.param_init_vals, rand(rng,LB:UB))
end

function addFloatParam(func::FuncCommand, name::String, LB, UB)
    push!(func.params, FuncParam(FloatParam,name,LB,UB))
    push!(func.param_init_vals, LB+rand(rng)*(UB-LB))
end

function addInitialValues(func::FuncCommand, values)
    if length(values)!=length(func.params)
        error("The number of initialized parameters should be $(length(func.params))")
    end
    func.param_init_vals = deepcopy(values)
end

function runCommand(func::FuncCommand, instance, values)
    return Base.invokelatest(func.cmd, instance, values...)
end

# PARAMETER TUNING FUNCTIONS

function execute(func::FuncCommand, instances::Array{String,1}, paramValues)
    cost = 0;
    for inst in instances
        cost+=runCommand(func,inst,paramValues)
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
            return (p,rand(rng,parVals[p]:param.UB))
        else
            return (p,parVals[p]+rand(rng)*(param.UB-parVals[p]))
        end
    else # descrease value
        if param.pType == IntParam
            v =rand(rng,param.LB:parVals[p])
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

# Expects that func retuns a cost an that the algorithm is minimizing
function tune(func::FuncCommand, instances::Array{String,1}, timeLimit::Int64)
    T::Float64=1000
    α::Float64=0.99999999
    τ::Float64=0.01

    t1::Float64=time_ns()
    elapsed_time::Float64=0.0

    it = 1
    curParValues = deepcopy(func.param_init_vals)
    bestParValues = deepcopy(func.param_init_vals)
    curCost = execute(func,instances,curParValues)#add the initial values
    bestCost = curCost
    while T>τ
        p,value = randomMoveOperator(func,curParValues)
        parValues = deepcopy(curParValues)
        parValues[p]=value
        cost = execute(func,instances,parValues)
        if cost <= curCost
            curCost=cost
            curParValues = deepcopy(parValues)
            if curCost<bestCost
                bestCost = curCost
                bestParValues = deepcopy(curParValues)
                println("AlgoTuner($elapsed_time) - New incumbent with cost $bestCost")
                printParamValues(func,bestParValues)
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
    println("AlgoTuner($elapsed_time) - Best incumbent with cost $bestCost")
    printParamValues(func,bestParValues)
end

end # module
