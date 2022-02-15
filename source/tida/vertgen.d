/++
The module for generating vertices for drawing open graphics by the library.

By means of $(HREF shape.html, Shape)'s, you can generate its vertices for a convenient 
representation and transfer such vertices to the shader to draw 
the corresponding shapes.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.vertgen;

import tida.shape;
import tida.vector;
import std.traits;
import tida.color;

/++
a template for translating a type into a type identifier that is 
understandable for the OpenGL interface.

Params:
    T = Type;
+/
template glType(T)
{
    import tida.gl;

    static if (is(T : float))
        enum glType = GL_FLOAT;
    else
    static if (is(T : double))
        enum glType = GL_DOUBLE;
    else
    static if (is(T : byte))
        enum glType = GL_BYTE;
    else
    static if (is(T : ubyte))
        enum glType = GL_UNSIGNED_BYTE;
    else
    static if (is(T : int))
        enum glType = GL_INT;
    else
    static if (is(T : uint))
        enum glType = GL_UNSIGNED_INT;
    else
        static assert(null, "The `" ~ T.stringof ~ "` type cannot be translated into an interface that OpenGL understands.");
}

/++
A storage object for the identifiers of the buffers stored in memory.
+/
class VertexInfo(T)
if (isNumeric!T)
{
    import tida.gl;

package(tida):
    uint id = 0;

public:
    BufferInfo!(T) buffer = null;
    ElementInfo!(uint) elements = null;

    this() @trusted
    {
        glGenVertexArrays(1, &id);
    }

    void bind() @trusted
    {
        glBindVertexArray(id);
    }

    static void unbind() @trusted
    {
        glBindVertexArray(0);
    }

    static void vertexAttribPointer(uint location, uint components, uint sample, uint offset) @trusted
    {
        glVertexAttribPointer(
            location,
            components,
            glType!T,
            false,
            sample * cast(uint) T.sizeof,
            cast(void*) (T.sizeof * offset)
        );
    }

    static void positionAttribPointer(uint location, uint sample, uint offset = 0) @safe
    {
        vertexAttribPointer(location, 2, sample, offset);
    }

    static void colorAttibPointer(uint location, uint sample, uint offset = 2) @safe
    {
        vertexAttribPointer(location, 4, sample, offset);
    }

    static void enableVertex (uint location) @trusted
    {
        glEnableVertexAttribArray(location);
    }

    void draw (ShapeType drawType, uint count = 1) @trusted
    {
        switch (drawType)
        {
            case ShapeType.point:
            {
                if (elements is null)
                {
                    glDrawArrays(GL_POINTS, 0, count);
                }
                else
                {
                    glDrawElements(
                        GL_POINTS,
                        cast(uint) elements.length,
                        GL_UNSIGNED_INT,
                        null
                    );
                }
            }
            break;

            case ShapeType.line:
            {
                if (elements is null)
                {
                    glDrawArrays(GL_LINES, 0, 2 * count);
                }
                else
                {
                    glDrawElements(
                        GL_LINES,
                        cast(uint) elements.length,
                        GL_UNSIGNED_INT,
                        null
                    );
                }
            }
            break;

            case ShapeType.triangle:
            {
                if (elements is null)
                {
                    glDrawArrays(GL_TRIANGLES, 0, 3 * count);
                }
                else
                {
                    glDrawElements(
                        GL_TRIANGLES,
                        cast(uint) elements.length,
                        GL_UNSIGNED_INT,
                        null
                    );
                }
            }
            break;

            case ShapeType.rectangle:
            {
                if (elements is null)
                {
                    glDrawArrays(GL_TRIANGLES, 0, 6 * count);
                }
                else
                {
                    glDrawElements(
                        GL_TRIANGLES,
                        cast(uint) elements.length,
                        GL_UNSIGNED_INT,
                        null
                    );
                }
            }
            break;

            case ShapeType.roundrect:
            {
                if (elements is null)
                {
                    glDrawArrays(GL_TRIANGLES, 0, cast(uint) buffer.length / (1 * count));
                }
                else
                {
                    glDrawElements(
                        GL_TRIANGLES,
                        cast(uint) elements.length,
                        GL_UNSIGNED_INT,
                        null
                    );
                }
            }
            break;

            case ShapeType.circle:
            {
                if (elements is null)
                {
                    glDrawArrays(GL_TRIANGLE_FAN, 0, cast(uint) buffer.length / 4);
                }
                else
                {
                    glDrawElements(
                        GL_TRIANGLE_FAN,
                        cast(uint) elements.length,
                        GL_UNSIGNED_INT,
                        null
                    );
                }
            }
            break;

            case ShapeType.polygon:
            {
                if (elements is null)
                {
                    glDrawArrays(GL_TRIANGLE_FAN, 0, cast(uint) buffer.length);
                }
                else
                {
                    glDrawElements(
                        GL_TRIANGLE_FAN,
                        cast(uint) elements.length,
                        GL_UNSIGNED_INT,
                        null
                    );
                }
            }
            break;

            case ShapeType.multi:
                return;

            case ShapeType.unknown:
                return;

            default:
                return;
        }
    }

    void clear() @trusted
    {
        glDeleteVertexArrays(1, &id);
    }

    ~this() @trusted
    {
        clear();
    }
}

