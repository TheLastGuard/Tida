/++

+/
module tida.graph.gl;

version(WebAssembly)
{

    extern(C)
    {
        void glViewport(int,int,int,int);
        void glClearColor(float,float,float,float);
        void glClear(int);
    }

}

public struct GL
{
    import tida.color;
    version(WebAssembly) {} else 
    {
        import tida.exception;
        import bindbc.opengl;
    }

    version(WebAssembly)
    {} else
    static void initialize() @trusted
    {
        auto retValue = loadOpenGL();

            if(retValue == GLSupport.noContext)
                throw new ContextException(ContextError.noContext,"Context is not create!");
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
}