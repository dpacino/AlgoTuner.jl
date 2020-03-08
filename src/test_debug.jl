include("AlgoTuner.jl")

function testF(inst,a,b,c)
    return (0.5-rand())*10
end

cmd = AlgoTuner.createRuntimeCommand(testF)
AlgoTuner.addIntParam(cmd,"a",1,3)
AlgoTuner.addIntParam(cmd,"b",1,3)
AlgoTuner.addFloatParam(cmd,"c",1,3)
#AlgoTuner.addInitialValues(cmd,[1,3,4])

#AlgoTuner.runCommand(cmd,cmd.param_init_vals)
AlgoTuner.tune(cmd,["a","b","c"],2)
