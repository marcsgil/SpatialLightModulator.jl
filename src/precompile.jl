using PrecompileTools

@setup_workload begin
    @compile_workload begin
        slm = SLM()
        holo = rand(UInt8, slm.width, slm.height)
        update_hologram!(slm, holo)
        close(slm)
    end
end