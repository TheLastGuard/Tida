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

alias ExtList = string[];

enum Extensions : string
{
    textureCompression = "GL_ARB_texture_compression",
    textureArray = "GL_EXT_texture_array"
}

bool hasExtensions(ExtList list, string name) @trusted
{
    import std.algorithm : canFind;

    if (list.length == 0)
        list = glExtensionsList();

    return list.canFind(name);
}

ExtList glExtensionsList() @trusted
{
    import std.conv : to;
    import std.string : split;

    int numExtensions = 0;
    glGetIntegerv(GL_NUM_EXTENSIONS, &numExtensions);

    string[] extensions;

    foreach (i; 0 .. numExtensions)
    {
        extensions ~= glGetStringi(GL_EXTENSIONS, i).to!string;
    }

    return extensions;
}

// Texture compressed
alias FCompressedTexImage2DARB = void function(GLenum target,
                                               int level,
                                               GLenum internalformat,
                                               GLsizei width,
                                               GLsizei height,
                                               int border,
                                               GLsizei imagesize,
                                               void* data);

__gshared
{
    FCompressedTexImage2DARB glCompressedTexImage2DARB;
}

alias glCompressedTexImage2D = glCompressedTexImage2DARB;

enum
{
    GL_COMPRESSED_RGBA_ARB = 0x84EE,
    GL_COMPRESSED_RGB_ARB = 0x84ED,
    GL_COMPRESSED_ALPHA_ARB = 0x84E9,

    GL_TEXTURE_COMPRESSION_HINT_ARB = 0x84EF,
    GL_TEXTURE_COMPRESSED_IMAGE_SIZE_ARB = 0x86A0,
    GL_TEXTURE_COMPRESSED_ARB = 0x86A1,
    GL_NUM_COMPRESSED_TEXTURE_FORMATS_ARB = 0x86A2,
    GL_COMPRESSED_TEXTURE_FORMATS_ARB = 0x86A3
}

bool extTextureCompressionLoad() @trusted
{
    import bindbc.opengl.util;

    if (!hasExtensions(null, "GL_ARB_texture_compression"))
        return false;

    if (!loadExtendedGLSymbol(  cast(void**) &glCompressedTexImage2DARB,
                                "glCompressedTexImage2DARB"))
        return false;

    return true;
}

// Texture array ext 
alias FFramebufferTextureLayerEXT = void function();

__gshared
{
    FFramebufferTextureLayerEXT glFramebufferTextureLayerEXT;
}

enum
{
    GL_TEXTURE_1D_ARRAY_EX = 0x8C18,
    GL_TEXTURE_2D_ARRAY_EXT = 0x8C1A,

    GL_TEXTURE_BINDING_1D_ARRAY_EXT = 0x8C1C,
    GL_TEXTURE_BINDING_2D_ARRAY_EXT = 0x8C1D,
    GL_MAX_ARRAY_TEXTURE_LAYERS_EXT = 0x88FF,
    GL_COMPARE_REF_DEPTH_TO_TEXTURE_EXT = 0x884E
}

bool extTextureArrayLoad() @trusted
{
    import bindbc.opengl.util;

    if (!hasExtensions(null, Extensions.textureArray))
        return false;

    // glFramebufferTextureLayerEXT
    if (!loadExtendedGLSymbol(cast(void**) &glFramebufferTextureLayerEXT,
                              "glFramebufferTextureLayerEXT"))
        return false;

    return true;
}