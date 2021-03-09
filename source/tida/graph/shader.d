/++

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.shader;

import tida.graph.gl;

enum One = 1;
enum Two = 2;
enum Three = 3;
enum Four = 4; 

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
    import tida.color;

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

            throw new Exception("Shader compile error:\n" ~ error.formatError);
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

        int status;
        GL3.getProgramiv(_id, GL_LINK_STATUS, status);
        if(!status)
        {
            int lenLog;
            string error;
            GL3.getProgramiv(_id, GL_INFO_LOG_LENGTH, lenLog);
            GL3.getProgramInfoLog(_id, lenLog, null, error);

            throw new Exception(error.formatError);
        }

        vertex = null;
        fragment = null;
        
        return this;
    }

    static if(isProgram!Type)
    void using() @safe
    {
        GL3.useProgram(_id);
    }

    static if(isProgram!Type)
    void bindAttribLocation(uint index,string name) @safe
    {
        GL3.bindAttribLocation(_id, index, name);
    }

    static if(isProgram!Type)
    int getAttribLocation(string name) @safe
    {
        return GL3.getAttribLocation(_id, name);
    }

    static if(isProgram!Type)
    void setUniform(int Type = Four)(string name, float[] value) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);

        static if(Type == One)
        {
            GL3.uniformf(uid, value);
        }else
        static if(Type == Two)
        {
            GL3.uniform2f(uid, value);
        }else
        static if(Type == Three)
        {
            GL3.uniform3f(uid, value);
        }else
        static if(Type == Four)
        {
            GL3.uniform4f(uid, value);
        }
    }

    import tida.graph.texture;

    static if(isProgram!Type)
    void setUniform(string name, Texture tex) @safe
    {
        GL3.uniform1i(GL3.getUniformLocation(_id, name), tex.glID);
    }

    static if(isProgram!Type)
    auto getUniformLocation(string name) @safe
    {
        return GL3.getUniformLocation(_id, name);
    }

    static if(isProgram!Type)
    void setUniform(string name, Color!ubyte color) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);
        GL3.uniform4f(uid, color);
    }

    static if(isProgram!Type)
    void setUniform(string name, float value) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);
        GL3.uniformf(uid, value);
    }

    static if(isProgram!Type)
    void setUniform(string name, float[4][4] value) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);
        GL3.uniformMatrix4fv(uid, value);
    }

    static if(isProgram!Type)
    void setUniform(string name, float[3][3] value) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);
        GL3.uniformMatrix3fv(uid, value);
    }

    static if(isProgram!Type)
    void setUniformMat(int Type)(string name, float* matPTR) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);

        static if(Type == Four)
        {
            GL3.uniformMatrix4fP(uid, matPTR);
        }else
        static if(Type == Three)
        {
            GL3.uniformMatrix3fP(uid, matPTR);
        }
    }

    static if(isProgram!Type)
    uint lengthUniforms() @safe
    {
        int len;
        GL3.getProgramiv(_id, GL_ACTIVE_UNIFORMS, len);

        return len;
    }

    void destroy() @safe
    {
        import std.stdio;

        static if(isProgram!Type)
        {
            GL3.deleteProgram(_id);
            writeln("Delete program!");
            writeln(_id);
        }

        static if(isShader!Type)
        {
            GL3.deleteShader(_id);
            writeln("Delete shader!");
            writeln(_id);
        }
    }

    ~this() @safe
    {
        destroy();
    }
}