/++
Figure description structure for binding and drawing.
+/
class BufferInfo(T)
{
    import tida.gl;

package(tida):
    uint id = 0;
    T[] contextData;

public:
    Vector!T[] vertexData; /// Vertices.

    /// The remaining data.
    /// Each element refers to a certain top.
    T[][] attachData;

    this() @safe
    {
        generateBuffer();
    }

    /// How many vertices are in the buffer
    @property size_t length() @safe inout
    {
        return vertexData.length;
    }

    /// How much data to attach (to all vertices).
    @property size_t attachDataLength() @safe inout
    {
        size_t result;

        foreach (e; attachData)
        {
            result += e.length;
        }

        return result;
    }

    /// The final length of the buffer.
    @property size_t rawLength() @safe inout
    {
        return length() + attachDataLength();
    }

    /++
    The function of accepting a vertex to the buffer, along with its attached 
    data (position, color, texture coordinates, etc.)

    Params:
        vertex = Vertex position.
        attached = Enumerated data that can be attached to the node.

    Example:
    ---
    //             vertex position --  color ------------
    buffer.append (vec!float (32, 32), 1.0, 0.0, 0.0, 1.0);
    buffer.append (vec!float (64, 64), 0.0, 1.0, 0.0, 0.5);
    ---
    +/
    void append (Args...) (Vector!float vertex, Args attached) @safe
    {
        vertexData ~= vertex;

        if (attached.length > attachData.length)
            attachData.length = attached.length;

        size_t i = 0;
        foreach (e; attached)
        {
            attachData[i] ~= e;
            i++;
        }
    }

    /++
    Issuance of the final data that should be obtained.
    +/
    @property T[] rawData() @safe
    {
        T[] result;

        foreach (size_t i, e; vertexData)
        {
            result ~= e.array;

            foreach (ae; attachData)
                result ~= ae[i];
        }

        return result;
    }

    /// Generate a buffer for the GPU.
    void generateBuffer() @trusted
    {
        glGenBuffers(1, &id);
    }

    /// Copy data to GPU.
    void attach() @trusted
    {
        contextData = rawData();

        glBufferData(GL_ARRAY_BUFFER, T.sizeof * contextData.length, contextData.ptr, GL_STATIC_DRAW);
    }

    /// Move data to GPU.
    void move() @trusted
    {
        contextData = rawData();

        glBufferData(GL_ARRAY_BUFFER, T.sizeof * contextData.length, contextData.ptr, GL_STATIC_DRAW);
        
        contextData.length = 0;
        vertexData.length = 0;
        attachData.length = 0;
    }

    /// Bind opengl buffer.
    void bind() @trusted
    {
        glBindBuffer(GL_ARRAY_BUFFER, id);
    }

    /// Unbind opengl buffer.
    static void unbind() @trusted
    {
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    /// Delete opengl buffer.
    void deleteBuffer() @trusted
    {
        glDeleteBuffers(1, &id);
    }

    /// Clear data.
    void clear() @safe
    {
        if (id != 0)
        {
            deleteBuffer();
        }

        vertexData.length = 0;
        attachData.length = 0;
        contextData.length = 0;
    }

    ~this()
    {
        clear();
    }
}

/++
Vertex element data.
+/
class ElementInfo(T)
{
    import tida.gl;

package(tida):
    uint id;

public:
    T[] data; /// Elements data

    this() @safe
    {
        generateBuffer();
    }

    /// Elements length.
    @property size_t length() @trusted
    {
        return data.length;
    }

