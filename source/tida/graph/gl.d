/++
    OpenGL module.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.gl;

public import bindbc.opengl;

__gshared bool _glIsInitialize;
__gshared GLSupport _glSupport;

/// Is OpenGL loaded state.
bool glIsInitialize() @trusted
{
    return _glIsInitialize;
}

GLSupport glSupport() @trusted
{
    return _glSupport;
}

enum 
{
    Lines = GL_LINES,
    Triangle = GL_TRIANGLES,
    Polygons = GL_POLYGON,
    Rectangle = GL_QUADS,
    Points = GL_POINTS
}

struct GL
{
    import tida.color;
    import tida.vector;

    static bool isInitialize() @trusted nothrow
    {
        return _glIsInitialize;
    }

    static void initialize() @trusted
    {
        auto retValue = loadOpenGL();

        if(retValue == GLSupport.noContext)
           throw new Exception("Context is not create!");

       _glIsInitialize = true;
       _glSupport = retValue;
    }

    static void alphaFunc(int mode,float alpha) @trusted nothrow
    {
        glAlphaFunc(mode,alpha);
    }

    static void readPixels(int x,int y,int width,int height,GLenum format,GLenum type,void* data) @trusted nothrow
    {
        glReadPixels(x,y,width,height,format,type,data);
    }

    static void viewport(int x,int y,int width,int height) @trusted nothrow
    {
        glViewport(x,y,width,height);
    }

    static void frustum(float a,float b,float c,float d,float e,float f) @trusted nothrow
    {
        glFrustum(a,b,c,d,e,f);
    }
    
    static void clearColor(Color!ubyte color) @trusted @property nothrow
    {
        glClearColor(color.rf,color.gf,color.bf,color.af);
    }

    static void clear(int mode = GL_COLOR_BUFFER_BIT) @trusted nothrow
    {
        glClear(mode);
    }

    static void translate(float x,float y,float z) @trusted nothrow
    {
        glTranslatef(x,y,z);
    }

    static void rotate(float angle,float x,float y,float z) @trusted nothrow
    {
        glRotatef(angle,x,y,z);
    }

    static void pushMatrix() @trusted nothrow
    {
        glPushMatrix();
    }

    static void popMatrix() @trusted nothrow
    {
        glPopMatrix();
    }

    static void draw(GLenum mode)(void delegate() @safe func) @trusted
    {
        glBegin(mode);
            func();
        glEnd();
    }

    static void genTextures(int nums,ref uint texID) @trusted nothrow
    {
        glGenTextures(nums, &texID);
    }

    static void enable(int mode) @trusted nothrow
    {
        glEnable(mode);
    }

    static void disable(int mode) @trusted nothrow
    {
        glDisable(mode);
    }

    static void texCoord2i(int a,int b) @trusted nothrow
    {
        glTexCoord2i(a,b);
    }

    static void bindTexture(int texID) @trusted nothrow
    {
        glBindTexture(GL_TEXTURE_2D, texID);
    }

    static void generateMipmap(int mode) @trusted nothrow
    {
        glGenerateMipmap(mode);
    }

    static void texParameteri(int a,int b) @trusted nothrow
    {
        glTexParameteri(GL_TEXTURE_2D,a,b);
    }

    static void texImage2D(uint width,uint height,ubyte[] pixels) @trusted nothrow
    {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width,height, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(void*) pixels);
    }

    static void vertex(Vecf vector,Vecf size = Vecf()) @trusted nothrow
    {
        glVertex3f(vector.x,vector.y,0.0f);
    }

    static void color(Color!ubyte color) @trusted nothrow
    {
        glColor4f(color.rf,color.gf,color.bf,color.af);
    }

    static void ortho(float a, float b, float c, float d, float e,float f) @trusted nothrow
    {
        glOrtho(a,b,c,d,e,f);
    }

    static void matrixMode(int mode) @trusted nothrow
    {
        glMatrixMode(mode);
    }

    static void loadIdentity() @trusted nothrow
    {
        glLoadIdentity();
    }

    static void releative(ref Vecf position,Vecf size) @trusted nothrow
    {
        position.x = position.x / size.x - 1.0f;
        position.y = ((size.y - position.y) / size.y);
    }
}

struct GL3
{
    import bindbc.opengl;

    static uint createProgram() @trusted nothrow
    {
        return glCreateProgram();
    }
    
    static void attachShader(uint program, uint shader) @trusted nothrow
    {
        glAttachShader(program,shader);
    }
    
    static void linkProgram(uint program) @trusted nothrow
    {
        glLinkProgram(program);
    }

    static void activeTexture(uint id) @trusted nothrow
    {
        glActiveTexture(id);
    }
    
    static uint createShader(uint typeShader) @trusted nothrow
    {
        return glCreateShader(typeShader);
    }
    
    static void shaderSource(uint shader,int count,ref string source) @trusted nothrow
    {
        import std.utf;
    
        const int len = cast(const(int)) source.length;
    
        glShaderSource(shader, count, [source.ptr].ptr, &len);
    }
    
    static void compileShader(uint shader) @trusted nothrow
    {
        glCompileShader(shader);
    }
    
