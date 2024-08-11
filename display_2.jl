using ModernGL
using GLFW
using Base.Threads

# Vertex shader source code
const vertex_shader_source = """
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
const fragment_shader_source = """
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

function create_shader(shader_type, source)
    shader = glCreateShader(shader_type)
    glShaderSource(shader, 1, [source], C_NULL)
    glCompileShader(shader)
    
    # Check for shader compile errors
    success = Ref{GLint}()
    glGetShaderiv(shader, GL_COMPILE_STATUS, success)
    if success[] != GL_TRUE
        infoLog = Vector{GLchar}(undef, 512)
        glGetShaderInfoLog(shader, 512, C_NULL, infoLog)
        error("Shader compilation failed: $(unsafe_string(pointer(infoLog)))")
    end
    
    return shader
end

mutable struct GLContext
    window::GLFW.Window
    shader_program::GLuint
    texture::GLuint
    vao::GLuint
    pbo::GLuint
    new_image::Array{UInt8,2}
    running::Atomic{Bool}
    update_requested::Atomic{Bool}
    width::Int
    height::Int
    render_condition::Condition
    render_lock::ReentrantLock
end

function init_gl(width, height)
    GLFW.Init()
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)

    # Get the primary monitor
    monitor = GLFW.GetPrimaryMonitor()
    mode = GLFW.GetVideoMode(monitor)

    # Create a fullscreen window
    window = GLFW.CreateWindow(mode.width, mode.height, "SLM Controller")
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

    # Check for linking errors
    success = Ref{GLint}()
    glGetProgramiv(shader_program, GL_LINK_STATUS, success)
    if success[] != GL_TRUE
        infoLog = Vector{GLchar}(undef, 512)
        glGetProgramInfoLog(shader_program, 512, C_NULL, infoLog)
        error("Shader program linking failed: $(unsafe_string(pointer(infoLog)))")
    end

    glDeleteShader(vertex_shader)
    glDeleteShader(fragment_shader)

    # Set up vertex data
    vertices = Float32[
        -1.0, -1.0, 0.0, 0.0,
         1.0, -1.0, 1.0, 0.0,
         1.0,  1.0, 1.0, 1.0,
        -1.0,  1.0, 0.0, 1.0
    ]

    indices = UInt32[0, 1, 2, 2, 3, 0]

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

    # Position attribute
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), C_NULL)
    glEnableVertexAttribArray(0)
    # Texture coord attribute
    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 4 * sizeof(Float32), Ptr{Cvoid}(2 * sizeof(Float32)))
    glEnableVertexAttribArray(1)

    # Create texture
    texture = Ref{GLuint}()
    glGenTextures(1, texture)
    glBindTexture(GL_TEXTURE_2D, texture[])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)

    # Create Pixel Buffer Object (PBO)
    pbo = Ref{GLuint}()
    glGenBuffers(1, pbo)
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, pbo[])
    glBufferData(GL_PIXEL_UNPACK_BUFFER, width * height, C_NULL, GL_STREAM_DRAW)
    glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0)

    # Initialize with a blank image
    blank_image = zeros(UInt8, height, width)
    glBindTexture(GL_TEXTURE_2D, texture[])
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, width, height, 0, GL_RED, GL_UNSIGNED_BYTE, blank_image)

    return GLContext(window, shader_program, texture[], vao[], pbo[], zeros(UInt8, height, width),
                     Atomic{Bool}(true), Atomic{Bool}(false), width, height, Condition(), ReentrantLock())
end

function render_loop(ctx::GLContext)
    #GLFW.MakeContextCurrent(ctx.window)
    #glFinish()

    while ctx.running[]
        lock(ctx.render_lock) do
            if ctx.update_requested[]
                glBindBuffer(GL_PIXEL_UNPACK_BUFFER, ctx.pbo)
                ptr = glMapBuffer(GL_PIXEL_UNPACK_BUFFER, GL_WRITE_ONLY)
                unsafe_copyto!(Ptr{UInt8}(ptr), pointer(ctx.new_image), ctx.width * ctx.height)
                glUnmapBuffer(GL_PIXEL_UNPACK_BUFFER)

                glBindTexture(GL_TEXTURE_2D, ctx.texture)
                glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, ctx.width, ctx.height, GL_RED, GL_UNSIGNED_BYTE, C_NULL)
                glBindBuffer(GL_PIXEL_UNPACK_BUFFER, 0)

                ctx.update_requested[] = false
            end
        end

        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GL_COLOR_BUFFER_BIT)

        glUseProgram(ctx.shader_program)
        glBindVertexArray(ctx.vao)
        glBindTexture(GL_TEXTURE_2D, ctx.texture)
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)

        GLFW.SwapBuffers(ctx.window)
        GLFW.PollEvents()

        if GLFW.WindowShouldClose(ctx.window)
            ctx.running[] = false
        end

        yield()  # Allow other tasks to run
    end

    GLFW.DestroyWindow(ctx.window)
    GLFW.Terminate()
end

function start_slm_controller(width, height)
    ctx = init_gl(width, height)
    
    Threads.@spawn render_loop(ctx)
    
    return ctx
end

function update_image!(ctx::GLContext, new_image::Array{UInt8,2})
    if size(new_image) != (ctx.height, ctx.width)
        error("New image dimensions ($(size(new_image))) must match the original dimensions ($(ctx.height), $(ctx.width))")
    end
    lock(ctx.render_lock) do
        copyto!(ctx.new_image, new_image)
        ctx.update_requested[] = true
    end
    notify(ctx.render_condition)
end

function stop_slm_controller(ctx::GLContext)
    ctx.running[] = false
end
##
# Start the SLM controller
width, height = 2560, 1080  # Set to your SLM's resolution
ctx = start_slm_controller(width, height)

new_image = rand(UInt8, height, width)
update_image!(ctx, new_image)

for i in 1:10
    new_image = rand(UInt8, height, width)
    update_image!(ctx, new_image)
    sleep(0.1)  # Wait for 100ms
end

stop_slm_controller(ctx)
