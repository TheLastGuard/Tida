module tida.graphics.gapi;

import tida.window;
public import tida.color;

/++
The permissible number of buffers for the output.
+/
enum BufferMode
{
    singleBuffer,
    doubleBuffer,
    troubleBuffer
}

/++
Graphics attributes for creating a special graphics pipeline
(default parameters are indicated in the structure).
+/
struct GraphicsAttributes
{
    int redSize = 8; /// Red size
    int greenSize = 8; /// Green size
    int blueSize = 8; /// Blue size
    int alphaSize = 8; /// Alpha channel size
    int colorDepth = 32; /// Color depth (pack in sample)
    BufferMode bufferMode = BufferMode.doubleBuffer;
}

/++
Type of shader program pass stage.
+/
enum StageType
{
    vertex, /// Vertex stage
    fragment, /// Fragment stage
    geometry, /// Geometry stage
    compute /// Compute stage
}

/++
The type of the rendered primitive.
+/
enum ModeDraw
{
    points, /// Points
    line, /// Lines
    lineStrip, /// Lines loop
    triangle, /// Triangles
    triangleStrip /// Triangles loop
}

/++
The type of buffer to use.
+/
enum BuffUsageType
{
    /// The buffer will use as few data modification operations as possible.
    staticData,

    /// The buffer assumes constant operations with buffer memory.
    dynamicData
}

/++
The type of buffer to use.
+/
enum BufferType
{
    /// Use as data buffer
    array,

    /// Use as buffer for indexing
    element,

    /// Use as buffer for uniforms structs
    uniform,

    /// Use as buffer for texture pixel buffer
    textureBuffer,

    /// Use as buffer for compute buffer
    storageBuffer
}

/++
The data buffer object. Can be created mutable and immutable.
+/
interface IBuffer
{
    /// How to use buffer.
    void usage(BufferType) @safe;

    /// Buffer type.
    @property BufferType type() @safe inout;

    /// Specifying the buffer how it will be used.
    void dataUsage(BuffUsageType) @safe;

    /// Attach data to buffer. If the data is created as immutable, the data can
    /// only be entered once.
    void bindData(inout void[] data) @safe;

    /// ditto
    void bindData(inout void[] data) @safe immutable;

    void[] getData(size_t) @safe;

    /// Clears data. If the data is immutable, then the method will throw an
    /// exception.
    void clear() @safe;
}

/// Type binded
enum TypeBind
{
    Byte,
    UnsignedByte,
    Short,
    UnsignedShort,
    Int,
    UnsignedInt,
    Float,
    Double
}

alias UniformType = TypeBind;

/++
Information about buffer bindings to vertices.
+/
struct AttribPointerInfo
{
    /// The location of the input vertex.
    uint location;

    /// The number of components per vertex.
    uint components;

    ///
    TypeBind type;

    /// Specifies the byte offset between consecutive generic vertex attributes.
    uint stride;

    /// The byte offset in the data buffer.
    uint offset;
}

/// Object of information about buffer binding to shader vertices.
interface IVertexInfo
{
    /// Attach a buffer to an object.
    void bindBuffer(inout IBuffer) @safe;

    /// Describe the binding of the buffer to the vertices.
    void vertexAttribPointer(AttribPointerInfo[]) @safe;
}

/++
The object to be manipulated with the shader.
+/
interface IShaderManip
{
    /// Loading a shader from its source code.
    void loadFromSource(string) @safe;

    /// Loading a shader from an memory.
    /// Assumes loading an object in Spire-V format.
    void loadFromMemory(void[]) @safe;

    /// Shader stage type.
    @property StageType stage() @safe;
}

struct UniformObject
{
    // optional
    IBuffer buffer;

    uint components = 1;
    uint length = 1;
    TypeBind type = TypeBind.Float;

    union ValueType
    {
        // single fields
        uint ui;
        int i;

        float f;
        double d;

        // vectors
        float[2] fv2;
        float[3] fv3;
        float[4] fv4;

        double[2] dv2;
        double[3] dv3;
        double[4] dv4;

        uint[2] uiv2;
        uint[3] uiv3;
        uint[4] uiv4;

        int[2] iv2;
        int[3] iv3;
        int[4] iv4;

        // matrixs
        float[2][2] f2;
        float[3][3] f3;
        float[4][4] f4;

        double[2][2] d2;
        double[3][3] d3;
        double[4][4] d4;

        this(T)(T value) @trusted
        {
            static foreach (member; __traits(allMembers, ValueType))
            {
                static if (
                    is(typeof(__traits(getMember, this, member)) == T)
                )
                {
                    __traits(getMember, this, member) = value;
                }
            }
        }
    }

    ValueType[] values;

    invariant(components < 9 && components != 0);
}

