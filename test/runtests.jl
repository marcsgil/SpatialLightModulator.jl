using Test, SpatialLightModulator

@testset "SpatialLightModulator" begin
    slm = SLM()
    @test_throws ErrorException SLM()
    data = rand(UInt8, slm.width, slm.height)
    update_hologram(slm, data)
    unfit_data = rand(UInt8, slm.width + 1, slm.height)
    @test_throws AssertionError update_hologram(slm, unfit_data)
    close(slm)
    @test_throws ErrorException update_hologram(slm, data)
    @test_throws ErrorException close(slm)
end