    /// Bind opengl element buffer.
    void bind() @trusted
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, id);
    }

    /// Unbind opengl element buffer.
    static void unbind() @trusted
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }

    /// Generate element buffer for GPU.
    void generateBuffer() @trusted
    {
        glGenBuffers(1, &id);
    }

    /// Copy elements to GPU.
    void attach() @trusted
    {
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, T.sizeof * data.length, data.ptr, GL_STATIC_DRAW);
    }

    /// Delete opengl buffer.
    void deleteBuffer() @trusted
    {
        glDeleteBuffers(1, &id);
    }

    /// Clear data.
    void clear() @safe
    {
        deleteBuffer();
        data.length = 0;
    }

    ~this() @trusted
    {
        clear();
    }
}

/++
Generates the vertices of shapes to be rendered using hardware acceleration.

Params:
    T = Type.
    shape = Shape information.
    textureSize =   Texture size. If not specified, will not generate texture 
                    vertices for vertices.
+/
Vector!T[] generateBuffer(T)(Shape!T shape) @safe nothrow pure
{
    import std.math : cos, sin;

    Vector!T[] vertexs;

    switch (shape.type)
    {
        case ShapeType.point:
            vertexs = [shape.begin];
        break;

        case ShapeType.line:
            vertexs = [shape.begin, shape.end];
        break;

        case ShapeType.rectangle:
            vertexs =   [
                            vec!T(shape.end.x, shape.begin.y),
                            shape.end,
                            vec!T(shape.begin.x, shape.end.y),
                            shape.begin
                        ];
        break;

        case ShapeType.roundrect:
            immutable pos1 = shape.begin + vec!T(shape.radius, 0);
            immutable pos2 = shape.begin + vec!T(0, shape.radius);

            immutable size = vec!T(shape.width, shape.height);

            vertexs =   [
                            // FIRST RECTANGLE
                            pos1,
                            pos1 + vec!T(size.x - shape.radius * 2, 0),
                            pos1 + size - vec!T(shape.radius * 2, 0),

                            pos1,
                            pos1 + vec!T(0, size.y),
                            pos1 + size - vec!T(shape.radius * 2, 0),

                            // SECOND RECTANGLE
                            pos2,
                            pos2 + vec!T(size.x, 0),
                            pos2 + size - vec!T(0, shape.radius * 2),

                            pos2,
                            pos2 + vec!T(0, size.y - shape.radius * 2),
                            pos2 + size - vec!T(0, shape.radius * 2)
                        ];

            void rounded(vec!T pos, T a1, T a2, T iter)
            {
                for (T i = a1; i <= a2;)
                {
                    vertexs ~= pos + vec!T(cos(i), sin(i)) * shape.radius;

                    i += iter;
                    vertexs ~= pos + vec!T(cos(i), sin(i)) * shape.radius;
                    vertexs ~= pos;

                    i += iter;
                }
            }

            rounded(shape.begin + vec!T(shape.radius, shape.radius), 270, 360, 0.25);
            rounded(shape.begin + vec!T(size.x - shape.radius, shape.radius), 0, 90, 0.25);
            rounded(shape.begin + vec!T(shape.radius, size.y - shape.radius), 180, 270, 0.25);
            rounded(shape.begin + vec!T(size.x - shape.radius, size.y - shape.radius), 90, 180, 0.25);
        break;

        case ShapeType.circle:
            for (T i = 0; i <= 360;)
            {
                vertexs ~= shape.begin + vec!T(cos(i), sin(i)) * shape.radius;

                i += 0.25;
                vertexs ~= shape.begin + vec!T(cos(i), sin(i)) * shape.radius;
                vertexs ~= shape.begin;

                i += 0.25;
            }
        break;

        case ShapeType.triangle:
            vertexs = shape.vertexs;
        break;

        case ShapeType.polygon:
            foreach (e; shape.data)
                vertexs ~= shape.begin + e;
            vertexs ~= shape.begin + shape.data[0];
        break;

        case ShapeType.multi:
            foreach (cs; shape.shapes)
            {
                vertexs ~= generateBuffer!T(cs);
            }
        break;

        default:
            return null;
    }

    return vertexs;
}

unittest
{
    immutable buffer = generateBuffer!(float)(
        Shape!(float).Rectangle(vec!float(32.0f, 32.0f),
                                vec!float(96.0f, 96.0f)));

    immutable checkedBuffer =
    [
        vec!float(96.0f, 32.0f),
        vec!float(96.0f, 96.0f),
        vec!float(32.0f, 96.0f),
        vec!float(32.0f, 32.0f)
    ];

    assert(buffer == (checkedBuffer));
}
