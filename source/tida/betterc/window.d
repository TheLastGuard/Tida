/++

+/
module tida.betterc.window;

version(WebAssembly):

struct Context
{
    import emscript.emscripten;
    import tida.window;

    public
    {
        GLAttributes attrib;
        EMSCRIPTEN_WEBGL_CONTEXT_HANDLE ctx;
    }

    public void attribInitialize(Window window) @trusted
    {
        emscripten_set_canvas_element_size("#canvas",window.width,window.height);
        EmscriptenWebGLContextAttributes glAttr;
        emscripten_webgl_init_context_attributes(&glAttr);

        glAttr.alpha = glAttr.depth = glAttr.stencil = glAttr.antialias = glAttr.preserveDrawingBuffer = glAttr.failIfMajorPerformanceCaveat = 0;
        glAttr.enableExtensionsByDefault = 1;
        glAttr.premultipliedAlpha = 0;
        glAttr.majorVersion = 1;
        glAttr.minorVersion = 0;
    }

    public EMSCRIPTEN_WEBGL_CONTEXT_HANDLE aContext() @trusted
    {
        return ctx;
    }

    public void initialize(Window window) @trusted
    {
        ctx = emscripten_webgl_create_context("#canvas",&glAttr);
    }
}

struct Window
{
    import emscript.emscripten;
    import tida.window;
    
    private
    {
        uint _width;
        uint _height;
        string _title;
        Context* context;
    }

    this(uint newWidth,uint newHeight,string newTitle) @trusted
    {
        _width = newWidth;
        _height = newHeight;
        _title = newTitle;
    }

    public void initialize(ubyte type)() @trusted
    {
        import core.stdc.stdlib;

        context = cast(Context*) malloc(Context.sizeof);
        context.attribInitialize();

        setContext();
    }

    public void contextSet(Context* context) @trusted
    {
        emscripten_webgl_make_context_current(context.aContext);
    }
}