template isMatrix(T)
{
    import std.traits;

    static if (isStaticArray!T)
    {
        static if(isStaticArray!(ForeachType!T))
        {
            enum isMatrix = T.length > 1 &&
                            (ForeachType!T).length > 1 &&
                            T.length == (ForeachType!T).length;
        } else
            enum isMatrix = false;
    } else
        enum isMatrix = false;
}

template matrixComponents(T)
if (isMatrix!T)
{
    enum matrixComponents = T.length;
}

template singleType(T)
{
    import std.traits;

    static if (isArray!T)
    {
        static if (isArray!(ForeachType!T))
        {
            alias singleType = singleType!(ForeachType!T);
        } else
            alias singleType = ForeachType!T;
    } else
        alias singleType = T;
}

template uniform(T)
{
    import std.traits;

    alias element = Unconst!(singleType!T);

    static if (is(element == float))
    {
        enum bind = TypeBind.Float;
    } else
    static if (is(element == double))
    {
        enum bind = TypeBind.Double;
    } else
    static if (is(element == int) || is(element == short) || is(element == byte))
    {
        enum bind = TypeBind.Int;
    } else
    static if (is(element == uint) || is(element == ushort) || is(element == ubyte))
    {
        enum bind = TypeBind.UnsignedInt;
    }

    UniformObject uniform(T data) @trusted
    {
        UniformObject object;
        object.type = bind;

        static if (isStaticArray!T)
        {
            static if(isMatrix!T)
            {
                object.components = cast(uint) (3 + matrixComponents!T);
                object.length = 1;
                object.values ~= cast(UniformObject.ValueType) data;
            } else
            {
                object.components = cast(uint) T.length;
                object.length = 1;
                object.values ~= cast(UniformObject.ValueType) data;
            }
        }
        else
        static if (isDynamicArray!T)
        {
            alias ftype = ForeachType!T;

            static if (isStaticArray!ftype)
            {
                static if(isMatrix!ftype)
                {
                    object.components = cast(uint) (3 + matrixComponents!ftype);
                    object.length = cast(uint) data.length;
                    foreach (e; data)
                        object.values ~= UniformObject.ValueType(e);
                } else
                {
                    object.components = cast(uint) ftype.length;
                    object.length = cast(uint) data.length;
                    foreach (e; data)
                        object.values ~= UniformObject.ValueType(e);
                }
            } else
            {
                object.components = 1;
                object.length = cast(uint) data.length;
                foreach (e; data)
                    object.values ~= UniformObject.ValueType(e);
            }
        } else
        {
            object.components = 1;
            object.length = 1;
            object.values ~= UniformObject.ValueType(data);
        }

        return object;
    }
}

/++
Object for interaction with the shader program.
+/
interface IShaderProgram
{
    import tida.vector;

    /// Attaching a shader to a program.
    void attach(IShaderManip) @safe;

    /// Program link. Assumes that prior to its call, shaders were previously bound.
    void link() @safe;

    uint getUniformID(string name) @safe;

    void setUniform(uint, UniformObject) @safe;

    final void setUniform(uint uniformID, Vector!float vec) @safe
    {
        setUniform(uniformID, uniform(cast(float[2]) [vec.x, vec.y]));
    }

    final void setUniform(string name, Vector!float vec) @safe
    {
        setUniform(getUniformID(name), uniform(cast(float[2]) [vec.x, vec.y]));
    }

    final void setUniform(T)(uint uniformID, T value) @safe
    {
        setUniform(uniformID, uniform(value));
    }

    final void setUniform(T)(string name, T value) @safe
    {
        setUniform(getUniformID(name), uniform(value));
    }
}

/++
Type of texture.
+/
enum TextureType
{
    /// The data is one -dimensional.
    oneDimensional,

    /// The data is a two -dimensional array.
    twoDimensional,

    /// The data is a two -dimensional three -dimensional array.
    threeDimensional
}

/// Type of deployment of texture on the canvas
enum TextureWrap : uint
{
    wrapS = 0,
    wrapT = 1,
    wrapR = 2
}

/// Type of deployment of texture on the canvas
enum TextureWrapValue : uint
{
    repeat = 0,
    mirroredRepeat = 1,
    clampToEdge = 2
}

/// Type of the texture processing filter.
enum TextureFilter : uint
{
    minFilter = 3,
    magFilter = 4
}

/// Type of the texture processing filter.
enum TextureFilterValue : uint
{
    nearest = 3,
    linear = 4
}

/++
Interface of interaction with a texture object.
+/
interface ITexture
{
    void storage(StorageType storage, uint width, uint height = 1) @safe;

    void subImage(inout void[] data, uint width, uint height = 1) @safe;

    void subData(inout void[] data, uint width, uint height = 1) @safe;

    void[] getData() @safe;

