module SpatialLightModulator

using ModernGL, GLFW
export SLM, update_hologram!, close

global is_there_an_open_slm = false

"""
    SLM(monitor_number=length(GetMonitors()))

A struct representing a Spatial Light Modulator (SLM).

# Fields
- `image::Array{UInt8,2}`: The grayscale image to be displayed
- `width::Int`: Width of the image/display
- `height::Int`: Height of the image/display
- `monitor::GLFW.Monitor`: The monitor on which to display
- `window::GLFW.Window`: The GLFW window object
- `mode::GLFW.VidMode`: Video mode of the monitor
- `shader_program::GLuint`: OpenGL shader program ID
- `vao::Ref{GLuint}`: Vertex Array Object
- `vbo::Ref{GLuint}`: Vertex Buffer Object
- `ebo::Ref{GLuint}`: Element Buffer Object
- `texture::Ref{GLuint}`: Texture object for the image
"""
mutable struct SLM
    image::Array{UInt8,2}
    width::Int
    height::Int
    monitor::GLFW.Monitor
    window::GLFW.Window
    mode::GLFW.VidMode
    shader_program::GLuint
    vao::Ref{GLuint}
    vbo::Ref{GLuint}
    ebo::Ref{GLuint}
    texture::Ref{GLuint}
    isopen::Bool
end

Base.show(io::IO, slm::SLM) = print(io, "SLM @ $(slm.monitor)")

# Vertex shader source code
vertex_shader_source = """
#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aTexCoord;
out vec2 TexCoord;
void main()
{
    gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0);
    TexCoord = aTexCoord;
}
"""

# Fragment shader source code
fragment_shader_source = """
#version 330 core
in vec2 TexCoord;
out vec4 FragColor;
uniform sampler2D ourTexture;
void main()
{
    float color = texture(ourTexture, TexCoord).r;
    FragColor = vec4(color, color, color, 1.0);
}
"""

"""
    create_shader(shader_type, source)

Create and compile an OpenGL shader.

# Arguments
- `shader_type`: The type of shader (e.g., GL_VERTEX_SHADER or GL_FRAGMENT_SHADER)
- `source`: The shader source code as a string

# Returns
- The compiled shader object
"""
function create_shader(shader_type, source)
    shader = glCreateShader(shader_type)
    glShaderSource(shader, 1, [source], C_NULL)
    glCompileShader(shader)
    return shader
end

function SLM(monitor_id=length(GLFW.GetMonitors())) 
    @assert !is_there_an_open_slm "There is already an open SLM"
    global is_there_an_open_slm = true

    # Initialize GLFW
    GLFW.Init()
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)

    # Create a fullscreen window
    monitor = GLFW.GetMonitors()[monitor_id]
    mode = GLFW.GetVideoMode(monitor)
    window = GLFW.CreateWindow(mode.width, mode.height, "SLM")
    GLFW.SetWindowMonitor(window, monitor, 0, 0, mode.width, mode.height, mode.refreshrate)
    GLFW.MakeContextCurrent(window)

    # Create and compile shaders
    vertex_shader = create_shader(GL_VERTEX_SHADER, vertex_shader_source)
    fragment_shader = create_shader(GL_FRAGMENT_SHADER, fragment_shader_source)

    # Create shader program
    shader_program = glCreateProgram()
    glAttachShader(shader_program, vertex_shader)
    glAttachShader(shader_program, fragment_shader)
    glLinkProgram(shader_program)

    # Set up vertex data
    vertices = Float32[
        -1.0, -1.0, 0.0, 0.0,
        1.0, -1.0, 1.0, 0.0,
        1.0, 1.0, 1.0, 1.0,
        -1.0, 1.0, 0.0, 1.0
    ]

    indices = UInt32[0, 1, 2, 2, 3, 0]

    # Create VAO, VBO, and EBO
    vao = Ref{GLuint}()
    glGenVertexArrays(1, vao)
    glBindVertexArray(vao[])

    vbo = Ref{GLuint}()
    glGenBuffers(1, vbo)
    glBindBuffer(GL_ARRAY_BUFFER, vbo[])
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW)

    ebo = Ref{GLuint}()
    glGenBuffers(1, ebo)
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ebo[])
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW)

    # Set vertex attribute pointers
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), C_NULL)
    glEnableVertexAttribArray(0)
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(2 * sizeof(Float32)))
    glEnableVertexAttribArray(1)

    # Create texture
    texture = Ref{GLuint}()
    glGenTextures(1, texture)
    glBindTexture(GL_TEXTURE_2D, texture[])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)


    # Create a grayscale image
    width, height = mode.width, mode.height
    image = zeros(UInt8, width, height)
    slm = SLM(image, width, height, monitor, window, mode, shader_program, vao, vbo, ebo, texture, true)

    glViewport(0, 0, mode.width, mode.height)

    update_hologram!(slm)
    slm
end

"""
    render_frame(slm::SLM; sleep_time=0.15)

Render a single frame for the SLM, using slm.image, and wait for `sleep_time` seconds.
"""
function render_frame(slm::SLM; sleep_time=0.15)
    glClearColor(0.0, 0.0, 0.0, 1.0)
    glClear(GL_COLOR_BUFFER_BIT)

    glUseProgram(slm.shader_program)
    glBindVertexArray(slm.vao[])
    glBindTexture(GL_TEXTURE_2D, slm.texture[])
    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)

    GLFW.SwapBuffers(slm.window)
    GLFW.PollEvents()
    Base.Libc.systemsleep(sleep_time)
    nothing
end

function update_hologram!(slm; sleep_time=0.15)
    @assert slm.isopen "SLM is closed"
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, slm.width, slm.height, 0, GL_RED, GL_UNSIGNED_BYTE, slm.image')
    render_frame(slm; sleep_time)
end

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

"""
    update_hologram!(slm::SLM[, image]; sleep_time=0.15)

Update the hologram display. If `image` is provided, update the display with that image. Otherwise, update the display with `slm.image`.
"""
function update_hologram!(slm, image; sleep_time=0.15)
    copy!(centralized_cut(slm.image, size(image)), image)
    update_hologram!(slm; sleep_time)
end

"""
    close(slm::SLM)

Close the SLM window and clean up resources.
"""
function Base.close(slm::SLM)
    GLFW.SetWindowShouldClose(slm.window, true)
    glDeleteVertexArrays(1, slm.vao)
    glDeleteBuffers(1, slm.vbo)
    glDeleteBuffers(1, slm.ebo)
    glDeleteTextures(1, slm.texture)
    GLFW.DestroyWindow(slm.window)
    slm.isopen = false
    global is_there_an_open_slm = false
    nothing
end

include("precompile.jl")

end
