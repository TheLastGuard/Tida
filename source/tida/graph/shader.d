/++

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.shader;

import tida.graph.gl;

string formatError(string error) @safe
{
    import std.array : replace;

    error = error.replace("error","\x1b[1;91merror\x1b[0m");

    return error;
}

enum
{
    Vertex,
    Fragment,
    Program
}

template GLTypeShader(int Type)
{
    static assert(Type != Program, "Program is not shader!");

    static if(Type == Vertex)
        enum GLTypeShader = GL_VERTEX_SHADER;
    else
    static if(Type == Fragment)
        enum GLTypeShader = GL_FRAGMENT_SHADER;
}

template isProgram(int Type)
{
    enum isProgram = Type == Program;
}

template isShader(int Type)
{
    enum isShader = !isProgram!Type;
}

class Shader(int Type)
{
    private
    {
        uint _id;
    }

    public
    {
        static if(isProgram!Type)
        {
            Shader!Vertex vertex;
            Shader!Fragment fragment;
        }
    }

    this() @safe
    {
        static if(isProgram!Type) {
            _id = GL3.createProgram();
        } else {
            _id = GL3.createShader(GLTypeShader!Type);
        }
    }

    uint id() @safe @property
    {
        return _id;
    }

    static if(isShader!Type)
    auto bindSource(string source) @safe
    {
        GL3.shaderSource(_id, 1, source);
        GL3.compileShader(_id);

        string error;
        int result;
        int lenLog;

        GL3.getShaderiv(_id, GL_COMPILE_STATUS, result);
        if(!result) {
            GL3.getShaderiv(_id, GL_INFO_LOG_LENGTH, lenLog);
            GL3.getShaderInfoLog(_id, lenLog, null, error);

            throw new Exception(error.formatError);
        }

        return this;
    }

    static if(isProgram!Type)
    auto attach(Shader!Vertex v) @safe
    {
        vertex = v;

        return this;
    }

    static if(isProgram!Type)
    auto attach(Shader!Fragment f) @safe
    {
        fragment = f;

        return this;
    }

    static if(isShader!Type)
    auto fromFile(string path) @safe
    {
        import std.file : exists, readText;

        if(!exists(path)) throw new Exception("Not find `"~path~"`!");
        bindSource(readText(path));

        return this;
    }

    static if(isProgram!Type)
    auto link() @safe
    {
        GL3.attachShader(_id, vertex.id);
        GL3.attachShader(_id, fragment.id);
        GL3.linkProgram(_id);
        
        return this;
    }

    static if(isProgram!Type)
    void using() @safe
    {
        GL3.useProgram(_id);
    }

    void destroy() @safe
    {
        static if(isProgram!Type)
        {
            GL3.deleteProgram(_id);
        }

        static if(isShader!Type)
        {
            GL3.deleteShader(_id);
        }
    }

    ~this() @safe
    {
        destroy();
    }
}