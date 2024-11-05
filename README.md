# SpatialLightModulator.jl

This project provides a Julia package for controlling a spatial light modulator (SLM). It allows you to display a fullscreen image, represented by a matrix of `UInt8` values, on a specified monitor. The package leverages [OpenGL.jl](https://github.com/JuliaGL/ModernGL.jl) for rendering and [GLFW.jl](https://github.com/JuliaGL/GLFW.jl) for window management.

## Installation

The package is in the General Registry, so you can install it by hitting `]` in a Julia REPL to enter the PKG mode and then typing

```
add SpatialLightModulator
```

## Usage

Here's a basic example of how to use the `SpatialLightModulator` package:

```julia
using SpatialLightModulator

# Create an SLM instance for the last monitor
slm = SLMDisplay()

# Generate random hologram data
holo = rand(UInt8, slm.width, slm.height)

# Update the hologram displayed on the SLM
updateArray(slm, holo)

# Close the SLM window
close(slm)
```

For the calculation of holograms used to produce structured light modes, consider using [StructuredLight.jl](https://github.com/marcsgil/StructuredLight.jl).

## Documentation

### `SLMDisplay`
    SLMDisplay(monitor::Int=lastindex(GetMonitors()))

Create a new Spatial Light Modulator (SLM) window.

`monitor` is the index of the monitor to use. By default, the last monitor is used.
To get the list of available monitors, use `GetMonitors()`, which is re-exported from GLFW.jl.


### `updateArray`
    updateArray(slm::SLMDisplay, data::AbstractMatrix{UInt8}; sleep=0.15)

Update the array displayed on the SLM.

`data` is a 2D matrix of UInt8 values representing the hologram.
The size of `data` must match the size of the SLM window.
Sleep for `sleep` seconds after updating the hologram. This is useful to give the SLM time to update the hologram.

### `close`

    close(slm::SLMDisplay)

Close the SLM window.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## Contact

For any questions or issues, please open an issue on the GitHub repository or send an email to `marcosgildeoliveira@gmail.com`