/++
A module for programming open graphics shaders.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.shader;

import tida.gl;

enum
{
    Vertex = 0, /// Vertex shader type
    Fragment, /// Fragment shader type
    Geometry, /// Geometry shader type
    Program /// Program shader type
}

/++
Whether the shader type is a program.
+/
template isShaderProgram(int type)
{
    enum isShaderProgram = (type == Program);
}

/++
Whether the shader type is a shader unit.
+/
template isShaderUnite(int type)
{
    enum isShaderUnite = !isShaderProgram!type;
}

/++
Whether the shader type is valid to use.
+/
template isValidTypeShader(int type)
{
    enum isValidTypeShader = (type < 4);
}

/++
Converts types into a convenient representation for the open graphics library.
+/
template glTypeShader(int type)
{
    static assert(isValidTypeShader!type, "Invalid type shader!");

    static if (type == Vertex)
        enum glTypeShader = GL_VERTEX_SHADER;
    else
    static if (type == Fragment)
        enum glTypeShader = GL_FRAGMENT_SHADER;
    static if (type == Geometry)
    	enum glTypeShader = GL_GEOMETRY_SHADER;
}

private string formatError(string error) @safe pure
{
    import std.array : replace;

    error = error.replace("error","\x1b[1;91merror\x1b[0m");

    return error;
}