    /// Acceps these images in the texture.
    ///
    /// If the texture is immutable, then the data can be entered only once.
    ///
    /// Params:
    ///     data = Image data.
    ///     width = Image width.
    ///     height = Image height.
    final void append(inout void[] data, uint width, uint height = 1) @safe
    {
        storage(StorageType.rgba8, width, height);
        subImage(data, width, height);
    }

    /// Type of deployment of texture on the canvas
    void wrap(TextureWrap wrap, TextureWrapValue value) @safe;

    /// Type of the texture processing filter.
    void filter(TextureFilter filter, TextureFilterValue value) @safe;

    /// Indicate the parameters of the texture.
    void params(uint[] parameters) @safe;

    /// Insert the texture identifier.
    void active(uint value) @safe;
}

interface IFrameBuffer
{
    void attach(ITexture) @safe;

    void generateBuffer(uint, uint) @safe;

    void clear(Color!ubyte) @safe;
}

enum StorageType
{
    r32f,
    rgba32f,
    rg32f,
    rgba32ui,
    rgba32i,
    r32ui,
    r32i,
    rgba8i,
    rgba8,
    r8i
}

alias ComputeDataType = StorageType;

/++
Graphic manipulator. Responsible for the abstraction of graphics over other
available graphics methods that can be selected. At the moment,
OpenGL backend is available, Vulkan is in implementation.
+/
interface IGraphManip
{
    /// Initializes an abstraction object for loading a library.
    void initialize() @safe;

    /// Create and bind a framebuffer surface to display in a window.
    ///
    /// Params:
    ///     window  = The window to bind the display to.
    ///     attribs = Graphics attributes.
    void createAndBindSurface(Window window, GraphicsAttributes attribs) @safe;

    /// Updating the surface when the window is resized.
    void update() @safe;

    /// Settings for visible borders on the surface.
    ///
    /// Params:
    ///     x = Viewport offset x-axis.
    ///     y = Viewport offset y-axis.
    ///     w = Viewport width.
    ///     h = Viewport height.
    void viewport(float x, float y, float w, float h) @safe;

    /// Color mixing options.
    ///
    /// Params:
    ///     src     = Src factor.
    ///     dst     = Dst factor.
    ///     state   = Do I need to mix colors?
    void blendFactor(BlendFactor src, BlendFactor dst, bool state) @safe;

    /// Color clearing screen.
    void clearColor(Color!ubyte) @safe;

    void clear() @safe;

    /// Drawing start.
    void begin() @safe;

    void compute(ComputeDataType[]) @safe;

    /// Drawing a primitive to the screen.
    ///
    /// Params:
    ///     mode    = The type of the rendered primitive.
    ///     first   = The amount of clipping of the initial vertices.
    ///     count   = The number of vertices to draw.
    void draw(ModeDraw mode, uint first, uint count) @safe;

    void drawIndexed(ModeDraw mode, uint icount) @safe;

    /// Shader program binding to use rendering.
    void bindProgram(IShaderProgram) @safe;

    /// Vertex info binding to use rendering.
    void bindVertexInfo(IVertexInfo vertInfo) @safe;

    /// Texture binding to use rendering.
    void bindTexture(ITexture texture) @safe;

    void bindBuffer(IBuffer buffer) @safe;

    /// Framebuffer output to the window surface.
    void drawning() @safe;

    void setFrameBuffer(IFrameBuffer) @safe;

    /// Creates a shader.
    IShaderManip createShader(StageType) @safe;

    /// Create a shader program.
    IShaderProgram createShaderProgram() @safe;

    /// Buffer creation.
    IBuffer createBuffer(BufferType buffType = BufferType.array) @safe;

    /// Create an immutable buffer.
    immutable(IBuffer) createImmutableBuffer(BufferType buffType = BufferType.array) @safe;

    /// Generates information about buffer binding to vertices.
    IVertexInfo createVertexInfo() @safe;

    /// Create a texture.
    ITexture createTexture(TextureType) @safe;

    IFrameBuffer createFrameBuffer() @safe;

    IFrameBuffer mainFrameBuffer() @safe;

    // Debug tools ----------------------------------------------------------+

    debug
    {
        import std.experimental.logger.core;

        // Log tools --------------------------------------------------------+

        void setupLogger(Logger = stdThreadLocalLog) @safe;

        // -------------------------------------------------------------------
    }

    // -----------------------------------------------------------------------
}

IGraphManip createGraphManip() @safe
{
    version (GraphBackendVulkan)
    {
        // TODO: Implement vulkan backend.

        return null;
    } else
    version (GraphBackendDX)
    {
        // TODO: Implement direct backend.

        return null;
    }
    version (GraphBackendGL)
    {
        import tida.graphics.gl;

        return new GLGraphManip();
    }
}
