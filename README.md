# Tida
---
[![dub](https://img.shields.io/dub/v/tida)](https://code.dlang.org/packages/tida) ![license](https://img.shields.io/dub/l/tida) ![version](https://img.shields.io/dub/dt/tida)

_ATTENTION! The project cannot guarantee the immutability of the API and stability. If you decide to use it for real purposes, this is your own risk. Found a bug? Throw it into the issue group._

What can?
---
Tida is a 2D game framework focused on objective programming.

The framework supports rendering of post-enhanced elementary shapes, rendering textures, and can also set such textures to a shape (by type, a texture that is filled on a circle). Basic concepts of catching keyboard and mouse input (unfortunately, joysticks are not yet supported!), Simple window manipulation, working with some two-dimensional mathematical models, text rendering using fonts, working with colors and mixing them, an objective-oriented model using scene-instance-components, and can organize the game loop for you.

# Features
1. **Objective-Oriented System**. The system for defining behavior consists of scenes, instances and their components, which will help to facilitate and sort the tasks of each game unit.

2. **Modularity**. Also, in addition to this, you can do without it by creating a runtime, window, processing and, in your own way, decide how you will set the behavior of the program. And also, you can extend the functionality of objects (which, of course, have interfaces through which you can already set your own behavior, otherwise - nothing). Also, if the renderer does not implement some of the rendering - do it yourself, using the implementation of the `IDrawable` /` IDrawableEx` interfaces!

3. **Sufficient simplicity**. To create the simplest window, you just need to create a class and declare the game parameters, and that's it! Also, many objects are documented, so it will be much easier to understand something.

4. **Useful optional extensions**. The author of the framework also implements some small additions, such as reading tile cards, some dummy. Also, there are other extensions in the plans that will appear in the future!


# What is a scene-instance-component?
This system allows you to easily define the behavior of the entire scene and its individual units, assigning such units (instances) individual or group behavior (depending on how you do it), while without overloading. To, for example, process keystrokes in the scene, you need to hang a special attribute on it that will track this, here's an example:
```d
import tida;

class Main : Scene
{
    @Event!Input
    void onInput(EventHandler event) @safe
    {
        if (event.keyDown == Key.Left)
        {
            <body>
        }
    }
}
```

It is also possible with `Instance`'s, which work in the same way to track events, however, their main difference is that they are added and tracked by the scene, and instances can interact with each other using collisions or generated local events. For a complete explanation, see the example for how they work (eg, `simplegame`, `seabattle`).

# How can you start a project with this framework?
Easy enough. Grab and run the following command where you plan to initialize the project:
```bash
$ dub run tida:init
```

This will bring up a project template with a source file template. Launch it, and you can already watch the game window!


# What platforms does it support?
At the moment - a computer with Windows and Linux operating systems. There is also Android in the plans, but only in the plans. The rest of the platforms are either not available or will not be made on principle.

# License (MIT)
Copyright 2020 (c) TodNaz

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