/++
A description object for a shader program or program unit.
+/
class Shader(int type)
if (isValidTypeShader!type)
{
    import std.string : toStringz;
    import std.conv : to;

    enum Type = type;

private:
    uint glid;

    static if (isShaderProgram!type)
    {
        Shader!Vertex vertex;
        Shader!Fragment fragment;
    } 

public @trusted:
    this()
    {
        static if (isShaderUnite!type)
            glid = glCreateShader(glTypeShader!type);
        else
            glid = glCreateProgram();
    }

    /// Shader identificator
    @property uint id()
    {
        return glid;
    }

    /++
    Binds the shader source directly to the shader itself into memory by compiling it.

    Params:
        source = Shader source code.

    Throws: `Exception` If the shader contains errors.
                        All errors are displayed in a preformatted message.
    +/
    static if (isShaderUnite!type)
    Shader!type bindSource(string source)
    {
        const int len = cast(const(int)) source.length;
        glShaderSource(glid, 1, [source.ptr].ptr, &len);
        glCompileShader(glid);

        char[] error;
        int result;
        int lenLog;

        glGetShaderiv(glid, GL_COMPILE_STATUS, &result);
        if (!result)
        {
            glGetShaderiv(glid, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);
            glGetShaderInfoLog(glid, lenLog, null, error.ptr);

            throw new Exception("Shader compile error:\n" ~ error.to!string.formatError);
        }

        return this;
    }

    /++
    Binds the source code to the shader directly from the specified file.

    Params:
        path = The path to the shader source code.

    Throws: `Exception` if the file is not found.
    +/
    static if (isShaderUnite!type)
    Shader!type fromFile(string path)
    {
        import std.file : readText;

        return bindSource(readText(path));
    }

    /++
    Binds a shader to the program.

    Params:
        shader = Fragment/Vertex shader.
    +/
    static if (isShaderProgram!type)
    Shader!type attach(T)(T shader)
    if (isShaderUnite!(T.Type) && (shader.Type == Vertex || shader.Type == Fragment || shader.Type == Geometry))
    {
        static if (T.Type == Vertex)
            vertex = shader;
        else
        static if (T.Type == Fragment)
            fragment = shader;

        glAttachShader(glid, shader.id);
        return this;
    }

    /++
    Links two compiled shaders into a program.

    Throws: `Exception` If linking two shaders did not succeed. The error
                        will be written directly in the exception message.
    +/
    static if (isShaderProgram!type)
    Shader!type link()
    {
        import std.conv : to;

        glLinkProgram(glid);

        int status;
        glGetProgramiv(glid, GL_LINK_STATUS, &status);
        if (!status)
        {
            int lenLog;
            char[] error;
            glGetProgramiv(glid, GL_INFO_LOG_LENGTH, &lenLog);
            error = new char[](lenLog);

            glGetProgramInfoLog(glid, lenLog, null, error.ptr);

            throw new Exception(error.to!string.formatError);
        }
        
        return this;
    }

    /++
    Uses a shader program.
    +/
    static if (isShaderProgram!type)
    void using()
    {
        glUseProgram(glid);
    }

    /++
    Associates a generic vertex attribute index with a named attribute variable

    Params:
        index = Specifies the index of the generic vertex attribute to be bound.
        name =  Specifies a null terminated string containing the name of the vertex shader
                attribute variable to which index is to be bound.

    See_Also: $(HTTP https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBindAttribLocation.xhtml, glBindAttribLocation)
    +/
    static if (isShaderProgram!Type)
    void bindAttribLocation(uint index, string name)
    {
        glBindAttribLocation(glid, index, name.ptr);
    }

    /++
    Enable or disable a generic vertex attribute array

    Params:
        name = Vertex attribute name.

    See_Also: $(HTTP https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glEnableVertexAttribArray.xhtml, glEnableVertexAttribArray)
    +/
    static if (isShaderProgram!Type)
    void enableVertex(string name)
    {
        glEnableVertexAttribArray(getAttribLocation(name));
    }

    /++
    Enable or disable a generic vertex attribute array

    Params:
        id = Vertex identificator.

    See_Also: $(HTTP https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glEnableVertexAttribArray.xhtml, glEnableVertexAttribArray)
    +/
    static if (isShaderProgram!Type)
    void enableVertex(uint id)
    {
        glEnableVertexAttribArray(id);
    }

    /++
    Enable or disable a generic vertex attribute array

    Params:
        name = Vertex attribute name.

    See_Also: $(HTTP https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glEnableVertexAttribArray.xhtml, glEnableVertexAttribArray)
    +/
    static if (isShaderProgram!Type)
    void disableVertex(string name)
    {
        glDisableVertexAttribArray(getAttribLocation(name));
    }

    /++
    Enable or disable a generic vertex attribute array

    Params:
        id = Vertex identificator.

    See_Also: $(HTTP https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glEnableVertexAttribArray.xhtml, glEnableVertexAttribArray)
    +/
    static if (isShaderProgram!Type)
    void disableVertex(uint id)
    {
        glDisableVertexAttribArray(id);
    }

    /++
    Returns the location of an attribute variable

    Params:
        name =  Points to a null terminated string containing the name of the
                attribute variable whose location is to be queried.

    See_Also: $(HTTP https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetAttribLocation.xhtml, glGetAttribLocation)
    +/
    static if(isShaderProgram!Type)
    int getAttribLocation(string name)
    {
        return glGetAttribLocation(glid, name.ptr);
    }

    import tida.color, tida.vector;

    /++
    Return uniform identificator (location)

    Params:
        name = Uniform name.
    +/
    static if (isShaderProgram!Type)
    uint getUniformLocation(string name)
    {
        return glGetUniformLocation(glid, name.ptr);
    }

    /++
        Sets the color of a 4D vector type uniform.

        Params:
            name = The name of the uniform variable.
            color = Color structure.
    +/
    static if (isShaderProgram!Type)
    void setUniform(string name, Color!ubyte color)
    {
        auto uid = glGetUniformLocation(glid, name.ptr);
        glUniform4f(uid, color.rf, color.gf, color.bf, color.af);
    }

    /++
        Sends a float value to the uniform.

        Params:
            name = The name of the uniform variable.
            value = Variable value.
    +/
    static if (isShaderProgram!Type)
    void setUniform(string name, float value)
    {
        auto uid = glGetUniformLocation(glid, name.ptr);
        glUniform1f(uid, value);
    }

    /++
        Passes a 4-by-4 variable matrix to the uniform.

        Params:
            name = The name of the uniform variable.
            value = Matrix.
    +/
    static if (isShaderProgram!Type)
    void setUniform(string name, float[4][4] value)
    {
        auto uid = glGetUniformLocation(glid, name.ptr);
        glUniformMatrix4fv(uid, 1, false, value[0].ptr);
    }

    /++
        Passes a 3-by-3 variable matrix to the uniform.

        Params:
            name= The name of the uniform variable.
            value = Matrix.
    +/
    static if (isShaderProgram!Type)
    void setUniform(string name, float[3][3] value)
    {
        auto uid = glGetUniformLocation(glid, name.ptr);
        glUniformMatrix3fv(uid, 1, false, cast(const(float)*) value);
    }

    ///
    static if (isShaderProgram!Type)
    void setUniformMat(int Type)(string name, float* matPTR)
    {
        auto uid = glGetUniformLocation(glid, name.ptr);

        static if (Type == 4)
        {
            glUniformMatrix4fP(uid, matPTR);
        }else
        static if (Type == 3)
        {
            glUniformMatrix3fP(uid, matPTR);
        }
    }

    /// Returns the number of variable uniforms in the program.
    static if (isShaderProgram!Type)
    uint lengthUniforms()
    {
        int len;
        glGetProgramiv(glid, GL_ACTIVE_UNIFORMS, &len);

        return len;
    }

    /// Destroys the structure of a shader or program.
    void destroy()
    {
        if(glid != 0)
        {
            static if (isShaderProgram!Type)
            {
                glDeleteProgram(glid);
            }else
            static if (isShaderUnite!Type)
            {
                glDeleteShader(glid);
            }

            glid = 0;
        }
    }

    ~this()
    {
        destroy();
    }
}
