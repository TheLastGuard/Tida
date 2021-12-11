/++
Module for loading the library of open graphics, as well as some of its 
extensions.

Also, the module provides information about which version of the library 
is used, provides a list of available extensions, and more.

To load the library, you need the created graphics context. Therefore, 
you need to create a window and embed a graphical context, 
which is described $(HREF window.html, here). After that, 
using the $(LREF loadGraphicsLibrary) function, the functions of 
the open graphics library will be available.

Example:
---
import tida.runtime;
import tida.window;
import tida.gl;

int main(string[] args)
{
    ITidaRuntime.initialize(args, AllLibrary);
    Window window = new Window(640, 480, "Example window");
    window.windowInitialize!(WithContext)();
    
    loadGraphicsLibrary();
    
    return 0;
}
---

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

/++
A function that returns the version of the library in the form of two numbers: 
a major version and a minor version.
+/
@property int[2] glVersionSpecifed() @trusted
{
    return _glVersionSpecifed;
}

/++
Returns the maximum version of the shaders in the open graphics.
+/
@property string glslVersion() @trusted
{
    return _glslVersion;
}

@property string glVendor() @trusted
{
	import std.conv : to;
	
	return glGetString(GL_VENDOR).to!string;
}

@property string glRenderer() @trusted
{
	import std.conv : to;
	
	return glGetString(GL_RENDERER).to!string;
}

/++
The function loads the `OpenGL` libraries for hardware graphics acceleration.

Throws:
$(HREF https://dlang.org/library/object.html#Exception, Exception) 
if the library was not found or the context was not created to implement 
hardware acceleration.
+/
void loadGraphicsLibrary() @trusted
{
    import std.exception : enforce;
    import std.conv : to;

    bool valid(GLSupport value)
    {
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

/++
Available extensions that the framework can load with one function.
+/
enum Extensions : string
{
    textureCompression = "GL_ARB_texture_compression",
    textureArray = "GL_EXT_texture_array",
    textureClear = "GL_ARB_clear_texture"
}

/++
Checks if the extension specified in the argument is in the open graphics library.

Params:
    list =  List of extensions. Leave it blank (using the following: '[]') 
            for the function to calculate all the extensions by itself.
    name =  The name of the extension you need.

Returns:
    Extension search result. `False` if not found.
+/
bool hasExtensions(ExtList list, string name) @trusted
{
    import std.algorithm : canFind;

    if (list.length == 0)
        list = glExtensionsList();

    return list.canFind(name);
}

/++
A function that provides a list of available extensions to use.
+/
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

/++
Loads the extension `GL_ARB_texture_compression`, that is, 
extensions for loading compressed textures.

Returns:
    Returns the result of loading. False if the download is not successful.
+/
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
    GL_TEXTURE_1D_ARRAY_EXT = 0x8C18,
    GL_TEXTURE_2D_ARRAY_EXT = 0x8C1A,

    GL_TEXTURE_BINDING_1D_ARRAY_EXT = 0x8C1C,
    GL_TEXTURE_BINDING_2D_ARRAY_EXT = 0x8C1D,
    GL_MAX_ARRAY_TEXTURE_LAYERS_EXT = 0x88FF,
    GL_COMPARE_REF_DEPTH_TO_TEXTURE_EXT = 0x884E
}

alias FClearTexImage = void function (uint texture, int level,
									  int format, int type,
									  void* data);

alias FClearTexSubImage = void function(uint texture, int level,
			                            int xoffset, int yoffset, int zoffset,
			                            int width, int height, int depth,
			                            int format, int type,
			                            void* data);
									  
__gshared
{
	FClearTexImage glClearTexImageARB;
	FClearTexSubImage glClearTexSubImageARB;
}

enum
{
	GL_CLEAR_TEXTURE = 0x9365
}

/++
Loads the extension `GL_EXT_texture_array`, that is, extensions for 
loading an array of textures.

Returns:
    Returns the result of loading. False if the download is not successful.
+/
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

bool extTextureClearLoad() @trusted
{
	import bindbc.opengl.util;

	if (!hasExtensions(null, Extensions.textureClear))
		return false;
	
	if (!loadExtendedGLSymbol(cast(void**) &glClearTexImageARB,
							  "glClearTexImage"))
		return false;
		
	if (!loadExtendedGLSymbol(cast(void**) &glClearTexImageARB,
							  "glClearTexSubImage"))
		return false;
		
	return true;
}