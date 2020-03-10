using Test
using AlgoTuner
using Pkg

@testset "AlgoTuner tests" begin
    @testset "Parameter types" begin
        function testF(seed,inst,a,b,c)
            println("************* ",AlgoTuner.version())
            @test typeof(a)==Int64
            @test typeof(b)==Int64
            @test typeof(c)==Float64
        end
        cmd = AlgoTuner.createRuntimeCommand(testF)
        AlgoTuner.addIntParam(cmd,"a",1,3)
        AlgoTuner.addIntParam(cmd,"b",1,3)
        AlgoTuner.addFloatParam(cmd,"c",1,3)
        AlgoTuner.addInitialValues(cmd,[1.0,3,3.1])

        #parValues = deepcopy(cmd.param_init_vals)
        #AlgoTuner.execute(cmd,["test"],parValues,1,[123])
        AlgoTuner.runCommand(cmd,123,"test",cmd.param_init_vals)

    end

    @testset "Execution of client algorithm" begin
        testF(seed,inst,a,b,c) = a+b*c
        cmd = AlgoTuner.createRuntimeCommand(testF)
        AlgoTuner.addIntParam(cmd,"a",1,3)
        AlgoTuner.addIntParam(cmd,"b",1,3)
        AlgoTuner.addFloatParam(cmd,"c",1,3)

        @test AlgoTuner.runCommand(cmd,123,"test",[1,2,3]) == 7
        @test AlgoTuner.runCommand(cmd,123,"test",[4,2,2]) == 8

    end
end
