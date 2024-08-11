using PrecompileTools

using PrecompileTools

@setup_workload begin
    holo = rand(UInt8, 1920, 1080)
    @compile_workload begin
        slm = SLM()
        update_hologram(slm, holo)
        close(slm)
    end
end