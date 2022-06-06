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
module tida.graphics.gl;

version(GraphBackendVulkan) {} else:
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
Indicates whether the use of geometry shaders is supported on this device.
+/
@property bool glGeometrySupport() @trusted
{
    ExtList extensions = glExtensionsList();

    return 	hasExtensions(extensions, Extensions.geometryShaderARB) ||
            hasExtensions(extensions, Extensions.geometryShaderEXT) ||
            hasExtensions(extensions, Extensions.geometryShaderNV);
}

@property bool glSpirvSupport() @trusted
{
    ExtList extensions = glExtensionsList();

    if (hasExtensions(extensions, Extensions.glSpirvARB))
    {
        int param;
        glGetIntegerv(GL_NUM_PROGRAM_BINARY_FORMATS, &param);

        return param != 0;
    } else
        return false;
}

/++
Returns the maximum version of the shaders in the open graphics.
+/
@property string glslVersion() @trusted
{
    return _glslVersion;
}

@property uint glError() @trusted
{
    return glGetError();
}

@property string glErrorMessage(immutable uint err) @trusted
{
    string error;

    switch (err)
    {
        case GL_INVALID_ENUM:
            error = "Invalid enum!";
            break;

        case GL_INVALID_VALUE:
            error = "Invalid input value!";
            break;

        case GL_INVALID_OPERATION:
            error = "Invalid operation!";
            break;

        case GL_STACK_OVERFLOW:
            error = "Stack overflow!";
            break;

        case GL_STACK_UNDERFLOW:
            error = "Stack underflow!";
            break;

        case GL_OUT_OF_MEMORY:
            error = "Out of memory!";
            break;

        case GL_INVALID_FRAMEBUFFER_OPERATION:
            error = "Invalid framebuffer operation!";
            break;

        default:
            error = "Unkown error!";
    }

    return error;
}

void checkGLError(
    string file = __FILE__,
    size_t line = __LINE__,
    string func = __FUNCTION__
) @safe
{
    immutable err = glError();
    if (err != GL_NO_ERROR)
    {
        throw new Exception(
            "In function `" ~ func ~ "` discovered error: `" ~ glErrorMessage(err) ~ "`.",
            file,
            line
        );
    }
}

void assertGLError(
    lazy uint checked,
    string file = __FILE__,
    size_t line = __LINE__,
    string func = __FUNCTION__
) @safe
{
    immutable err = checked();
    if (err != GL_NO_ERROR)
    {
        throw new Exception(
            "In function `" ~ func ~ "` discovered error: `" ~ glErrorMessage(err) ~ "`.",
            file,
            line
        );
    }
}

/++
Returns the company responsible for this GL implementation.
This name does not change from release to release.

See_Also:
    $(HREF https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetString.xhtml, OpenGL Reference - glGetString)
+/
@property string glVendor() @trusted
{
    import std.conv : to;

    return glGetString(GL_VENDOR).to!string;
}

/++
Returns the name of the renderer.
This name is typically specific to a particular configuration of a hardware platform.
It does not change from release to release.

See_Also:
    $(HREF https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetString.xhtml, OpenGL Reference - glGetString)
