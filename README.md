# Tida
Tida is a library written in D. It is intended for opening a window, drawing objects in it and tracking window events. In general, this project was created for 2D games, so all components are focused only on 2D logic.

For now, the library can:
* Open a window on Windows and Linux platforms (x11).
* Create a context for a window (OpenGL).
* Draw some objects like: `lines`, `circle`, `rectangles`, `regular triangles`, `Images`.
* Create and load images from formats such as `png`,` jpeg`, `tga`,` bmp`. (Also: [imageformats](https://code.dlang.org/packages/imageformats)).
* Render text using the FreeType library.

Examples of programs can be found [here](https://github.com/TodNaz/Tida/tree/master/examples).

# How to use the project?
To use the libraries, just add the repository to the dependencies:
```json
{
    "name": "git-dependency",
    "dependencies": {
        "tida": {
            "repository": "git+https://github.com/TodNaz/Tida.git",
            "version": "~master"
        }
    }
}
```
The configuration should itself find the dependencies to the library, depending on the platform being built.

# Other
Documentation is currently only presented in the `docs` folder.
