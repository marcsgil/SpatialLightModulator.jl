using ModernGL
using GLFW

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

function create_shader(shader_type, source)
    shader = glCreateShader(shader_type)
    glShaderSource(shader, 1, [source], C_NULL)
    glCompileShader(shader)
    return shader
end

function main()
    # Initialize GLFW
    GLFW.Init()
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 3)
    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)

    # Create a fullscreen window
    monitor = GLFW.GetPrimaryMonitor()
    mode = GLFW.GetVideoMode(monitor)
    window = GLFW.CreateWindow(mode.width, mode.height, "Fullscreen Grayscale Image")
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

    # Create a grayscale image
    img_width, img_height = 512, 512
    img = rand(UInt8, img_height, img_width)

    # Set up vertex data
    vertices = Float32[
        -1.0, -1.0, 0.0, 0.0,
         1.0, -1.0, 1.0, 0.0,
         1.0,  1.0, 1.0, 1.0,
        -1.0,  1.0, 0.0, 1.0
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
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, img_width, img_height, 0, GL_RED, GL_UNSIGNED_BYTE, img)

    # Main rendering loop
    while !GLFW.WindowShouldClose(window)
        glClearColor(0.0, 0.0, 0.0, 1.0)
        glClear(GL_COLOR_BUFFER_BIT)

        glUseProgram(shader_program)
        glBindVertexArray(vao[])
        glBindTexture(GL_TEXTURE_2D, texture[])
        glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, C_NULL)

        GLFW.SwapBuffers(window)
        GLFW.PollEvents()
    end

    # Clean up
    glDeleteVertexArrays(1, vao)
    glDeleteBuffers(1, vbo)
    glDeleteBuffers(1, ebo)
    glDeleteTextures(1, texture)
    GLFW.DestroyWindow(window)
    GLFW.Terminate()
end
##
# Run the program
Threads.@spawn main()

