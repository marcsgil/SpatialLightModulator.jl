module SpatialLightModulator

using ModernGL, GLFW
using GLFW: GetMonitors
include("utils.jl")
export main, SLMDisplay, updateArray, GetMonitors

global open_monitors = Set{Int}()

struct SLMDisplay
    monitor::Int
    window::GLFW.Window
    width::Int
    height::Int
    refreshrate::Int
    shaderProgram::GLuint
    vao::Ref{GLuint}
    vbo::Ref{GLuint}
    ebo::Ref{GLuint}
    texture::Ref{GLuint}
end

Base.show(io::IO, slm::SLMDisplay) = print(io, "SLM @ $(GLFW.GetMonitors()[slm.monitor])")

"""
    SLMDisplay(monitor::Int=lastindex(GetMonitors()))

Create a new Spatial Light Modulator (SLM) window.

`monitor` is the index of the monitor to use. By default, the last monitor is used.
To get the list of available monitors, use `GetMonitors()`, which is re-exported from GLFW.jl.
"""
function SLMDisplay(monitor::Int=lastindex(GLFW.GetMonitors()))
    if monitor in open_monitors
        error("Monitor $monitor is already in use")
    end

    glfw_monitor, window, width, height, refreshrate = init_fullscreen(monitor)
    push!(open_monitors, monitor)

    srcVertexShader = """
    #version 330 core
    layout (location = 0) in vec2 aPos;
    layout (location = 1) in vec2 aTexCoord;

    out vec2 TexCoord;

    void main()
    {
        gl_Position = vec4(aPos, 0.0, 1.0);
        TexCoord = vec2(aTexCoord.x, aTexCoord.y);
    }
    """

    srcFragmentShader = """
    #version 330 core
    out vec4 FragColor;

    in vec2 TexCoord;

    uniform sampler2D texture1;

    void main()
    {
        float color = texture(texture1, TexCoord).r;
        FragColor = vec4(color, color, color, 1.0);
    }
    """

    vertexShader = create_shader(GL_VERTEX_SHADER, srcVertexShader)
    fragmentShader = create_shader(GL_FRAGMENT_SHADER, srcFragmentShader)
    shaderProgram = create_shader_program(vertexShader, fragmentShader)

    vertices = Float32[
        1, 1, 1, 1, # top right
        1, -1, 1, 0, # bottom right
        -1, -1, 0, 0, # bottom left
        -1, 1, 0, 1, # top left
    ]

    indices = UInt32[
        0, 1, 3,
        1, 2, 3
    ]

    vao = create_vao()

    vbo = create_buffer_object(GL_ARRAY_BUFFER, vertices)
    ebo = create_buffer_object(GL_ELEMENT_ARRAY_BUFFER, indices)

    # vertex position
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(0))
    glEnableVertexAttribArray(0)

    # vertex color
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(2 * sizeof(Float32)))
    glEnableVertexAttribArray(1)

    texture = create_texture()
    glUseProgram(shaderProgram)

    slm = SLMDisplay(monitor, window, width, height, refreshrate, shaderProgram, vao, vbo, ebo, texture)
    updateArray(slm, zeros(UInt8, width, height))
    slm
end

"""
    updateArray(slm::SLMDisplay, data::AbstractMatrix{UInt8}; sleep=0.15)

Update the array displayed on the SLM.

`data` is a 2D matrix of UInt8 values representing the hologram.
The size of `data` must match the size of the SLM window.
Sleep for `sleep` seconds after updating the hologram. This is useful to give the SLM time to update the hologram.
"""
function updateArray(slm::SLMDisplay, data::AbstractMatrix{UInt8}; sleep=0.15)
    @assert size(data) == (slm.width, slm.height) "Data size does not match SLM size"

    if GLFW.WindowShouldClose(slm.window)
        error("The SLM window has already been closed")
    end

    glClear(GL_COLOR_BUFFER_BIT)

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, size(data)..., 0, GL_RED, GL_UNSIGNED_BYTE, data)

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)
    GLFW.SwapBuffers(slm.window)
    GLFW.PollEvents()
    Base.Libc.systemsleep(sleep)
    nothing
end

"""
    close(slm::SLMDisplay)

Close the SLM window.
"""
function Base.close(slm::SLMDisplay)
    if GLFW.WindowShouldClose(slm.window)
        error("The SLM window has already been closed")
    end
    GLFW.SetWindowShouldClose(slm.window, true)
    GLFW.DestroyWindow(slm.window)
    try
        glDeleteVertexArrays(1, slm.vao)
        glDeleteBuffers(1, slm.vbo)
        glDeleteBuffers(1, slm.ebo)
        glDeleteTextures(1, slm.texture)
    catch e
        @warn "Trying to delete buffers led to the following error:"
        println(e)
    end
    pop!(open_monitors, slm.monitor)
    nothing
end

include("precompile.jl")

end
