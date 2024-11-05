using Test, SpatialLightModulator

@testset "SpatialLightModulator" begin
    slm = SLMDisplay()
    @test_throws ErrorException SLMDisplay()
    data = rand(UInt8, slm.width, slm.height)
    updateArray(slm, data)
    unfit_data = rand(UInt8, slm.width + 1, slm.height)
    @test_throws AssertionError updateArray(slm, unfit_data)
    close(slm)
    @test_throws ErrorException updateArray(slm, data)
    @test_throws ErrorException close(slm)
end