/++
    A module for working with opengl shaders.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.shader;

import tida.graph.gl;

enum One = 1; /// Parameter for transferring uniforms. Pass the float variable.
enum Two = 2; /// Parameter for transferring uniforms. Pass a 2D vector variable.
enum Three = 3; /// Parameter for transferring uniforms. Pass a 3D vector to the variable.
enum Four = 4; /// Parameter for transferring uniforms. Pass a 4D vector to the variable.

private string formatError(string error) @safe pure
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

/++
    Depending on the shader type, it passes the shader type for the opengl format.
+/
template GLTypeShader(int Type)
{
    static assert(Type != Program, "Program is not a shader!");

    static if(Type == Vertex)
        enum GLTypeShader = GL_VERTEX_SHADER;
    else
    static if(Type == Fragment)
        enum GLTypeShader = GL_FRAGMENT_SHADER;
}

/// Whether the current shader is a program.
template isProgram(int Type)
{
    enum isProgram = Type == Program;
}

/// Whether the shader is a shader.
template isShader(int Type)
{
    enum isShader = !isProgram!Type;
}

/// Shader description class.
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
            Shader!Vertex vertex; /// Vertex shader.
            Shader!Fragment fragment; /// Fragment shader.
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

    /// Returns the shader ID.
    uint id() @safe @property
    {
        return _id;
    }

    /++
        Binds a shader or program by its identifier.

        Params:
            id = Identifier program or shader.
    +/
    void bind(uint iden) @safe @property
    {
        this._id = iden;
    }

    /++
        Binds the shader source directly to the shader itself into memory by compiling it.

        Params:
            source = Shader source code.

        Throws: `Exception` If the shader contains errors.
                            All errors are displayed in a preformatted message.
    +/
    static if(isShader!Type)
    Shader!Type bindSource(string source) @safe
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

    /++
        Binds a shader to the program.

        Params:
            v = Vertex shader.
    +/
    static if(isProgram!Type)
    Shader!Type attach(Shader!Vertex v) @safe
    {
        vertex = v;

        return this;
    }

    /++
        Binds a shader to the program.

        Params:
            f = Fragment shader.
    +/
    static if(isProgram!Type)
    Shader!Type attach(Shader!Fragment f) @safe
    {
        fragment = f;

        return this;
    }

    /++
        Binds the source code to the shader directly from the specified file.

        Params:
            path = The path to the shader source code.

        Throws: `Exception` if the file is not found.
    +/
    static if(isShader!Type)
    Shader!Type fromFile(string path) @safe
    {
        import std.file : exists, readText;

        if(!exists(path)) throw new Exception("Not find `"~path~"`!");
        bindSource(readText(path));

        return this;
    }

    /++
        Links two compiled shaders into a program.

        Throws: `Exception` If linking two shaders did not succeed. The error
                            will be written directly in the exception message.
    +/
    static if(isProgram!Type)
    Shader!Type link() @safe
    in(vertex,"The vertex shader is not attached!")
    in(fragment,"The fragment shader is not attached!")
    do
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

    /++
        Uses a shader program.
    +/
    static if(isProgram!Type)
    void using() @safe
    {
        GL3.useProgram(_id);
    }

    /++
        Associates a generic vertex attribute index with a named attribute variable

        Params:
            index = Specifies the index of the generic vertex attribute to be bound.
            name =  Specifies a null terminated string containing the name of the vertex shader
                    attribute variable to which index is to be bound.

        See_Also: $(HTTP https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBindAttribLocation.xhtml, glBindAttribLocation)
    +/
    static if(isProgram!Type)
    void bindAttribLocation(uint index,string name) @safe
    {
        GL3.bindAttribLocation(_id, index, name);
    }

    /++
        Returns the location of an attribute variable

        Params:
            name =  Points to a null terminated string containing the name of the
                    attribute variable whose location is to be queried.

        See_Also: $(HTTP https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetAttribLocation.xhtml, glGetAttribLocation)
    +/
    static if(isProgram!Type)
    int getAttribLocation(string name) @safe
    {
        return GL3.getAttribLocation(_id, name);
    }

    /++
        Sets a uniform variable to the shader program.

        Params:
            Type = The type of the variable that is passed to the uniform variable.
            name = The name of the uniform variable.
            value = The value of the variable.
    +/
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

    /++
        Sets some reference to the texture in the uniform variable.

        Params:
            name = The name of the uniform variable.
            tex = The texture to bind.
    +/
    static if(isProgram!Type)
    void setUniform(string name, Texture tex) @safe
    {
        GL3.uniform1i(GL3.getUniformLocation(_id, name), tex.glID);
    }

    /++
        Returns the identifier of the uniform variable to interact with.

        Params:
            name = The name of the uniform variable.
    +/
    static if(isProgram!Type)
    int getUniformLocation(string name) @safe
    {
        return GL3.getUniformLocation(_id, name);
    }

    /++
        Sets the color of a 4D vector type uniform.

        Params:
            name = The name of the uniform variable.
            color = Color structure.
    +/
    static if(isProgram!Type)
    void setUniform(string name, Color!ubyte color) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);
        GL3.uniform4f(uid, color);
    }

    /++
        Sends a float value to the uniform.

        Params:
            name = The name of the uniform variable.
            value = Variable value.
    +/
    static if(isProgram!Type)
    void setUniform(string name, float value) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);
        GL3.uniformf(uid, value);
    }

    /++
        Passes a 4-by-4 variable matrix to the uniform.

        Params:
            name = The name of the uniform variable.
            value = Matrix.
    +/
    static if(isProgram!Type)
    void setUniform(string name, float[4][4] value) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);
        GL3.uniformMatrix4fv(uid, value);
    }

    /++
        Passes a 3-by-3 variable matrix to the uniform.

        Params:
            name= The name of the uniform variable.
            value = Matrix.
    +/
    static if(isProgram!Type)
    void setUniform(string name, float[3][3] value) @safe
    {
        auto uid = GL3.getUniformLocation(_id, name);
        GL3.uniformMatrix3fv(uid, value);
    }

    ///
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

    /// Returns the number of variable uniforms in the program.
    static if(isProgram!Type)
    uint lengthUniforms() @safe
    {
        int len;
        GL3.getProgramiv(_id, GL_ACTIVE_UNIFORMS, len);

        return len;
    }

    /// Destroys the structure of a shader or program.
    void destroy() @safe
    {
        if(_id != 0)
        {
            static if(isProgram!Type)
            {
                GL3.deleteProgram(_id);
            }

            static if(isShader!Type)
            {
                GL3.deleteShader(_id);
            }

            _id = 0;
        }
    }

    ~this() @safe
    {
        destroy();
    }
}
