using PrecompileTools

@setup_workload begin
    @compile_workload begin
        slm = SLMDisplay()
        holo = rand(UInt8, slm.width, slm.height)
        updateArray(slm, holo)
        close(slm)
    end
end