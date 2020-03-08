using Test
using AlgoTuner

@testset "Execution of client algorithm" begin
    testF(inst,a,b,c) = a+b*c
    cmd = AlgoTuner.createRuntimeCommand(testF)
    AlgoTuner.addIntParam(cmd,"a",1,3)
    AlgoTuner.addIntParam(cmd,"b",1,3)
    AlgoTuner.addFloatParam(cmd,"c",1,3)

    @test AlgoTuner.runCommand(cmd,"test",[1,2,3]) == 7
    @test AlgoTuner.runCommand(cmd,"test",[4,2,2]) == 8
end
