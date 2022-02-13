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
    import tida.shape;

private:
    uint bid;
    uint vid;
    uint eid;

    size_t blength;
    size_t elength;

public:
    Shape!T shapeinfo; /// Shape information

@trusted:
    /++
    Enters data into a separate memory.

    Params:
        buffer = Binded buffer.
    +/
    void bindFromBuffer(T[] buffer)
    {
        glGenVertexArrays(1, &vid);
        glGenBuffers(1, &bid);
        glBindVertexArray(vid);

        glBindBuffer(GL_ARRAY_BUFFER, bid);
        glBufferData(GL_ARRAY_BUFFER, T.sizeof * buffer.length, buffer.ptr, GL_STATIC_DRAW);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindVertexArray(0);

        blength = buffer.length;
    }

    /++
    Enters data into a separate memory.

    Params:
        buffer = Binded buffer.
        element = Binded element buffer.
    +/
    void bindFromBufferAndElem(T[] buffer, uint[] element)
    {
        glGenVertexArrays(1, &vid);
        glGenBuffers(1, &bid);
        glBindVertexArray(vid);

        glBindBuffer(GL_ARRAY_BUFFER, bid);
        glBufferData(GL_ARRAY_BUFFER, T.sizeof * buffer.length, buffer.ptr, GL_STATIC_DRAW);

        glGenBuffers(1, &eid);

        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eid);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, uint.sizeof * buffer.length, element.ptr, GL_STATIC_DRAW);

        glBindBuffer(GL_ARRAY_BUFFER, 0);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        glBindVertexArray(0);

        blength = buffer.length;
        elength = element.length;
    }

    /// Binds an array of vertices to the current render cycle.
    void bindVertexArray() nothrow
    {
        glBindVertexArray(vid);
    }

    /// Binds an buffer of vertices to the current render cycle.
    void bindBuffer() nothrow
    {
        glBindBuffer(GL_ARRAY_BUFFER, bid);
    }

    /// Binds an element buffer of vertices to the current render cycle.
    void bindElementBuffer() nothrow
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, eid);
    }

    /// Unbinds an buffer of vertices to the current render cycle.
    static void unbindBuffer() nothrow
    {
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }

    /// Unbinds an element buffer of vertices to the current render cycle.
    static void unbindElementBuffer() nothrow
    {
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    }

    /// Unbinds an array of vertices to the current render cycle.
    static void unbindVertexArray() nothrow
    {
        glBindVertexArray(0);
    }

    /// Define an array of generic vertex attribute data
    void vertexAttribPointer(uint vertLocation, int sample = 2) nothrow
    {
        glVertexAttribPointer(vertLocation, 2, glType!T, false, sample * cast(int) T.sizeof, null);
    }

    /// Define an array of generic vertex attribute data
    void textureAttribPointer(uint location, int sample = 4) nothrow
    {
        glVertexAttribPointer(location, 2, glType!T, false, sample * cast(int) T.sizeof, cast(void*) (T.sizeof * 2));
    }

    void offsetAttribPointer(uint location, uint offset, uint sample) nothrow
    {
        glVertexAttribPointer(location, 2, glType!T, false, sample * cast(int) T.sizeof, cast(void*) (T.sizeof * offset));
    }

    /// Define an array of generic vertex attribute data
    void colorAttribPointer(uint location, uint sample = 6) nothrow
    {
        glVertexAttribPointer(location, 4, glType!T, false, sample * cast(int) T.sizeof, cast(void*) (T.sizeof * 2));
    }

    /// ID of the generated vertex array.
    @property uint idVertexArray() nothrow inout
    {
        return vid;
    }

    /// The identifier of the buffer in memory.
    @property uint idBufferArray() nothrow inout
    {
        return bid;
    }

    /// The identifier of the elements in memory.
    @property uint idElementArray() nothrow inout
    {
        return eid;
    }

    /// Buffer length.
    @property size_t length() nothrow inout
    {
        return blength;
    }

    /// Element length
    @property size_t elementLength() nothrow inout
    {
        return elength;
    }

    /++
    Outputs the rendering of the buffer.

    Params:
        type = Shape type
        count = Count rendering shapes
    +/
    void draw(ShapeType type, int count = 1)
    {
        switch(type)
        {
            case ShapeType.point:
                glDrawArrays(GL_POINTS, 0, 1 * count);
            break;
        
            case ShapeType.line:
                glDrawArrays(GL_LINES, 0, 2 * count);
            break;

            case ShapeType.rectangle:
                glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
            break;

            case ShapeType.roundrect:
                glDrawArrays(GL_TRIANGLES, 0, cast(uint) (blength / 2 * count));
            break;

            case ShapeType.circle:
                glDrawArrays(GL_TRIANGLE_FAN, 0, cast(uint) (blength / 4 * count));
            break;

            case ShapeType.triangle:
                glDrawArrays(GL_TRIANGLES, 0, cast(uint) blength);
            break;

            case ShapeType.polygon:
                glDrawArrays(GL_TRIANGLE_FAN, 0, cast(uint) blength);
            break;

            default:
                assert(null, "Unknown type!");
        }
    }

    /// Destroys vertex information.
    void deleting()
    {
        if(idBufferArray != 0) glDeleteBuffers(1, &bid);
        if(idVertexArray != 0) glDeleteVertexArrays(1, &vid);
        if(idElementArray != 0) glDeleteBuffers(1, &eid);

        bid = 0;
        vid = 0;
        eid = 0;
    }

    ~this()
    {
        this.deleting();
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
Vector!T[] generateBuffer(T)(Shape!T shape, Vector!T textureSize = vecNaN!T) @safe nothrow pure
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
            vertexs = shape.data;
            vertexs ~= shape.data[0];
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

    if (!isVectorNaN!T(textureSize))
    {
        auto vertDump = vertexs.dup;
        vertexs.length = 0;

        const clip = rectVertexs!T(vertDump);

        foreach (e; vertDump) {
            vertexs ~= [e,
                        vec!T   ((e.x - clip.x) / clip.width,
                                (e.y - clip.y) / clip.height)];
        }
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

/// ditto
VertexInfo!T generateVertex(T)(Shape!T shape, Vector!T textSize = vecNaN!T) @trusted
{
    T[] buffer;

    buffer = generateBuffer!T(shape, textSize).generateArray;

    VertexInfo!T info = new VertexInfo!T();

    if (shape.type == ShapeType.rectangle)
    {
        uint[] elements = [0 ,1, 2, 2, 3 ,0];
        info.bindFromBufferAndElem(buffer, elements);
    }else
    {
        info.bindFromBuffer(buffer);
    }

    info.shapeinfo = shape;

    destroy(buffer);

    return info;
}

/// ditto
VertexInfo!T generateVertexColor(T)(Shape!T shape, Color!ubyte[] colors) @trusted
{
    T[] buffer;
    Color!float[] fcolors;

    foreach (e; colors)
        fcolors ~= e.convert!(ubyte, float);

    buffer = generateBuffer!T(shape).generateArray;
    T[] buffDump = buffer.dup;
    buffer = [];

    VertexInfo!T info = new VertexInfo!T();

    size_t j = 0;
    for (size_t i = 0; i < buffDump.length; i += 2)
    {
        buffer ~= buffDump[i .. i + 2] ~ fcolors[j].toBytes!(PixelFormat.RGBA);
        j++;
    }

    if (shape.type == ShapeType.rectangle)
    {
        uint[] elements = [0 ,1, 2, 2, 3 ,0];
        info.bindFromBufferAndElem(buffer, elements);
    }else
    {
        info.bindFromBuffer(buffer);
    }

    info.shapeinfo = shape;

    destroy(buffer);

    return info;
}
