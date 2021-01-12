# Tida
Tida is a kind of framework for two-dimensional games aimed at creating something of its own in the D language, while using libraries such as:
* `X11`, `GLX`, `WGL` - to create a window and context in such a window. In the code, all this will be implemented in an OOP style, using higher-level constructs to create a window already in the main code, using such a library.
* `OpenGL 2.0` - for rendering 2D graphics in a window. A special render will be prepared for it, where you can specify some parameters for rendering, cameras, and so on.
* `FreeType` - for text rendering, without it it is practically difficult to implement manual text rendering.
* `OpenAL` - To play music content. By default, it accepts raw data, but using the `mp3decoders` application library, it is now allowed to load compressed music format rather than raw data.
* `imageformats` - To load common image formats such as `.png`,` .jpeg`, `.bmp`,` .tga`. Also, the framework has already prepared an implementation for describing images and colors to facilitate presentation.

# What does this project have to offer and what is it planning?
At the moment, the project already knows how to create windows and contexts in Linux and Windows environments, and conditionally independent functions from the platform have also been implemented (Conditionally, because when trying to implement a manual complete creation, you still have to take into account some nuances, in the form of order of calls and etc., for this the process has already been facilitated, in the form of one-time initialization of the window).

Also, the project is already able to catch such window events as changes in size, position (only through the window itself), keystrokes, tracking mouse events and tracking the event of exiting the program.

Example:
```D
module app;

import tida;

void main(string[] args)
{
    TidaRuntime.initialize(args);

    Window window = new Window(640,480,"Simple window.");
    window.initialize!Simple;

    EventHandler event = new EventHandler(window);

    bool isGame = true;

    while(isGame)
    {
        while(event.update)
        {
            if(event.isQuit)
                isGame = false;

            if(event.getKeyDown == Key.Escape)
                isGame = false;
        }
    }
}
```
(Such an example is available in a special folder -> `examples/simplewindow`).

Also, at the moment, the Scene-Entity system is already being developed, which will allow programming at a higher level, where you do not need to worry about scheduling actions in the game cycle, but simply write a class and implement everything according to your respective events, which will facilitate the process of writing games using scenes and objects.

# Contribution
You can help with code given CODE STYLE, which is not very strict. Tasks can be viewed in GitHub Projects, or by opening tida.minder through Minder, it describes what needs to be implemented and what is implemented. All changes are accepted through `Pull requests`. All functions that you have changed or added are desirable to sign, for example:
```D
/++
    Description...
    
    Params:
        ...
        
    Returns:
        ...
        
    Authors: TodNaz <tod.naz@ya.ru>
+/
T sign(T)(T number) @safe nothrow
{
    if(number == 0) return 0;

    return number > 0 ? 1 : -1;
}
```

# How to use the project?
I don't think that you can seriously use this project, but if you decide, you can add it via dub, but not through the official repository, but by adding the repository to the build configuration:
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

# Documentation
The documentation is not available from source, however you can generate it yourself. Enter the following to generate the documentation:
```
$ cd .../Tida
$ dub fetch gendoc
$ dub run gendoc
$ cd docs/
```

# License
Copyright 2020 (c) TodNaz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.