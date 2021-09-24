/++
Module for loading a library of open graphics.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.gl;

public import bindbc.opengl;

__gshared int[2] _glVersionSpecifed;
__gshared string _glslVersion;

@property int[2] glVersionSpecifed() @trusted
{
    return _glVersionSpecifed;
}

@property string glslVersion() @trusted
{
    return _glslVersion;
}

/++
The function loads the `OpenGL` libraries for hardware graphics acceleration.

Throws:
`Exception` if the library was not found or the context was not created to 
implement hardware acceleration.
+/
void loadGraphicsLibrary() @trusted
{
    import std.exception : enforce;
    import std.conv : to;

    bool valid(GLSupport value) {
        return value != GLSupport.noContext &&
               value != GLSupport.badLibrary &&
               value != GLSupport.noLibrary; 
    }

    GLSupport retValue = loadOpenGL();
    enforce!Exception(valid(retValue), 
    "The library was not loaded or the context was not created!");

    glGetIntegerv(GL_MAJOR_VERSION, &_glVersionSpecifed[0]);
    glGetIntegerv(GL_MINOR_VERSION, &_glVersionSpecifed[1]);
   _glslVersion = glGetString(GL_SHADING_LANGUAGE_VERSION).to!string[0 .. 4];
}