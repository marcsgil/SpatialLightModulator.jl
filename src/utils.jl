function init_fullscreen(monitor_id)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
    GLFW.WindowHint(GLFW.AUTO_ICONIFY, false)

    # Create a fullscreen window
    monitor = GLFW.GetMonitors()[monitor_id]
    mode = GLFW.GetVideoMode(monitor)
    window = GLFW.CreateWindow(mode.width, mode.height, "SLM $monitor_id")
    width = mode.width
    height = mode.height
    refreshrate = mode.refreshrate
    GLFW.SetWindowMonitor(window, monitor, 0, 0, width, height, refreshrate)
    GLFW.MakeContextCurrent(window)

    monitor, window, width, height, refreshrate
end

function create_shader(shader_type, source)
    shader = glCreateShader(shader_type)
    glShaderSource(shader, 1, [source], C_NULL)
    glCompileShader(shader)

    success = Ref{GLint}()
    glGetShaderiv(shader, GL_COMPILE_STATUS, success)
    if success[] == 0
        infoLog = zeros(UInt8, 1024)
        glGetShaderInfoLog(shader, 1024, C_NULL, infoLog)
        @error String(infoLog)
    end

    shader
end

function create_shader_program(shaders...)
    shaderProgram = glCreateProgram()
    for shader ∈ shaders
        glAttachShader(shaderProgram, shader)
    end

    glLinkProgram(shaderProgram)

    success = Ref{GLint}()
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, success)
    if success[] == 0
        infoLog = zeros(UInt8, 1024)
        glGetProgramInfoLog(shaderProgram, 1024, C_NULL, infoLog)
        @error String(infoLog)
    end

    for shader ∈ shaders
        glDeleteShader(shader)
    end

    shaderProgram
end

function create_buffer_object(type, vertices)
    bo = Ref{GLuint}()
    glGenBuffers(1, bo)
    glBindBuffer(type, bo[])
    glBufferData(type, sizeof(vertices), vertices, GL_STATIC_DRAW)
    bo
end

function create_vao()
    vao = Ref{GLuint}()
    glGenVertexArrays(1, vao)
    glBindVertexArray(vao[])
    vao
end


function create_texture(data)
    texture = Ref{GLuint}()
    glGenTextures(1, texture)
    glBindTexture(GL_TEXTURE_2D, texture[])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)

    width, height, _ = size(data)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, width, height, 0, GL_RGB, GL_UNSIGNED_BYTE, data)
end

function create_texture()
    texture = Ref{GLuint}()
    glGenTextures(1, texture)
    glBindTexture(GL_TEXTURE_2D, texture[])
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    texture
end