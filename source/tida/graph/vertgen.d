/++
    A module for working with vertices.
    
    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.vertgen;

import tida.graph.gl;
import tida.shape, tida.vector, tida.color;
import std.range;

/// Vertex description class.
class VertexInfo
{
    private
    {
        uint _idVertexArr;
        uint _idBufferArr;
        uint _idElemenArr;

        uint bufferLength;
        uint elementLength;
    }

    public
    {
        Shape shapeinfo; // Shape information
    }

    /++
        Generates vertices from a buffer.

        Params:
            buffer = Buffer.
    +/
    auto generateFromBuffer(float[] buffer) @safe nothrow
    in(!buffer.empty, "Buffer is empty!")
    do
    {
        GL3.genVertexArrays(_idVertexArr);
        GL3.genBuffers(_idBufferArr);
        GL3.bindVertexArray(_idVertexArr);

        GL3.bindBuffer(GL_ARRAY_BUFFER, _idBufferArr);
        GL3.bufferData(GL_ARRAY_BUFFER, buffer, GL_STATIC_DRAW);

        GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
        GL3.bindVertexArray(0);

        bufferLength = cast(uint) buffer.length;

        return this;
    }

    /++
        Generates vertices from a buffer and elements.

        Params:
            buffer = Buffer.
            elem = Elements.
    +/
    auto generateFromElemBuff(float[] buffer,uint[] elem) @safe nothrow
    in(!buffer.empty, "Buffer is empty!")
    in(!elem.empty, "Element array is empty!")
    do
    {
        GL3.genVertexArrays(_idVertexArr);
        GL3.genBuffers(_idBufferArr);
        GL3.bindVertexArray(_idVertexArr);

        GL3.bindBuffer(GL_ARRAY_BUFFER, _idBufferArr);
        GL3.bufferData(GL_ARRAY_BUFFER, buffer, GL_STATIC_DRAW);

        GL3.genBuffers(_idElemenArr);

        GL3.bindBuffer(GL_ELEMENT_ARRAY_BUFFER, _idElemenArr);
        GL3.bufferData(GL_ELEMENT_ARRAY_BUFFER, elem, GL_STATIC_DRAW);

        GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
        GL3.bindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
        GL3.bindVertexArray(0);

        bufferLength = cast(uint) buffer.length;
        elementLength = cast(uint) elem.length;

        return this;
    }

    /// Binds an array of vertices to the current render cycle.
    void bindVertexArray() @safe nothrow
    {
        GL3.bindVertexArray(idVertexArray);
    }

    /// ID of the generated vertex array.
    uint idVertexArray() @safe nothrow @property
    {
        return _idVertexArr;
    }

    /// The identifier of the buffer in memory.
    uint idBufferArray() @safe nothrow @property
    {
        return _idBufferArr;
    }

    /// The identifier of the elements in memory.
    uint idElementArray() @safe nothrow @property
    {
        return _idElemenArr;
    }

    /// Buffer length.
    uint length() @safe nothrow @property
    {
        return bufferLength;
    }

    uint elemLength() @safe nothrow @property
    {
        return elementLength;
    }

    ///
    void draw(ShapeType type, uint count = 1) @safe nothrow
    {
        switch(type)
        {
            case ShapeType.line:
                GL3.drawArrays(GL_LINES, 0, 2 * count);
            break;

            case ShapeType.rectangle:
                GL3.drawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);
            break;

            case ShapeType.circle:
                GL3.drawArrays(GL_TRIANGLE_FAN, 0, cast(uint) (bufferLength / 4 * count));
            break;

            case ShapeType.triangle:
                GL3.drawArrays(GL_TRIANGLES, 0, cast(uint) bufferLength);
            break;

            default:
                assert(null, "Unknown type!");
        }
    }

    /// Destroys vertex information.
    void deleting() @safe nothrow
    {
        if(idBufferArray != 0) GL3.deleteBuffer(_idBufferArr);
        if(idVertexArray != 0) GL3.deleteVertexArray(_idVertexArr);
        if(idElementArray != 0) GL3.deleteBuffer(_idElemenArr);

        _idBufferArr = 0;
        _idVertexArr = 0;
        _idElemenArr = 0;
    }

    ~this() @safe nothrow
    {
        this.deleting();
    }
}

/++
    Generates a buffer from the shape description structure.

    Params:
        shape = Shape structure.
        position = Shape position.

    Example:
    ---
    auto buffer = generateBuffer(Shape.Line(Vecf(32, 48), Vecf(64, 96)));
    ---
+/
Vecf[] generateBuffer(Shape shape, Vecf textSize = VecfNan) @safe nothrow
in(shape.type != ShapeType.unknown, "Shape is unknown!")
out(r; !r.empty, "Buffer is empty!")
do
{
    import std.math : cos, sin;

    Vecf[] vertexs;

    switch(shape.type)
    {
        case ShapeType.point:
            vertexs = [shape.begin];
        break;

        case ShapeType.line:
            vertexs =   [(shape.begin),
                         (shape.end)];
        break;

        case ShapeType.rectangle:
            vertexs =   [Vecf(shape.end.x, shape.begin.y),
                         shape.end,
                         Vecf(shape.begin.x, shape.end.y),
                         shape.begin];
        break;

        case ShapeType.circle:
            for(float i = 0; i <= 360;)
            {
                vertexs ~= shape.begin + Vecf(cos(i), sin(i)) * shape.radius;

                i += 0.5;
                vertexs ~= shape.begin + Vecf(cos(i), sin(i)) * shape.radius;
                vertexs ~= shape.begin;

                i += 0.5;
            }
        break;

        case ShapeType.triangle:
            vertexs = shape.vertexs;
        break;

        case ShapeType.polygon:
            vertexs = shape.data;
        break;

        case ShapeType.multi:
            foreach(cs; shape.shapes)
                vertexs ~= generateBuffer(cs);
        break;

        default:
            return null;
    }

    if(!textSize.isVecfNan) {
        auto vertDump = vertexs.dup;
        vertexs.length = 0;

        const clip = rectVertexs(vertDump);

        foreach(e; vertDump) {
            vertexs ~= [e,
                        Vecf((e.x - clip.x) / clip.width,
                             (e.y - clip.y) / clip.height)];
        }
    }

    return vertexs;
}

/++
    Generates information about vertices from the shape description structure.

    Params:
        shape = Shape structure.
        position = Shape position.

    Example:
    ---
    auto info = generateVertex(Shape.Rectangle(Vecf(0,0), Vecf(32, 32)), Vecf(32, 32));
    ---
+/
VertexInfo generateVertex(Shape shape, Vecf textSize = VecfNan) @trusted
{
    float[] buffer;

    buffer = generateBuffer(shape, textSize).generateArray;

    VertexInfo info;

    if(shape.type == ShapeType.rectangle)
    {
        uint[] elements = [0 ,1, 2, 2, 3 ,0];

        info = new VertexInfo().generateFromElemBuff(buffer, elements);
    }else
    {
        info = new VertexInfo().generateFromBuffer(buffer);
    }

    info.shapeinfo = shape;

    destroy(buffer);

    return info;
}
