module SpatialLightModulator

using GLMakie, GLMakie.GLFW
using Roots, Interpolations, Bessels

export SLM, update_hologram, close
export centralized_indices, all_centralized_indces, centralized_cut

function centralized_indices(x, cut_size, ax=1)
    L = size(x, ax)
    center = L ÷ 2
    max(1, center - cut_size ÷ 2 + 1):min(L, center + cut_size ÷ 2)
end

function all_centralized_indces(x, cut_size)
    (centralized_indices(x, cut_size[n], n) for n ∈ 1:ndims(x))
end

function centralized_cut(x, cut_size)
    view(x, all_centralized_indces(x, cut_size)...)
end

mutable struct SLM
    monitor::GLFW.Monitor
    screen::GLMakie.Screen
    height::Int
    width::Int
    framerate::Int
    hologram::Matrix{UInt8}
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
    hologram = zeros(UInt8, width, height)
    hm = heatmap!(ax, hologram, colormap=:greys, colorrange=(0, 255))
    screen = display(fig; decorated=false, focus_on_show=true, monitor, framerate)
    SLM(monitor, screen, height, width, framerate, hologram, fig, ax, hm)
end

function update_hologram(slm::SLM, hologram::AbstractMatrix{UInt8}; sleep_time=0.15)
    indices = all_centralized_indces(slm.hologram, size(hologram))
    slm.hologram[indices...] = hologram
    slm.hm[3][] .= slm.hologram
    notify(slm.hm[3])
    sleep(sleep_time)
end

Base.close(slm::SLM) = GLMakie.destroy!(slm.screen)

include("precompile.jl")

end