+/
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
    /++
    Compressing texture images can reduce texture memory utilization and
    improve performance when rendering textured primitives.

    See_Also:
        $(HREF https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_texture_compression.txt, OpenGL reference "GL_ARB_texture_compression")
    +/
    textureCompression = "GL_ARB_texture_compression",

    /++
    This extension introduces the notion of one- and two-dimensional array
    textures.  An array texture is a collection of one- and two-dimensional
    images of identical size and format, arranged in layers.

    See_Also:
        $(HREF https://www.khronos.org/registry/OpenGL/extensions/EXT/EXT_texture_array.txt, OpenGL reference "GL_EXT_texture_array")
    +/
    textureArray = "GL_EXT_texture_array",

    /++
    Texture objects are fundamental to the operation of OpenGL. They are
    used as a source for texture sampling and destination for rendering
    as well as being accessed in shaders for image load/store operations
    It is also possible to invalidate the contents of a texture. It is
    currently only possible to set texture image data to known values by
    uploading some or all of a image array from application memory or by
    attaching it to a framebuffer object and using the Clear or ClearBuffer
    commands.

    See_Also:
        $(HREF https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_clear_texture.txt, OpenGL reference "GL_ARB_clear_texture")
    +/
    textureClear = "GL_ARB_clear_texture",

    /++
    ARB_geometry_shader4 defines a new shader type available to be run on the
    GPU, called a geometry shader. Geometry shaders are run after vertices are
    transformed, but prior to color clamping, flat shading and clipping.

    See_Also:
        $(HREF https://www.khronos.org/registry/OpenGL/extensions/ARB/ARB_geometry_shader4.txt, OpenGL reference "GL_ARB_geometry_shader4")
    +/
    geometryShaderARB = "GL_ARB_geometry_shader4",

    /// ditto
    geometryShaderEXT = "GL_EXT_geometry_shader4",

    /// ditto
    geometryShaderNV = "GL_NV_geometry_shader4",

    glSpirvARB = "GL_ARB_gl_spirv"
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
alias FCompressedTexImage2DARB = extern(C) void function(GLenum target,
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
alias FFramebufferTextureLayerEXT = extern(C) void function();

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

string formatError(string error) @safe pure
{
    import std.array : replace;

    error = error.replace("error","\x1b[1;91merror\x1b[0m");

    return error;
}

import tida.graphics.gapi;

class GLBuffer : IBuffer
{
    uint id;
    uint glDataUsage = GL_STATIC_DRAW;
    uint glBuff = GL_ARRAY_BUFFER;
    bool isEmpty = true;
    BufferType _type = BufferType.array;

    this(BufferType buffType) @trusted
    {
        glCreateBuffers(1, &id);
        this._type = buffType;
    }

    this(BufferType buffType) @trusted immutable
    {
        glCreateBuffers(1, cast(uint*) &id);
        this._type = buffType;
    }

    void bind() @trusted
    {
        glBindBuffer(glBuff, id);
    }

    void bind() @trusted immutable
    {
        glBindBuffer(glBuff, id);
    }

    ~this() @trusted
    {
        glDeleteBuffers(1, &id);

        id = 0;
    }

override:
    void usage(BufferType buffType) @trusted
    {
        if (buffType == BufferType.array)
        {
            glBuff = GL_ARRAY_BUFFER;
        } else
        if (buffType == BufferType.element)
        {
            glBuff = GL_ELEMENT_ARRAY_BUFFER;
        }

        this._type = buffType;
    }

    @property BufferType type() @trusted inout
    {
        return this._type;
    }

    void dataUsage(BuffUsageType type) @trusted
    {
        if (type == BuffUsageType.staticData)
            glDataUsage =  GL_STATIC_DRAW;
        else
        if (type == BuffUsageType.dynamicData)
            glDataUsage = GL_DYNAMIC_DRAW;
    }

    void bindData(inout void[] data) @trusted
    {
        checkGLError();

        if (id == 0)
            assert(null);

        if (isEmpty)
        {
            glNamedBufferData(id, data.length, data.ptr, glDataUsage);
            isEmpty = false;
        } else
        {
            glNamedBufferSubData(id, 0, data.length, data.ptr);
        }

        checkGLError();
    }

    void bindData(inout void[] data) @trusted immutable
    {
        glNamedBufferStorage(id, data.length, data.ptr, GL_MAP_READ_BIT);
    }

    void clear() @trusted
    {
        glNamedBufferData(id, 0, null, glDataUsage);
    }
}

class GLVertexInfo : IVertexInfo
{
    GLBuffer buffer;
    GLBuffer indexBuffer;

    uint id;

    this() @trusted
    {
        glCreateVertexArrays(1, &id);
    }

    ~this() @trusted
    {
        glDeleteVertexArrays(1, &id);
    }

    uint glType(TypeBind tb) @safe
    {
        final switch (tb)
        {
            case TypeBind.Byte:
                return GL_BYTE;

            case TypeBind.UnsignedByte:
                return GL_UNSIGNED_BYTE;

            case TypeBind.Short:
                return GL_SHORT;

            case TypeBind.UnsignedShort:
                return GL_UNSIGNED_SHORT;

            case TypeBind.Int:
                return GL_INT;

            case TypeBind.UnsignedInt:
                return GL_UNSIGNED_INT;

            case TypeBind.Float:
                return GL_FLOAT;

            case TypeBind.Double:
                return GL_DOUBLE;
        }
    }

override:
    void bindBuffer(inout IBuffer buffer) @trusted
    {
        if (buffer.type == BufferType.array)
        {
            this.buffer = cast(GLBuffer) buffer;
        } else
        if (buffer.type == BufferType.element)
        {
            this.indexBuffer = cast(GLBuffer) buffer;
        }
    }

    void vertexAttribPointer(AttribPointerInfo[] attribs) @trusted
    {
        foreach (attrib; attribs)
        {
            uint typeID = glType(attrib.type);

            glVertexArrayVertexBuffer(
                id,
                0,
                buffer.id,
                0,
                attrib.stride
            );

            if(indexBuffer !is null)
                glVertexArrayElementBuffer(id, indexBuffer.id);

            glEnableVertexArrayAttrib(id, attrib.location);

            glVertexArrayAttribFormat(id, attrib.location, attrib.components, typeID, false, attrib.offset);

            glVertexArrayAttribBinding(id, attrib.location, 0);
        }
    }
}

class GLShaderManip : IShaderManip
{
    StageType _stage;
    uint id;

    uint glStage(StageType type) @safe
    {
        if (type == StageType.vertex)
        {
            return GL_VERTEX_SHADER;
        } else
        if (type == StageType.fragment)
        {
            return GL_FRAGMENT_SHADER;
        } else
        if (type == StageType.geometry)
        {
            return GL_GEOMETRY_SHADER;
        }

        return 0;
    }

    this(StageType stage) @trusted
    {
        this._stage = stage;
        id = glCreateShader(glStage(stage));
    }

    ~this() @trusted
    {
        glDeleteShader(id);
    }

override:
    void loadFromSource(string source) @trusted
    {
        import std.conv : to;

        const int len = cast(const(int)) source.length;
        glShaderSource(id, 1, [source.ptr].ptr, &len);
        glCompileShader(id);

        char[] error;
        int result;
        int lenLog;

        glGetShaderiv(id, GL_COMPILE_STATUS, &result);
        if (!result)
        {
            glGetShaderiv(id, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);
            glGetShaderInfoLog(id, lenLog, null, error.ptr);

            throw new Exception("Shader compile error:\n" ~ error.to!string.formatError);
        }
    }

    void loadFromMemory(void[] memory) @trusted
    {
        import std.conv : to;

        if (!glSpirvSupport())
            return;

        glShaderBinary(1, &id, GL_SHADER_BINARY_FORMAT_SPIR_V, memory.ptr, cast(uint) memory.length);
        glSpecializeShader(id, "main", 0, null, null);

        char[] error;
        int result;
        int lenLog;

        glGetShaderiv(id, GL_COMPILE_STATUS, &result);
        if (!result)
        {
            glGetShaderiv(id, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);
            glGetShaderInfoLog(id, lenLog, null, error.ptr);

            throw new Exception("Shader compile error:\n" ~ error.to!string.formatError);
        }
    }

    @property StageType stage() @safe
    {
        return _stage;
    }
}

class GLShaderProgram : IShaderProgram
{
    uint id;

    GLShaderManip   vertex,
                    fragment,
                    geometry;

    this() @trusted
    {
        id = glCreateProgram();
    }

    ~this() @trusted
    {
        glDeleteProgram(id);
    }

    void use() @trusted
    {
        glUseProgram(id);
    }
override:
    uint getUniformID(string name) @trusted
    {
        import std.string : toStringz;

        return glGetUniformLocation(id, name.toStringz);
    }

    void setUniform(uint uniformID, uint value) @trusted
    {
        glUniform1ui(uniformID, value);
    }

    void setUniform(uint uniformID, int value) @trusted
    {
        glUniform1i(uniformID, value);
    }

    void setUniform(uint uniformID, float value) @trusted
    {
        glUniform1f(uniformID, value);
    }

    void setUniform(uint uniformID, float[2] value) @trusted
    {
        glUniform2f(uniformID, value[0], value[1]);
    }

    void setUniform(uint uniformID, float[3] value) @trusted
    {
        glUniform3f(uniformID, value[0], value[1], value[2]);
    }

    void setUniform(uint uniformID, float[4] value) @trusted
    {
        glUniform4f(uniformID, value[0], value[1], value[2], value[3]);
    }

    void setUniform(uint uniformID, float[2][2] value) @trusted
    {
        glUniformMatrix2fv(uniformID, 1, false, value[0].ptr);
    }

    void setUniform(uint uniformID, float[3][3] value) @trusted
    {
        glUniformMatrix3fv(uniformID, 1, false, value[0].ptr);
    }

    void setUniform(uint uniformID, float[4][4] value) @trusted
    {
        glUniformMatrix4fv(uniformID, 1, false, value[0].ptr);
    }

    void attach(IShaderManip shader) @trusted
    {
        if (shader.stage == StageType.vertex)
        {
            vertex = cast(GLShaderManip) shader;
            glAttachShader(id, vertex.id);
        } else
        if (shader.stage == StageType.fragment)
        {
            fragment = cast(GLShaderManip) shader;
            glAttachShader(id, fragment.id);
        } else
        if (shader.stage == StageType.geometry)
        {
            geometry = cast(GLShaderManip) shader;
            glAttachShader(id, geometry.id);
        }
    }

    void link() @trusted
    {
        import std.conv : to;

        glLinkProgram(id);

        int status;
        glGetProgramiv(id, GL_LINK_STATUS, &status);
        if (!status)
        {
            int lenLog;
            char[] error;
            glGetProgramiv(id, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);

            glGetProgramInfoLog(id, lenLog, null, error.ptr);

            throw new Exception(error.to!string.formatError);
        }
    }
}

class GLTexture : ITexture
{
    uint id;
    uint glType;
    TextureType _type;
    uint activeID = 0;

    this(TextureType _type) @trusted
    {
        this._type = _type;

        if (_type == TextureType.oneDimensional)
            glType = GL_TEXTURE_1D;
        else
        if (_type == TextureType.twoDimensional)
            glType = GL_TEXTURE_2D;
        else
        if (_type == TextureType.threeDimensional)
            glType = GL_TEXTURE_3D;

        glCreateTextures(glType, 1, &id);
    }

    ~this() @trusted
    {
        glDeleteTextures(1, &id);
    }

    uint toGLWrap(TextureWrap wrap) @safe
    {
        if (wrap == TextureWrap.wrapR)
            return GL_TEXTURE_WRAP_R;
        else
        if (wrap == TextureWrap.wrapS)
            return GL_TEXTURE_WRAP_S;
        else
            return GL_TEXTURE_WRAP_T;
    }

    uint tpGLWrapValue(TextureWrapValue value) @safe
    {
        if (value == TextureWrapValue.clampToEdge)
            return GL_CLAMP_TO_EDGE;
        else
        if (value == TextureWrapValue.mirroredRepeat)
            return GL_MIRRORED_REPEAT;
        else
            return GL_REPEAT;
    }

    uint toGLFilter(TextureFilter filter) @safe
    {
        if (filter == TextureFilter.minFilter)
            return GL_TEXTURE_MIN_FILTER;
        else
            return GL_TEXTURE_MAG_FILTER;
    }

    uint toGLFilterValue(TextureFilterValue value) @safe
    {
        if (value == TextureFilterValue.nearest)
            return GL_NEAREST;
        else
            return GL_LINEAR;
    }

override:
    void active(uint value) @trusted
    {
        activeID = value;
        glBindTextureUnit(activeID, id);
    }

    void append(inout void[] data, uint width, uint height) @trusted
    {
        glBindTextureUnit(activeID, id);

        glTextureStorage2D(id, 1, GL_RGBA8, width, height);
        glTextureSubImage2D(id, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data.ptr);

        checkGLError();
    }

    void wrap(TextureWrap wrap, TextureWrapValue value) @trusted
    {
        uint    glWrap = toGLWrap(wrap),
                glWrapValue = tpGLWrapValue(value);

        glTextureParameteri(id, glWrap, glWrapValue);
    }

    void filter(TextureFilter filter, TextureFilterValue value) @trusted
    {
        uint    glFilter = toGLFilter(filter),
                glFilterValue = toGLFilterValue(value);

        glTextureParameteri(id, glFilter, glFilterValue);
    }
}

class GLGraphManip : IGraphManip
{
    import tdw = tida.window;

    version(Posix)
    {
        import x11.X;
        import x11.Xlib;
        import x11.Xutil;
        import tida.runtime;
        import dglx.glx;

        version(UseXCB)
        {
            import xcb.xcb;

            enum GLX_VISUAL_ID = 0x800b;
            xcb_visualid_t visualID;
        }

        tdw.Window window;
        Display* display;
        uint displayID;
        XVisualInfo* visualInfo;
        GLXContext _context;
        GLXFBConfig bestFbcs;

        void initializePosixImpl() @trusted
        {
            version(UseXCB)
            {
                display = XOpenDisplay(null);
                displayID = DefaultScreen(display);
            } else
            {
                display = runtime.display;
                displayID = runtime.displayID;
            }

            loadGLXLibrary();
        }

        void createPosixImpl(tdw.Window window, GraphicsAttributes attribs) @trusted
        {
            import dglx.glx;
            version(UseXCB) import xcb.xcb;
            import std.exception : enforce;
            import std.conv : to;

            this.window = window;

            int[] glxAttributes =
            [
                GLX_X_RENDERABLE    , True,
                GLX_DRAWABLE_TYPE   , GLX_WINDOW_BIT,
                GLX_RENDER_TYPE     , GLX_RGBA_BIT,
                GLX_X_VISUAL_TYPE   , GLX_TRUE_COLOR,
                GLX_RED_SIZE        , attribs.redSize,
                GLX_GREEN_SIZE      , attribs.greenSize,
                GLX_BLUE_SIZE       , attribs.blueSize,
                GLX_ALPHA_SIZE      , attribs.alphaSize,
                GLX_DOUBLEBUFFER    , attribs.bufferMode == BufferMode.doubleBuffer ? 1 : 0,
                None
            ];

            int fbcount = 0;
            scope fbc = glXChooseFBConfig(  display, displayID,
                                            glxAttributes.ptr, &fbcount);
            scope(success) XFree(fbc);
            enforce!Exception(fbc);

            int bestFbc = -1, bestNum = -1;
            foreach (int i; 0 .. fbcount)
            {
                int sampBuff, samples;
                glXGetFBConfigAttrib(   display, fbc[i],
                                        GLX_SAMPLE_BUFFERS, &sampBuff);
                glXGetFBConfigAttrib(   display, fbc[i],
                                        GLX_SAMPLES, &samples);

                if (bestFbc < 0 || (sampBuff && samples > bestNum))
                {
                    bestFbc = i;
                    bestNum = samples;
                }
            }

            this.bestFbcs = fbc[bestFbc];
            enforce!Exception(bestFbcs);

            version(UseXCB)
            {
                glXGetFBConfigAttrib(display, bestFbcs, GLX_VISUAL_ID , cast(int*) &visualID);
            } else
            {
                this.visualInfo = glXGetVisualFromFBConfig(runtime.display, bestFbcs);
                enforce!Exception(visualInfo);
            }

            _context = glXCreateNewContext( display, this.bestFbcs,
                                            GLX_RGBA_TYPE, null, true);

            window.destroy();

            version(UseXCB)
            {
                window.createFromVisual(visualID, 100, 100);
                glXMakeCurrent(display, window.handle, _context);
            } else
            {
                window.createFromXVisual(visualInfo, 100, 100);
                glXMakeCurrent(display, window.handle, _context);
            }

            window.show();
        }
    }

    GLShaderProgram currentProgram;
    GLVertexInfo currentVertex;
    GLTexture currentTexture;

    int glMode(ModeDraw mode)
    {
        if (mode == ModeDraw.points)
            return GL_POINTS;
        else
        if (mode == ModeDraw.line)
            return GL_LINES;
        else
        if (mode == ModeDraw.lineStrip)
            return GL_LINE_STRIP;
        else
        if (mode == ModeDraw.triangle)
            return GL_TRIANGLES;
        else
        if (mode == ModeDraw.triangleStrip)
            return GL_TRIANGLE_FAN;

        return 0;
    }

override:
    void initialize() @trusted
    {
        version(Posix)
        {
            initializePosixImpl();
        } else
        version(Windows)
        {
            initializeWinInpl();
        }
    }

    void createAndBindSurface(tdw.Window window, GraphicsAttributes attribs) @trusted
    {
        version(Posix)
        {
            createPosixImpl(window, attribs);
        } else
        version(Windows)
        {
            createWinImpl(window, attribs);
        }

        loadGraphicsLibrary();
    }

    void update() @trusted
    {

    }

    void viewport(float x, float y, float w, float h) @trusted
    {
        glViewport(
            cast(uint) x,
            cast(uint) y,
            cast(uint) w,
            cast(uint) h
        );
    }

    void blendFactor(BlendFactor src, BlendFactor dst, bool state) @trusted
    {
        int glBlendFactor(BlendFactor factor)
        {
            if (factor == BlendFactor.Zero)
                return GL_ZERO;
            else
            if (factor == BlendFactor.One)
                return GL_ONE;
            else
            if (factor == BlendFactor.SrcColor)
                return GL_SRC_COLOR;
            else
            if (factor == BlendFactor.DstColor)
                return GL_DST_COLOR;
            else
            if (factor == BlendFactor.OneMinusSrcColor)
                return GL_ONE_MINUS_SRC_COLOR;
            else
            if (factor == BlendFactor.OneMinusDstColor)
                return GL_ONE_MINUS_DST_COLOR;
            else
            if (factor == BlendFactor.SrcAlpha)
                return GL_SRC_ALPHA;
            else
            if (factor == BlendFactor.DstAlpha)
                return GL_DST_ALPHA;
            else
            if (factor == BlendFactor.OneMinusSrcAlpha)
                return GL_ONE_MINUS_SRC_ALPHA;
            else
            if (factor == BlendFactor.OneMinusDstAlpha)
                return GL_ONE_MINUS_DST_ALPHA;

            return 0;
        }

        glBlendFunc(glBlendFactor(src), glBlendFactor(dst));

        if (state)
            glEnable(GL_BLEND);
        else
            glDisable(GL_BLEND);
    }

    void clearColor(Color!ubyte color) @trusted
    {
        glClearColor(color.rf, color.gf, color.bf, color.af);
    }

    void clear() @trusted
    {
        glClear(GL_COLOR_BUFFER_BIT);
    }

    void begin() @trusted
    {
        if (currentVertex !is null)
            glBindVertexArray(currentVertex.id);

        if (currentProgram !is null)
            currentProgram.use();

        if (currentTexture !is null)
        {
            glBindTexture(currentTexture.glType, currentTexture.id);
            currentTexture.active(currentTexture.activeID);
        }
    }

    void draw(ModeDraw mode, uint first, uint count) @trusted
    {
        uint gmode = glMode(mode);

        glDrawArrays(gmode, first, count);
    }

    void drawIndexed(ModeDraw mode, uint icount) @trusted
    {
        uint gmode = glMode(mode);

        glDrawElements(gmode, icount, GL_UNSIGNED_INT, null);
    }

    void bindProgram(IShaderProgram program) @trusted
    {
        currentProgram = cast(GLShaderProgram) program;
    }

    void bindVertexInfo(IVertexInfo vertInfo) @trusted
    {
        currentVertex = cast(GLVertexInfo) vertInfo;
    }

    void bindTexture(ITexture texture) @trusted
    {
        currentTexture = cast(GLTexture) texture;
    }

    void drawning() @trusted
    {
        glXSwapBuffers(display, window.handle);
    }

    IShaderManip createShader(StageType stage) @trusted
    {
        return new GLShaderManip(stage);
    }

    IShaderProgram createShaderProgram() @trusted
    {
        return new GLShaderProgram();
    }

    IBuffer createBuffer(BufferType buffType = BufferType.array) @trusted
    {
        return new GLBuffer(buffType);
    }

    immutable(IBuffer) createImmutableBuffer(BufferType buffType = BufferType.array) @trusted
    {
        return new immutable GLBuffer(buffType);
    }

    IVertexInfo createVertexInfo() @trusted
    {
        return new GLVertexInfo();
    }

    ITexture createTexture(TextureType type) @trusted
    {
        return new GLTexture(type);
    }
}
