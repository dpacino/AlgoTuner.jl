using AlgoTuner


include("dario_SA_Julia_opt2.jl")

function getBestKnownValues()
    instances = ["tsp_toy20.tsp","tsp_toy50.tsp"]
    bestKnown = Dict{String,Float64}()
    for inst in instances
        bestKnown[inst] = SA(inst,1,1234,300.0,0.9999,1)
    end
    return instances, bestKnown
end

benchmark,bestKnown = getBestKnownValues()


#Original function
#SA("TSP/tsp_fun.tsp",2,1234,1000.0,0.9999999)

TSP_SA(seed, instance, T, alpha, test) =
        (SA(instance,2,seed,T,alpha, test) - bestKnown[instance])/bestKnown[instance]

cmd = AlgoTuner.createRuntimeCommand(TSP_SA)

AlgoTuner.addFloatParam(cmd,"T",100,10000)
AlgoTuner.addFloatParam(cmd,"alpha",0.9,0.9999999)
AlgoTuner.addIntParam(cmd,"test",1,2)

#AlgoTuner.addInitialValues(cmd,[300.0,0.9999,1])

AlgoTuner.tune(cmd,benchmark,30,2,[1234,5432],AlgoTuner.ShowAll)
