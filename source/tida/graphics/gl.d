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
import std.experimental.logger.core;

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

extern(C) void __glLog(
    GLenum source,
    GLenum type,
    GLuint id,
    GLenum severity,
    GLsizei length,
    const(char*) message,
    const(void*) userParam
)
{
    import std.conv : to;

    string sourceID;
    string typeID;
    uint typeLog = 0;

    Logger logger = cast(Logger) userParam;

    switch (source)
    {
        case GL_DEBUG_SOURCE_API:
            sourceID = "API";
        break;

        case GL_DEBUG_SOURCE_APPLICATION:
            sourceID = "Application";
        break;

        case GL_DEBUG_SOURCE_SHADER_COMPILER:
            sourceID = "Shader Program";
        break;

        case GL_DEBUG_SOURCE_WINDOW_SYSTEM:
            sourceID = "Window system";
        break;

        case GL_DEBUG_SOURCE_THIRD_PARTY:
            sourceID = "Third party";
        break;

        default:
            sourceID = "Unknown";
    }

    switch(type)
    {
        case GL_DEBUG_TYPE_ERROR:
            typeID = "Error";
            typeLog = 1;
        break;

        case GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR:
            typeID = "Deprecated";
            typeLog = 2;
        break;

        case GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR:
            typeID = "Undefined behaviour";
            typeLog = 3;
        break;

        default:
            typeID = "Other";
        break;
    }

    final switch(typeLog)
    {
        case 0: break;

        case 1:
            logger.critical("[OpenGL][", sourceID, "](", id, ") ", message.to!string);
        break;

        case 2:
            logger.warning("[OpenGL][", sourceID, "](", id, ") ", message.to!string);
        break;

        case 3:
            logger.critical("[OpenGL][", sourceID, "](", id, ") ", message.to!string);
        break;
    }
}

void glSetupDriverLog(Logger logger) @trusted
{
    glEnable(GL_DEBUG_OUTPUT);
    glDebugMessageCallback(cast(GLDEBUGPROC) &__glLog, cast(void*) logger);
}

import tida.graphics.gapi;

class GLBuffer : IBuffer
{
    uint id;
    uint glDataUsage = GL_STATIC_DRAW;
    uint glBuff = GL_ARRAY_BUFFER;
    bool isEmpty = true;
    BufferType _type = BufferType.array;

    Logger logger;

    this(BufferType buffType, Logger Logger) @trusted
    {
        this.logger = logger;

        glCreateBuffers(1, &id);
        usage(buffType);
    }

