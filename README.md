# SpatialLightModulator.jl

This project provides a Julia package for controlling a spatial light modulator (SLM). It allows you to display a fullscreen image, represented by a matrix of `UInt8` values, on a specified monitor. The package leverages [OpenGL.jl](https://github.com/JuliaGL/ModernGL.jl) for rendering and [GLFW.jl](https://github.com/JuliaGL/GLFW.jl) for window management.

## Installation

To install the package, clone the repository and use Julia's package manager to add it to your environment:

```sh
git clone https://github.com/yourusername/SpatialLightModulator.git
cd SpatialLightModulator
julia -e 'using Pkg; Pkg.add(PackageSpec(path=pwd()))'
```

## Usage

Here's a basic example of how to use the `SpatialLightModulator` package:

```julia
using SpatialLightModulator

# Create an SLM instance for the last monitor
slm = SLM()

# Generate random hologram data
holo = rand(UInt8, slm.width, slm.height)

# Update the hologram displayed on the SLM
update_hologram(slm, holo)

# Close the SLM window
close(slm)
```

For the calculation of holograms used to produce structured light modes, consider using [StructuredLight.jl](https://github.com/marcsgil/StructuredLight.jl).

## Documentation

### `SLM`
    SLM(monitor_id::Int=lastindex(GetMonitors()))

Create a new Spatial Light Modulator (SLM) window.
`monitor_id` is the index of the monitor to use. By default, the last monitor is used.
To get the list of available monitors, use `GetMonitors()`, which is re-exported from GLFW.jl.


### `update_hologram`

    update_hologram(slm::SLM, data::AbstractMatrix{UInt8}; sleep_time=0.15)
    

Update the hologram displayed on the SLM.
`data` is a 2D matrix of `UInt8` values representing the hologram.
The size of `data` must match the size of the SLM window.

### `close`

    close(slm::SLM)

Close the SLM window.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request on GitHub.

## Contact

For any questions or issues, please open an issue on the GitHub repository or send an email to `marcosgildeoliveira@gmail.com`