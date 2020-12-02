/++
    

    Authors: TodNaz
    License: MIT
+/
module tida.graph.gl;

public import bindbc.opengl;

enum
{
    Lines = GL_LINES,
    Triangle = GL_TRIANGLES,
    Polygons = GL_POLYGON,
    Rectangle = GL_QUADS,
    Points = GL_POINTS
}

public struct GL
{
    import tida.color;
    import tida.vector;

    version(WebAssembly) {} else 
    {
        import tida.exception;
    }

    static void initialize() @trusted
    {
        auto retValue = loadOpenGL();

            if(retValue == GLSupport.noContext)
                throw new ContextException(ContextError.noContext,"Context is not create!");
    }

    static void alphaFunc(int mode,float alpha) @trusted
    {
        glAlphaFunc(mode,alpha);
    }

    static void readPixels(int x,int y,int width,int height,GLenum format,GLenum type,void* data) @trusted
    {
        glReadPixels(x,y,width,height,format,type,data);
    }

    static void viewport(int x,int y,int width,int height) @trusted
    {
        glViewport(x,y,width,height);
    }

    

    static void clearColor(Color!ubyte color) @trusted @property
    {
        glClearColor(color.rf,color.gf,color.bf,color.af);
    }

    static void clear() @trusted
    {
        glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    }

    static void translate(float x,float y,float z) @trusted
    {
        glTranslatef(x,y,z);
    }

    static void rotate(float angle,float x,float y,float z) @trusted
    {
        glRotatef(angle,x,y,z);
    }

    static void pushMatrix() @trusted
    {
        glPushMatrix();
    }

    static void popMatrix() @trusted
    {
        glPopMatrix();
    }

    static void draw(GLenum mode)(void delegate() @safe func) @trusted
    {
        glBegin(mode);
            func();
        glEnd();
    }

    static void genTextures(int nums,ref uint texID) @trusted
    {
        glGenTextures(nums, &texID);
    }

    static void enable(int mode) @trusted
    {
        glEnable(mode);
    }

    static void disable(int mode) @trusted
    {
        glDisable(mode);
    }

    static void texCoord2i(int a,int b) @trusted
    {
        glTexCoord2i(a,b);
    }

    static void bindTexture(int texID) @trusted
    {
        glBindTexture(GL_TEXTURE_2D, texID);
    }

    static void texParameteri(int a,int b) @trusted
    {
        glTexParameteri(GL_TEXTURE_2D,a,b);
    }

    static void texImage2D(uint width,uint height,ubyte[] pixels) @trusted
    {
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width,height, 0, GL_RGBA, GL_UNSIGNED_BYTE, cast(void*) pixels);
    }

    static void vertex(Vecf vector,Vecf size = Vecf()) @trusted
    {
        glVertex3f(vector.x,vector.y,0.0f);
    }

    static void color(Color!ubyte color) @trusted
    {
        glColor4f(color.rf,color.gf,color.bf,color.af);
    }

    static void ortho(float a, float b, float c, float d, float e,float f) @trusted
    {
        glOrtho(a,b,c,d,e,f);
    }

    static void matrixMode(int mode) @trusted
    {
        glMatrixMode(mode);
    }

    static void loadIdentity() @trusted
    {
        glLoadIdentity();
    }

    static void releative(ref Vecf position,Vecf size) @trusted
    {
        position.x = position.x / size.x - 1.0f;
        position.y = ((size.y - position.y) / size.y);
    }
}