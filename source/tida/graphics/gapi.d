module tida.graphics.gapi;

import tida.window;
public import tida.color;

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
    geometry /// Geometry stage
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
    textureBuffer
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

/++
Object for interaction with the shader program.
+/
interface IShaderProgram
{
    /// Attaching a shader to a program.
    void attach(IShaderManip) @safe;

    /// Program link. Assumes that prior to its call, shaders were previously bound.
    void link() @safe;

    uint getUniformID(string name) @safe;

    /// Sets the value to the uniform.
    void setUniform(uint uniformID, float value) @safe;

    /// ditto
    void setUniform(uint uniformID, uint value) @safe;

    /// ditto
    void setUniform(uint uniformID, int value) @safe;

    /// ditto
    void setUniform(uint uniformID, float[2] value) @safe;

    /// ditto
    void setUniform(uint uniformID, float[3] value) @safe;

    /// ditto
    void setUniform(uint uniformID, float[4] value) @safe;

    /// ditto
    void setUniform(uint uniformID, float[2][2] value) @safe;

    /// ditto
    void setUniform(uint uniformID, float[3][3] value) @safe;

    /// ditto
    void setUniform(uint uniformID, float[4][4] value) @safe;
}

enum TextureType
{
    oneDimensional,
    twoDimensional,
    threeDimensional
}

enum TextureWrap
{
    wrapS,
    wrapT,
    wrapR
}

enum TextureWrapValue
{
    repeat,
    mirroredRepeat,
    clampToEdge
}

enum TextureFilter
{
    minFilter,
    magFilter
}

enum TextureFilterValue
{
    nearest,
    linear
}

interface ITexture
{
    void append(inout void[] data, uint width, uint height) @safe;

    void wrap(TextureWrap wrap, TextureWrapValue value) @safe;

    void filter(TextureFilter filter, TextureFilterValue value) @safe;

    void active(uint value) @safe;
}

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

    /// Framebuffer output to the window surface.
    void drawning() @safe;

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
}

IGraphManip createGraphManip() @safe
{
    version (GraphBackendVulkan)
    {
        import tida.graphics.vulkan;

        return new VulkanGraphManup();
    } else
    {
        import tida.graphics.gl;

        return new GLGraphManip();
    }
}