    this(BufferType buffType) @trusted immutable
    {
        glCreateBuffers(1, cast(uint*) &id);

        if (buffType == BufferType.array)
        {
            glBuff = GL_ARRAY_BUFFER;
        } else
        if (buffType == BufferType.element)
        {
            glBuff = GL_ELEMENT_ARRAY_BUFFER;
        } else
        if (buffType == BufferType.uniform)
        {
            glBuff = GL_UNIFORM_BUFFER;
        } else
        if (buffType == BufferType.textureBuffer)
        {
            glBuff = GL_TEXTURE_BUFFER;
        } else
        if (buffType == BufferType.storageBuffer)
        {
            glBuff = GL_SHADER_STORAGE_BUFFER;
        }

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

    void[] getData(size_t length) @trusted
    {
        void[] data = new void[](length);
        glGetNamedBufferSubData(id, 0, cast(GLsizeiptr) length, data.ptr);

        return data;
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
        } else
        if (buffType == BufferType.uniform)
        {
            glBuff = GL_UNIFORM_BUFFER;
        } else
        if (buffType == BufferType.textureBuffer)
        {
            glBuff = GL_TEXTURE_BUFFER;
        } else
        if (buffType == BufferType.storageBuffer)
        {
            glBuff = GL_SHADER_STORAGE_BUFFER;
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
        debug
        {
            if (data.length == 0)
                logger.warning("There are no data for the buffer, which may be an error!");
        }

        if (isEmpty)
        {
            glNamedBufferData(id, data.length, data.ptr, glDataUsage);
            isEmpty = false;
        } else
        {
            glNamedBufferSubData(id, 0, data.length, data.ptr);
        }
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

    Logger logger;

    uint id;

    this(Logger logger) @trusted
    {
        glCreateVertexArrays(1, &id);

        this.logger = logger;
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
        debug
        {
            import std.algorithm : canFind;

            uint[] locationUse;

            if (this.buffer is null)
            {
                logger.critical("The buffer is not set for binding to the vertices!");
            }
        }

        foreach (attrib; attribs)
        {
            uint typeID = glType(attrib.type);

            debug
            {
                if (locationUse.canFind(attrib.location))
                    logger.warning("Do you need to apply data in one location two or more times?");
                else
                    locationUse ~= attrib.location;
            }

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

    Logger logger;

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
        } else
        if (type == StageType.compute)
        {
            return GL_COMPUTE_SHADER;
        }

        return 0;
    }

    this(StageType stage, Logger logger) @trusted
    {
        this._stage = stage;
        this.logger = logger;
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
            debug logger.critical("Shader is not a compile!");

            glGetShaderiv(id, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);
            glGetShaderInfoLog(id, lenLog, null, error.ptr);

            debug logger.critical("Shader log error:\n", error.to!string);

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
            debug logger.critical("Shader is not a compile!");

            glGetShaderiv(id, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);
            glGetShaderInfoLog(id, lenLog, null, error.ptr);

            debug logger.critical("Shader log error:\n", error.to!string.formatError);

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

    static struct UniformCache
    {
        uint id;
        UniformObject object;
    }

    GLShaderManip   vertex,
                    fragment,
                    geometry,
                    compute;

    UniformCache[] cache;

    void useCache(UniformCache object) @trusted
    {
        final switch(object.object.type)
        {
            case TypeBind.Float:
            {
                final switch(object.object.components)
                {
                    // vectors
                    case 1:
                        glUniform1fv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].f
                        );
                    break;

                    case 2:
                        glUniform2fv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].fv2[0]
                        );
                    break;

                    case 3:
                        glUniform3fv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].fv3[0]
                        );
                    break;

                    case 4:
                        glUniform4fv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].fv4[0]
                        );
                    break;

                    // matrixes
                    case 5:
                        glUniformMatrix2fv(
                            object.id,
                            object.object.length,
                            0,
                            &object.object.values[0].f2[0][0]
                        );
                    break;

                    case 6:
                        glUniformMatrix3fv(
                            object.id,
                            object.object.length,
                            0,
                            &object.object.values[0].f3[0][0]
                        );
                    break;

                    case 7:
                        glUniformMatrix4fv(
                            object.id,
                            object.object.length,
                            0,
                            &object.object.values[0].f4[0][0]
                        );
                    break;
                }
            }
            break;

            case TypeBind.Double:
            {
                final switch(object.object.components)
                {
                    // vectors
                    case 1:
                        glUniform1dv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].d
                        );
                    break;

                    case 2:
                        glUniform2dv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].dv2[0]
                        );
                    break;

                    case 3:
                        glUniform3dv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].dv3[0]
                        );
                    break;

                    case 4:
                        glUniform4dv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].dv4[0]
                        );
                    break;

                    // matrixes
                    case 5:
                        glUniformMatrix2dv(
                            object.id,
                            object.object.length,
                            0,
                            &object.object.values[0].d2[0][0]
                        );
                    break;

                    case 6:
                        glUniformMatrix3dv(
                            object.id,
                            object.object.length,
                            0,
                            &object.object.values[0].d3[0][0]
                        );
                    break;

                    case 7:
                        glUniformMatrix4dv(
                            object.id,
                            object.object.length,
                            0,
                            &object.object.values[0].d4[0][0]
                        );
                    break;
                }
            }
            break;

            case TypeBind.Int, TypeBind.Short, TypeBind.Byte:
            {
                final switch(object.object.components)
                {
                    // vectors
                    case 1:
                        glUniform1iv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].i
                        );
                    break;

                    case 2:
                        glUniform2iv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].iv2[0]
                        );
                    break;

                    case 3:
                        glUniform3iv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].iv3[0]
                        );
                    break;

                    case 4:
                        glUniform4iv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].iv4[0]
                        );
                    break;

                    case 5: return;
                    case 6: return;
                    case 7: return;
                }
            }
            break;

            case TypeBind.UnsignedInt, TypeBind.UnsignedShort, TypeBind.UnsignedByte:
            {
                final switch(object.object.components)
                {
                    // vectors
                    case 1:
                        glUniform1uiv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].ui
                        );
                    break;

                    case 2:
                        glUniform2uiv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].uiv2[0]
                        );
                    break;

                    case 3:
                        glUniform3uiv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].uiv3[0]
                        );
                    break;

                    case 4:
                        glUniform4uiv(
                            object.id,
                            object.object.length,
                            &object.object.values[0].uiv4[0]
                        );
                    break;

                    case 5: return;
                    case 6: return;
                    case 7: return;
                }
            }
            break;
        }
    }

    Logger logger;

    this(Logger logger) @trusted
    {
        this.logger = logger;
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

    void setUniform(uint uniformID, UniformObject uniform) @trusted
    {
        cache ~= UniformCache(uniformID, uniform);
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
        } else
        if (shader.stage == StageType.compute)
        {
            compute = cast(GLShaderManip) shader;
            glAttachShader(id, compute.id);
        }
    }

    void link() @trusted
    {
        import std.conv : to;

        debug
        {
            if (compute is null)
            {
                if (vertex is null)
                    logger.critical("There is no important element of the shader program: vertex shader.");

                if (fragment is null)
                    logger.critical("There is no important element of the shader program: fragment shader");
            }
        }

        glLinkProgram(id);

        int status;
        glGetProgramiv(id, GL_LINK_STATUS, &status);
        if (!status)
        {
            logger.critical("The shader program could not ling out!");

            int lenLog;
            char[] error;
            glGetProgramiv(id, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);

            glGetProgramInfoLog(id, lenLog, null, error.ptr);

            logger.critical("Shader program linking error log:");
            logger.critical(error.to!string);

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

    uint width = 0;
    uint height = 0;

    Logger logger;

    this(TextureType _type, Logger logger) @trusted
    {
        this._type = _type;
        this.logger = logger;

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

    uint dataType;

override:
    void active(uint value) @trusted
    {
        activeID = value;
    }

    void storage(StorageType storage, uint width, uint height) @trusted
    {
        debug
        {
            if (width == 0 || height == 0)
                logger.critical("The sizes of the image are set incorrectly (they are zero)");
        }

        if (_type == TextureType.oneDimensional)
        {
            glTextureStorage1D(id, 1, GLGraphManip.glStorageType(storage), width);

            this.width = width;
            this.height = 1;
        } else
        {
            glTextureStorage2D(id, 1, GLGraphManip.glStorageType(storage), width, height);

            this.width = width;
            this.height = height;
        }
    }

    void subImage(inout void[] data, uint width, uint height) @trusted
    {
        debug
        {
            if (data.length == 0)
                logger.critical("There can be no empty data! For cleaning, use `ITexture.clear`.");

            if (width == 0 || height == 0)
                logger.critical("The sizes of the image are set incorrectly (they are zero)");
        }

        if (_type == TextureType.oneDimensional)
        {
            glTextureSubImage1D(id, 0, 0, width, GL_RGBA, GL_UNSIGNED_BYTE, data.ptr);
        } else
        {
            glTextureSubImage2D(id, 0, 0, 0, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data.ptr);
        }

        this.dataType = GL_RGBA;
    }

    void subData(inout void[] data, uint width, uint height) @trusted
    {
        debug
        {
            if (data.length == 0)
                logger.critical("There can be no empty data! For cleaning, use `ITexture.clear`.");

            if (width == 0 || height == 0)
                logger.critical("The sizes of the image are set incorrectly (they are zero)");
        }

        if (_type == TextureType.oneDimensional)
        {
            glTextureSubImage1D(id, 0, 0, width, GL_RED, GL_FLOAT, data.ptr);
        } else
        {
            glTextureSubImage2D(id, 0, 0, 0, width, height, GL_RED, GL_FLOAT, data.ptr);
        }

        this.dataType = GL_RED;
    }

    void[] getData() @trusted
    {
        immutable dt = this.dataType == GL_RGBA ? GL_UNSIGNED_BYTE : GL_FLOAT;
        void[] data = new void[](width * height * (dt == GL_UNSIGNED_BYTE ? 4 : float.sizeof));

        glGetTextureImage(id, 0, this.dataType, dt, cast(int) data.length, data.ptr);

        return data;
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

    void params(uint[] parameters) @trusted
    {
        import std.range : chunks;

        foreach (kv; chunks(parameters, 2))
        {
            if (kv[0] >= TextureFilter.min &&
                kv[0] <= TextureFilter.max)
            {
                filter(
                    cast(TextureFilter) kv[0],
                    cast(TextureFilterValue) kv[1]
                );
            } else
            if (kv[0] >= TextureWrap.min &&
                kv[0] <= TextureWrap.max)
            {
                wrap(
                    cast(TextureWrap) kv[0],
                    cast(TextureWrapValue) kv[1]
                );
            } else
            {
                debug
                {
                    logger.warning("Unknown parameters for the texture.");
                }
            }
        }
    }
}

class GLFrameBuffer : IFrameBuffer
{
    uint id = 0;
    uint rid = 0;

    uint width = 0;
    uint height = 0;

    this() @trusted
    {
        glCreateFramebuffers(1, &id);
    }

    this(uint index) @safe
    {
        id = index;
    }

    ~this() @trusted
    {
        if (id != 0)
        {
            glDeleteFramebuffers(1, &id);
        }

        if (rid != 0)
        {
            glDeleteRenderbuffers(1, &rid);
        }
    }

override:
    void generateBuffer(uint width, uint height) @trusted
    {
        this.width = width;
        this.height = height;

        if (rid != 0)
        {
            glDeleteRenderbuffers(1, &rid);
        }

        glCreateRenderbuffers(1, &rid);

        glNamedRenderbufferStorage(rid, GL_RGBA8, width, height);
        glNamedFramebufferRenderbuffer(id, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, rid);
    }

    void attach(ITexture texture) @trusted
    {
        GLTexture tex = cast(GLTexture) texture;

        glNamedFramebufferTexture(id, GL_COLOR_ATTACHMENT0, tex.id, 0);

        width = tex.width;
        height = tex.height;
    }

    void clear(Color!ubyte color) @trusted
    {
        glClearNamedFramebufferfv(id, GL_COLOR, 0, [color.rf, color.gf, color.bf, color.af].ptr);
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

            debug
            {
                scope(failure)
                    logger.critical("GLX library is not a loaded!");
            }
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

            version(UnsupportNewFeature)
            {
                _context = glXCreateNewContext( display, this.bestFbcs,
                                                GLX_RGBA_TYPE, null, true);
            } else
            {
                int[] ctxAttrib = [
                    GLX_CONTEXT_MAJOR_VERSION_ARB, 4,
                    GLX_CONTEXT_MINOR_VERSION_ARB, 6,
                    None
                ];
                _context = glXCreateContextAttribsARB(display, this.bestFbcs, null, true, ctxAttrib.ptr);
                enforce!Exception(_context);
            }

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

            debug
            {
                scope(failure)
                    logger.critical("Window or/and context is not a created!");
            }
        }
    }

    GLShaderProgram currentProgram;
    GLVertexInfo currentVertex;
    GLTexture[] currentTexture;
    GLFrameBuffer mainFB;
    GLFrameBuffer currentFB;
    GLBuffer[] buffers;

    Color!ubyte _clearColor = Color!ubyte.init;

    Logger logger;

    this() @trusted
    {
        debug
        {
            logger = stdThreadLocalLog;
        }
    }

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

    alias glComputeType = glStorageType;

    static uint glStorageType(StorageType type)
    {
        final switch(type)
        {
            case ComputeDataType.r32f:
                return GL_R32F;

            case ComputeDataType.rgba32f:
                return GL_RGBA32F;

            case ComputeDataType.rg32f:
                return GL_RG32F;

            case ComputeDataType.rgba32ui:
                return GL_RGBA32UI;

            case ComputeDataType.rgba32i:
                return GL_RGBA32I;

            case ComputeDataType.r32ui:
                return GL_R32UI;

            case ComputeDataType.r32i:
                return GL_R32I;

            case ComputeDataType.rgba8i:
                return GL_RGBA8I;

            case ComputeDataType.rgba8:
                return GL_RGBA8;

            case ComputeDataType.r8i:
                return GL_R8I;
        }
    }

override:
    void initialize() @trusted
    {
        logger.info("Load shared libs...");
        version(Posix)
        {
            initializePosixImpl();
        } else
        version(Windows)
        {
            initializeWinInpl();
        }
        logger.info("Success!");
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

        mainFB = new GLFrameBuffer(0);
        currentFB = mainFB;
    }

    void update() @trusted
    {

    }

    void viewport(float x, float y, float w, float h) @trusted
    {
        debug
        {
            if (w < 0 || h < 0)
                logger.warning("The port size is incorrectly set!");
        }

        glViewport(
            cast(uint) x,
            cast(uint) y,
            cast(uint) w,
            cast(uint) h
        );

        currentFB.width = cast(uint) w;
        currentFB.height = cast(uint) h;
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
        _clearColor = color;
    }

    void clear() @trusted
    {
        currentFB.clear(_clearColor);
    }

    void begin() @trusted
    {
        debug
        {
            if (currentVertex is null)
                logger.warning("The peaks for drawing are not set!");

            if (currentProgram is null)
                logger.warning("A shader program for drawing are not set!");
        }

        glBindFramebuffer(GL_FRAMEBUFFER, currentFB.id);

        if (currentVertex !is null)
        {
            glBindVertexArray(currentVertex.id);
        }

        if (currentProgram !is null)
        {
            currentProgram.use();
        }

        if (currentProgram !is null)
        {
            foreach (e; currentTexture)
            {
                glBindTextureUnit(e.activeID, e.id);
            }
        }
    }

    void compute(ComputeDataType[] type) @trusted
    {
        import std.algorithm : map;
        import std.range : array;

        if (currentProgram !is null)
        {
            currentProgram.use();
        }

        foreach (size_t i, GLTexture e; currentTexture)
        {
            glBindImageTexture(e.activeID, e.id, 0, false, 0, GL_WRITE_ONLY, glComputeType(type[i]));
        }

        if (buffers.length > 0)
        {
            uint[] ids = buffers.map!(e => e.id).array;
            glBindBuffersBase(GL_SHADER_STORAGE_BUFFER, 0, cast(int) ids.length, ids.ptr);
        }

        if (currentTexture.length == 0)
        {
            glDispatchCompute(1, 1, 1);
        } else
        {
            glDispatchCompute(currentTexture[0].width, currentTexture[0].height, 1);
        }

        glMemoryBarrier(GL_ALL_BARRIER_BITS);

        buffers = [];
        currentTexture = [];
    }

    void draw(ModeDraw mode, uint first, uint count) @trusted
    {
        foreach (e; currentProgram.cache)
        {
            currentProgram.useCache(e);
        }

        currentProgram.cache.length = 0;

        uint gmode = glMode(mode);

        glDrawArrays(gmode, first, count);

        glBindFramebuffer(GL_FRAMEBUFFER, 0);

        currentProgram = null;
        currentVertex = null;
        currentTexture.length = 0;
    }

    void drawIndexed(ModeDraw mode, uint icount) @trusted
    {
        foreach (e; currentProgram.cache)
        {
            currentProgram.useCache(e);
        }

        currentProgram.cache.length = 0;

        uint gmode = glMode(mode);

        glDrawElements(gmode, icount, GL_UNSIGNED_INT, null);

        currentProgram = null;
        currentVertex = null;
        currentTexture.length = 0;
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
        if (texture is null)
        {
            debug
            {
                logger.warning("The zero pointer is sent to the function, which may be an error.");
            }

            return;
        }

        currentTexture ~= cast(GLTexture) texture;
    }

    void bindBuffer(IBuffer buffer) @trusted
    {
        if (buffer is null)
        {
            debug
            {
                logger.warning("The zero pointer is sent to the function, which may be an error.");
            }

            return;
        }

        GLBuffer bf = cast(GLBuffer) buffer;

        debug
        {
            if (bf._type != BufferType.storageBuffer)
            {
                logger.warning("A buffer is introduced that cannot serve for calculations. In other situations, it will not be used.");
            }
        }

        this.buffers ~= bf;
    }

    void drawning() @trusted
    {
        if (currentFB !is mainFB)
        {
            glBlitNamedFramebuffer(
                currentFB.id,
                mainFB.id,
                0, 0,
                currentFB.width, currentFB.height,
                0, 0,
                mainFB.width, mainFB.height,
                GL_COLOR_BUFFER_BIT,
                GL_LINEAR
            );
        }

        version(Posix)
        {
            glXSwapBuffers(display, window.handle);
        }
    }

    void setFrameBuffer(IFrameBuffer ifb) @trusted
    {
        if (ifb is null)
        {
            currentFB = mainFB;
        } else
        {
            currentFB = cast(GLFrameBuffer) ifb;
        }
    }

    IShaderManip createShader(StageType stage) @trusted
    {
        return new GLShaderManip(stage, logger);
    }

    IShaderProgram createShaderProgram() @trusted
    {
        return new GLShaderProgram(logger);
    }

    IBuffer createBuffer(BufferType buffType = BufferType.array) @trusted
    {
        return new GLBuffer(buffType, logger);
    }

    immutable(IBuffer) createImmutableBuffer(BufferType buffType = BufferType.array) @trusted
    {
        return new immutable GLBuffer(buffType);
    }

    IVertexInfo createVertexInfo() @trusted
    {
        return new GLVertexInfo(logger);
    }

    ITexture createTexture(TextureType type) @trusted
    {
        return new GLTexture(type, logger);
    }

    IFrameBuffer createFrameBuffer() @trusted
    {
        return new GLFrameBuffer();
    }

    IFrameBuffer mainFrameBuffer() @trusted
    {
        return mainFB;
    }

    debug
    {
        void setupLogger(Logger logger = stdThreadLocalLog) @safe
        {
            glSetupDriverLog(logger);
            this.logger = logger;
        }
    }
}
