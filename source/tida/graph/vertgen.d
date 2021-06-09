/++
    
    
    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.vertgen;

import tida.graph.gl;
import tida.shape, tida.vector, tida.color;
import std.range;

class VertexInfo
{
    private
    {
        uint _idVertexArr;
        uint _idBufferArr;
        uint _idElemenArr;

        uint bufferLength;
    }

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

        return this;
    }

    void bindVertexArray() @safe nothrow
    {
        GL3.bindVertexArray(idVertexArray);
    }

    uint idVertexArray() @safe nothrow @property
    {
        return _idVertexArr;
    }

    uint idBufferArray() @safe nothrow @property
    {
        return _idBufferArr;
    }

    uint idElementArray() @safe nothrow @property
    {
        return _idElemenArr;
    }

    uint length() @safe nothrow @property
    {
        return bufferLength;
    }

    void draw(ShapeType type, uint count = 1) @safe nothrow
    {
        switch(type)
        {
            case ShapeType.line:
                GL3.drawArrays(GL_LINES, 0, 2 * count);
            break;

            case ShapeType.rectangle:
                GL3.drawElements(GL_TRIANGLES, 6 * count, GL_UNSIGNED_INT, null);
            break;

            case ShapeType.circle:
                GL3.drawArrays(GL_TRIANGLES, 0, cast(uint) bufferLength / 2 * count);
            break;

            default:
                assert(null, "Unknown type!");
        }
    }

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

float[] generateBuffer(const(Shape) shape, Vecf position = Vecf(0, 0)) @safe nothrow
in(shape.type != ShapeType.unknown, "Shape is unknown!")
out(r; !r.empty, "Buffer is empty!")
do
{
    import std.math : cos, sin;

    switch(shape.type)
    {
        case ShapeType.point:
            return shape.begin.array;

        case ShapeType.line:
            return  (shape.begin + position).array ~
                    (shape.end + position).array;

        case ShapeType.rectangle:
            return  (position + Vecf(shape.end.x, shape.begin.y)).array ~   [0.0f] ~
                    (position + shape.end).array ~                          [0.0f] ~
                    (position + Vecf(shape.begin.x, shape.end.y)).array ~   [0.0f] ~
                    (position + shape.begin).array ~                        [0.0f];

        case ShapeType.circle:
            position = position + shape.begin;

            float[] buffer;

            float x = 0.0f;
            float y = 0.0f;

            for(float i = 0; i <= 360;)
            {
                x = shape.radius * cos(i);
                y = shape.radius * sin(i);

                buffer ~= [position.x + x,position.y + y];

                i += 0.5;
                x = shape.radius * cos(i);
                y = shape.radius * sin(i);

                buffer ~= [position.x + x,position.y + y];
                buffer ~= position.array;

                i += 0.5;
            }

            return buffer;

        case ShapeType.triangle:
            return  shape.vertexs[0].array ~
                    shape.vertexs[1].array ~
                    shape.vertexs[2].array;

        case ShapeType.polygon:
            float[] buffer;

            foreach(cs; shape.data) {
                buffer ~= cs.array ~ [0.0f];
            }

            return buffer;

        case ShapeType.multi:
            float[] buffer;

            foreach(cs; shape.shapes)
                buffer ~= generateBuffer(cs);

            return buffer;

        default:
            return null;
    }
}

VertexInfo generateVertex(const(Shape) shape, Vecf position = Vecf(0, 0)) @trusted
{
    float[] buffer;

    buffer = generateBuffer(shape, position);

    VertexInfo info;

    if(shape.type != ShapeType.rectangle) {
        info = new VertexInfo().generateFromBuffer(buffer);
    } else {
        uint[] elem =   [
                            0, 1, 3,
                            1, 2, 3
                        ];

        info = new VertexInfo().generateFromElemBuff(buffer, elem);

        destroy(elem);
    }

    destroy(buffer);

    return info;
}
