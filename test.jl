using GLFW, ModernGL
import Base.Threads.@spawn

monitor = GLFW.GetPrimaryMonitor()
video_mode = GLFW.GetVideoMode(monitor)
width, height = video_mode.width, video_mode.height
window = GLFW.CreateWindow(600, 400, "SLM")
GLFW.MakeContextCurrent(window)

@spawn begin
    while !GLFW.WindowShouldClose(window)
        """/* Render here */
        glClear(GL_COLOR_BUFFER_BIT);
        # ModernGL"""

        GLFW.SwapBuffers(window)
        GLFW.PollEvents()
    end

    GLFW.DestroyWindow(window)
end
##
@spawn GLFW.SetWindowMonitor(window, monitor, 0, 0, video_mode.width, video_mode.height, video_mode.refreshrate)

glCreateVertexArrays(1,1)
ModernGL.glGenVertexArrays(1, )