    static void getShaderInfoLog(uint shader, uint length, int* sizeMax, ref string log) @trusted nothrow
    {
        import std.conv : to;
    
        char[] clog = new char[length];
    
        glGetShaderInfoLog(shader,length,sizeMax,clog.ptr);
        
        log = clog.to!string;
    }

    static void getProgramInfoLog(uint program, uint length, int* sizeMax, ref string log) @trusted nothrow
    {
        import std.conv : to;

        char[] clog = new char[length];

        glGetProgramInfoLog(program,length,sizeMax,clog.ptr);

        log = clog.to!string;
    }
    
    static void getShaderiv(uint shader, uint mode, ref int result) @trusted nothrow
    {
        glGetShaderiv(shader,mode,&result);
    }

    static void getProgramiv(uint program, uint mode, ref int result) @trusted nothrow
    {
        glGetProgramiv(program, mode, &result);
    }
    
    static void useProgram(uint program) @trusted nothrow
    {
        glUseProgram(program);
    }
    
    static void deleteShader(uint shader) @trusted nothrow
    {
        glDeleteShader(shader);
    }
    
    static void genBuffers(ref uint vbo) @trusted nothrow
    {
        glGenBuffers(1, &vbo);
    }
    
    static void bindBuffer(uint mode, uint vbo) @trusted nothrow
    {
        glBindBuffer(mode, vbo);
    }
    
    static void bufferData(T)(uint mode,T[] data, uint mode2) @trusted nothrow
    {
        glBufferData(mode,T.sizeof * data.length, cast(void*) data.ptr, mode2);
    }
    
    static void genVertexArrays(ref uint vao) @trusted nothrow
    {
        glGenVertexArrays(1, &vao);
    }
    
    static void bindVertexArray(uint vao) @trusted nothrow
    {
        glBindVertexArray(vao);
    }

    static void deleteBuffer(ref uint id) @trusted nothrow
    {
        glDeleteBuffers(1, &id);
    }
    
    static void deleteVertexArray(ref uint id) @trusted nothrow
    {
        glDeleteVertexArrays(1, &id);
    }

    static void vertexAttribPointer(uint a,uint b,uint mode,bool norm,uint size,void* data) @trusted nothrow
    {
        glVertexAttribPointer(a, b, mode ,norm ? GL_TRUE : GL_FALSE, size, data);
    }
    
    static void enableVertexAttribArray(uint mode) @trusted nothrow
    {
        glEnableVertexAttribArray(mode);
    }

    static void disableVertexAttribArray(uint mode) @trusted nothrow
    {
        glDisableVertexAttribArray(mode);
    }
    
    static void drawArrays(uint mode, uint a, uint b) @trusted nothrow
    {
        glDrawArrays(mode, a, b);
    }

    static void drawElements(uint mode, int a, int b, void* c) @trusted nothrow
    {
        glDrawElements(mode, a, b, c);
    }

    static void deleteProgram(uint id) @trusted nothrow
    {
        glDeleteProgram(id);
    }

    static void bindAttribLocation(uint program, uint index, string name) @trusted nothrow
    {
        import std.utf;

        glBindAttribLocation(program, index, name.toUTFz!(char*));
    }

    static int getAttribLocation(uint program, string name) @trusted nothrow
    {
        import std.utf;

        return glGetAttribLocation(program, name.toUTFz!(char*));
    }

    static int getUniformLocation(uint program, string name) @trusted nothrow
    {
        import std.utf;

        return glGetUniformLocation(program, name.toUTFz!(char*));
    }

    static void uniform4f(uint uniformID, float a, float b, float c, float d) @trusted nothrow
    {
        glUniform4f(uniformID, a, b, c, d);
    }

    static void uniform4f(uint uniformID, float[] arr) @trusted nothrow
    {
        uniform4f(uniformID, arr[0], arr[1], arr[2], arr[3]);
    }

    import tida.color;

    static void uniform4f(uint uniformID, Color!ubyte color) @trusted nothrow
    {
        uniform4f(uniformID, color.rf, color.gf, color.bf, color.af);
    }

    static void uniform3f(uint uniformID, float[] value) @trusted nothrow
    {
        glUniform3f(uniformID, value[0], value[1], value[2]);
    }

    static void uniform2f(uint uniformID, float[] value) @trusted nothrow
    {
        glUniform2f(uniformID, value[0], value[1]);
    }

    static void uniformf(uint uniformID, float value) @trusted nothrow
    {
        glUniform1f(uniformID, value);
    }

    static void uniformMatrix4fv(uint uniformID, ref float[4][4] mat) @trusted nothrow
    {
        glUniformMatrix4fv(uniformID, 1, GL_FALSE, &mat[0][0]);
    }

    static void uniformMatrix4fP(uint uniformID, float* mat) @trusted nothrow
    {
        glUniformMatrix4fv(uniformID, 1, GL_FALSE, mat);
    }

    static void uniformMatrix3fP(uint uniformID, float* mat) @trusted nothrow
    {
        glUniformMatrix3fv(uniformID, 1, GL_FALSE, mat);
    }

    static void uniformMatrix3fv(uint uniformID, float[3][3] mat) @trusted nothrow
    {
        glUniformMatrix3fv(uniformID, 1, GL_FALSE, &mat[0][0]);
    }

    static void uniform1i(uint uniformID, uint id) @trusted nothrow
    {
        glUniform1i(uniformID, id);
    }
}