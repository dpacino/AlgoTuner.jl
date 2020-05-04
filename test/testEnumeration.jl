
using AlgoTuner

foo(seed,inst,a,b) = a*2-b

cmd1 = AlgoTuner.createRuntimeCommand(foo)

AlgoTuner.addIntParam(cmd1,"a",1,3)
AlgoTuner.addIntParam(cmd1,"b",4,5)


AlgoTuner.enumerationTuning(cmd1,["test"],2,[1234,345])

