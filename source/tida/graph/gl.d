/++
    OpenGL module.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.gl;

public import bindbc.opengl;
import tida.templates;

__gshared bool _glIsInitialize;

/// Is OpenGL loaded state.
bool glIsInitialize() @trusted
{
    return _glIsInitialize;
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

	static uint createProgram() @trusted
	{
		return glCreateProgram();
	}
	
	static void attachShader(uint program, uint shader) @trusted
	{
		glAttachShader(program,shader);
	}
	
	static void linkProgram(uint program) @trusted
	{
		glLinkProgram(program);
	}
	
	static uint createShader(uint typeShader) @trusted
	{
		return glCreateShader(typeShader);
	}
	
	static void shaderSource(uint shader,int count,ref string source) @trusted
	{
		import std.utf;
	
		const int len = cast(const(int)) source.length;
	
		glShaderSource(shader, count, [source.ptr].ptr, &len);
	}
	
	static void compileShader(uint shader) @trusted
	{
		glCompileShader(shader);
	}
	
	static void getShaderInfoLog(uint shader, uint length, int* sizeMax, ref string log) @trusted
	{
		import std.conv : to;
	
		char[] clog = new char[length];
	
		glGetShaderInfoLog(shader,length,sizeMax,clog.ptr);
		
		log = clog.to!string;
	}

    static void getProgramInfoLog(uint program, uint length, int* sizeMax, ref string log) @trusted
    {
        import std.conv : to;

        char[] clog = new char[length];

        glGetProgramInfoLog(program,length,sizeMax,clog.ptr);

        log = clog.to!string;
    }
	
	static void getShaderiv(uint shader, uint mode, ref int result) @trusted
	{
		glGetShaderiv(shader,mode,&result);
	}

    static void getProgramiv(uint program, uint mode, ref int result) @trusted
    {
        glGetProgramiv(program, mode, &result);
    }
	
	static void useProgram(uint program) @trusted
	{
		glUseProgram(program);
	}
	
	static void deleteShader(uint shader) @trusted
	{
		glDeleteShader(shader);
	}
	
	static void genBuffers(ref uint vbo) @trusted
	{
		glGenBuffers(1, &vbo);
	}
	
	static void bindBuffer(uint mode, uint vbo) @trusted
	{
		glBindBuffer(mode, vbo);
	}
	
	static void bufferData(uint mode,float[] data, uint mode2) @trusted
	{
		glBufferData(mode,data.sizeof * data.length, cast(void*) data.ptr, mode2);
	}
	
	static void genVertexArrays(ref uint vao) @trusted
	{
		glGenVertexArrays(1, &vao);
	}
	
	static void bindVertexArray(uint vao) @trusted
	{
		glBindVertexArray(vao);
	}
	
	static void vertexAttribPointer(uint a,uint b,uint mode,bool norm,uint size,void* data) @trusted
	{
		glVertexAttribPointer(a, b, mode ,norm ? GL_TRUE : GL_FALSE, size, data);
	}
	
	static void enableVertexAttribArray(uint mode) @trusted
	{
		glEnableVertexAttribArray(mode);
	}
	
	static void drawArrays(uint mode, uint a, uint b) @trusted
	{
		glDrawArrays(mode, a, b);
	}

    static void deleteProgram(uint id) @trusted
    {
        glDeleteProgram(id);
    }

    static void bindAttribLocation(uint program, uint index, string name) @trusted
    {
        import std.utf;

        glBindAttribLocation(program, index, name.toUTFz!(char*));
    }

    static int getAttribLocation(uint program, string name) @trusted
    {
        import std.utf;

        return glGetAttribLocation(program, name.toUTFz!(char*));
    }

    static int getUniformLocation(uint program, string name) @trusted
    {
        import std.utf;

        return glGetUniformLocation(program, name.toUTFz!(char*));
    }

    static void uniform4f(uint uniformID, float a, float b, float c, float d) @trusted
    {
        glUniform4f(uniformID, a, b, c, d);
    }

    static void uniform4f(uint uniformID, float[] arr) @trusted
    {
        uniform4f(uniformID, arr[0], arr[1], arr[2], arr[3]);
    }

    import tida.color;

    static void uniform4f(uint uniformID, Color!ubyte color) @trusted
    {
        uniform4f(uniformID, color.rf, color.gf, color.bf, color.af);
    }

    static void uniformf(uint uniformID, float value) @trusted
    {
        glUniform1f(uniformID, value);
    }
}