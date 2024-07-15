module SpatialLightModulator

using GLMakie, GLMakie.GLFW

export SLM, update_hologram

struct SLM
    monitor::GLFW.Monitor
    screen::GLMakie.Screen
    height::Int
    width::Int
    framerate::Int
    fig::Figure
    ax::Axis
    hm::Heatmap{Tuple{Vector{Float32},Vector{Float32},Matrix{Float32}}}
end

function SLM(monitor_id=length(GLFW.GetMonitors()))
    GLMakie.activate!()
    monitor = GLFW.GetMonitors()[monitor_id]
    video_mode = GLFW.GetVideoMode(monitor)
    width, height = video_mode.width, video_mode.height
    framerate = video_mode.refreshrate
    fig = Figure(size=(width, height), figure_padding=0)
    ax = Axis(fig[1, 1], aspect=DataAspect())
    hidedecorations!(ax)
    hm = heatmap!(ax, zeros(UInt8, width, height), colormap=:greys, colorrange=(0, 255))
    screen = display(fig; decorated=false, focus_on_show=true, monitor, framerate)
    SLM(monitor, screen, height, width, framerate, fig, ax, hm)
end

update_hologram(slm::SLM, hologram::AbstractMatrix{UInt8}) = slm.hm[3][] = hologram
Base.close(slm::SLM) = GLMakie.destroy!(slm.screen)

end
