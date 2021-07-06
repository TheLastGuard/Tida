/++
    This module gives access to the creation and management of a window. Unfortunately, 
    it is not supported to create more than one window, due to security concerns of accessing 
    memory and connecting to the window manager server. At the moment, you can create a window, 
    and a context for the graphics pipeline, set the size, window, window resistivity and some 
    other window parameters, which are inherent in both the x11 environment and the Windows window manager 
    in both ways. However, there are features of the implementations, for example, so far only x11 can be 
    used to set the transparency of the window.
    # 1. Create window components.
    ## 1.1 Creating a simple window.
    A window is created by calling the window manager server, and for this, you first need to connect to it 
    to send requests such as initializing the window and changing its parameters. To do this, you need to 
    create a runtime to connect to the window manager server. Import the runtime module, and instantiate it. 
    In addition, it will load other libraries, this can be undone, the following example will show how to create 
    a runtime for the server connection without loading unnecessary libraries:
    ---
    TidaRuntime.initialize(args, NoLibrary);
    ---
    (You can download individual components as needed, see: 
    [tida.runtime](https://github.com/TodNaz/Tida/blob/master/source/tida/runtime.d))
    In this case, the library will connect to the window manager, and then it will be possible to work with windows.
    First, you need to allocate memory for properties through the garbage collector, setting in the constructor. 
    The constructor only sets parameters, but not how not to create a window:
    ---
    auto window = new Window(640, 480, "Title!");
    ---
    The random step is to create the window itself. The easiest way is through the `initialize` function. 
    The template parameter includes the window type.
    * `Simple` - Options for creating a window in which the graphics pipeline will not be created.
    * `ContextIn` - Creates both a window and a graphics pipeline for applying hardware accelerated graphics.
    Now, let's create a window without a graphics pipeline:
    ---
    window.initialize!Simple;
    ---
    When creating a window, it will automatically show the window, and now you can handle the event, or draw in it.
    ## 1.2 Creating a graphics pipeline and using it.
    Once hardware acceleration is required, you can create a window with a graphics pipeline that you can interact 
    with through the Open Graphics Library. Unfortunately, the rendering engine uses the capabilities of the first 
    versions, but you can refuse rendering in favor of your own by inheriting the interface. The easiest way to create 
    such a window is also with `initialize`:
    ---
    window.initialize!ContextIn;
    ---
    And in this case, the window itself will create a graphic pipeline and determine the creation parameters. 
    However, you can create a manual context, regardless of the platform through the `IContext` interface, 
    by setting the necessary context parameters. The following example will show you how this can be done. 
    First, you need to create a window from where the context will be created:
    ---
    window.initialize!Simple;
    ---
    The next step is to allocate memory for the context:
    ---
    auto context = new Context();
    ---
    Now, we can define the attributes of the graphics pipeline:
    ---
    context.attributeInitialize(GLAttributes(...));
    ---
    After, when the attributes are initialized, you need to create the context itself:
    ---
    context.initialize()
    ---
    The pipeline properties are defined in the GLAttributes structure, create a pipeline from its properties.
    Now this context can be assigned to a window:
    ---
    window.context = context;
    ---
    Unfortunately, in the Windows environment, before creating, you need to declare a window for the context, 
    from where the parameters will be displayed:
    ---
    context.deviceMake(window.handle);
    ---
    # 2. Window control.
    ## 2.1 Window size.
    The size of the window is set using the constructor, however, if you need to dynamically resize, 
    you can use the `resize` method, where you can change the visual size of the window. 
    You can find out the parameters using the properties `width`,` height`, however, when the user resizes manually, 
    they will not be recorded automatically, you must perform this action yourself using event tracking through 
    the handler:
    ---
    IEventHandler event = new EventHandler(window);
    ...
    if(event.isResize) {
        window.eventResize(event.newSizeWindow);
    }
    ---
    In this situation, you yourself keep track of the size of the window. If not tracked, the size will visually change, 
    however, the properties of the window will not be changed, and when using it, there may be unexpected behavior. 
    This is due to the fact that automatic markup is impossible due to a bug in x11, when the event is set to be tracked, 
    he graphic pipeline does not change size along with the window, from where there are gaps with scaling.
    If you don't want the user to be able to resize, set such a property to `resizable`. 
    If you want, this can also be canceled. Not only the user, but also the program cannot change the size.
    It is also available to switch the window to full screen mode through the 'fullscreen' property. 
    Both translation and translation into windowed mode are available:
    ---
    window.fullscreen = true; // Fullscreen mode
    ...
    window.fullscreen = false; // Window mode
    ---
    ## 2.2 External component.
    The window represents the icon, title, icon and frame for the window. All such properties can be set through 
    the corresponding functions.
    `window.icon` - 
    The parameters indicate the structure of the picture, where the sequence is taken from, covented the icon, 
    and send the data to the server. An example of how to set an icon from a file:
    ---
    window.icon = new Image().load("icon.png");
    ---
    `window.border` -
    Determines whether the window will have frames.
    `window.title` - 
    Sets the title of the window.
    ## 2.3 Features with platform.
    There may be a case when you need to work with a window directly through its native API, 
    for this there is a `handle` method. It gives a pointer to a window in its plafform, and based on it, 
    you can change some of its parameters. Care should be taken with this, because by changing it outside 
    of the class, you can cause the program to behave undefined. To prevent this from happening, change those 
    properties that the handler, renderer and the window itself will not track when it works with it.
    Here's an example of interaction:
    ---
    auto winPtr = window.handle();
    // Fixes the title bar in X11 environment.
    XStoreName(runtime.display, winPtr, newTitle.toUTFz!(char*));
    ---
    This example shows a bad attitude of work outside the stratum, since now the object, when we request a title, 
    will return the old title because it did not remember the old one. Therefore, be extremely careful when working 
    outside the interlayer.
    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.window;

enum ubyte Empty     = 0; /// Will not initialize the window.
enum ubyte Simple    = 1; /// Initializes a window with no graphics context for OpenGL.
enum ubyte ContextIn = 2; /// Initialization of a window with a graphics pipeline for OpenGL.

/// Attributes for creating context.
struct GLAttributes
{
    public
    {
        int redSize = 8; /// Red size
        int greenSize = 8; /// Green size
        int blueSize = 8; /// Blue size
        int alphaSize = 8; /// Alpha channel size
        int depthSize = 24; /// Depth size
        int stencilSize = 8; /// Stencil size
        int colorDepth = 32; /// Color depth
        bool doubleBuffer = true; /// Double buffering
    }
}

/++
    Automatically resizes all colors when creating context.
    sizeAll = Color component size.
+/
template GLAttribAutoColorSize(ubyte sizeAll)
{
    enum GLAttribAutoColorSize = GLAttributes(sizeAll, sizeAll, sizeAll, sizeAll);
}

/++
    The context interface that describes how to interact with the context.
    See_Also:
            $(HTTP https://dri.freedesktop.org/wiki/GLX/, GLX)
            $(HTTP https://docs.microsoft.com/en-us/windows/win32/opengl/wgl-functions, WGL)
+/
interface IContext
{
    /++
        Initializes the attributes of the context.
        
        Params:
            attributes = Attributes for creating context.


        Throws: `Exception` If the context in the process was not created 
        under the influence of input parameters.
    +/
    void attributeInitialize(GLAttributes attributes) @safe;

    /++
        Initializes the contest itself.
    +/
    void initialize() @safe;

    /// Context destory
    void destroy() @safe;
}

/++
    The interface describing the interaction with the window in the program.
+/
interface IWindow
{
    import tida.graph.image;

    /// Shows a window.
    void show() @safe;

    /// Hides a window.
    void hide() @safe;

    /++
        Sets the context to the window. When creating the context manually, 
        keep in mind that this function will not help.

        Throws: `Exception` if the context is damaged or does not match the parameters.
    +/
    void context(IContext context) @safe @property;

    /// The currently supplied context to the window.
    IContext context() @safe @property;

    /++
        Swaps buffers.
        Throws: `Exception` If there is no graphics pipeline.
    +/
    void swapBuffers() @safe;

    /// X-axis position of the window.
    int x() @safe @property;

    /// Y-axis position of the window.
    int y() @safe @property;

    /++
        Resizes the window.
        Params:
            newWidth = Window width.
            newHeight = Window height.
    +/
    void resize(uint newWidth,uint newHeight) @safe;

    /++
        Changes the position of the window.
        Params:
            posX = Window x-axis position.
            posY = Window y-axis position.
    +/
    void move(int posX,int posY) @safe;

    /// Resizable states of the window.
    void resizable(bool value) @safe @property;

    /// ditto
    bool resizable() @safe @property;

    /// Window states, full screen or windowed.
    void fullscreen(bool value) @safe @property;

    /// ditto
    bool fullscreen() @safe @property;

    /// The state of the borders, whether they are there or not.
    void border(bool value) @safe @property;

    /// ditto
    bool border() @safe @property;

    /// Window title.
    void title(string newTitle) @safe @property;

    /// ditto
    string title() @safe @property;

    void icon(Image image) @safe @property;

    /// Window width.
    uint width() @safe @property;

    /// Window height.
    uint height() @safe @property;

    /// Destroys the window instance.
    void destroyWindow() @safe;

    /++
        Changes only the window size values without changing the window itself. 
        (This is needed for events when the window is resized).
    +/ 
    void eventResize(uint[2] size) @safe;
}

version(Posix)
class Context : IContext
{
    import tida.x11, tida.runtime;

    private
    {
        GLXContext _context;
        XVisualInfo* visual;
        GLXFBConfig bestFbcs;   
    }

    void bindContext(GLXContext ctx) @safe
    {
        this._context = ctx;
    }

    override void attributeInitialize(GLAttributes attributes = GLAttribAutoColorSize!8) @trusted
    {
        import std.conv : to;
        import std.exception : enforce;

        int[] glxAttribs = 
            [
                GLX_X_RENDERABLE    , True,
                GLX_DRAWABLE_TYPE   , GLX_WINDOW_BIT,
                GLX_RENDER_TYPE     , GLX_RGBA_BIT,
                GLX_X_VISUAL_TYPE   , GLX_TRUE_COLOR,
                GLX_RED_SIZE        , attributes.redSize,
                GLX_GREEN_SIZE      , attributes.greenSize,
                GLX_BLUE_SIZE       , attributes.blueSize,
                GLX_ALPHA_SIZE      , attributes.alphaSize,
                GLX_DEPTH_SIZE      , attributes.depthSize,
                GLX_STENCIL_SIZE    , attributes.stencilSize,
                GLX_DOUBLEBUFFER    , attributes.doubleBuffer.to!int,
                None
            ];

        int fbcount = 0;
        auto fbc = glXChooseFBConfig(runtime.display, runtime.displayID, glxAttribs.ptr, &fbcount);

        enforce(fbc, "fbc was not found!");

        int bestFbc = -1, bestNum = -1;
        foreach(int i; 0 .. fbcount)
        {
            int sampBuff, samples;
            glXGetFBConfigAttrib(runtime.display, fbc[i], GLX_SAMPLE_BUFFERS, &sampBuff);
            glXGetFBConfigAttrib(runtime.display, fbc[i], GLX_SAMPLES, &samples);

            if(bestFbc < 0 || (sampBuff && samples > bestNum)) {
                bestFbc = i;
                bestNum = samples;
            }
        }

        bestFbcs = fbc[bestFbc];

        enforce(bestFbcs, "best FBS is a nil!");

        visual = glXGetVisualFromFBConfig(runtime.display, bestFbcs);

        enforce(visual, "Visual is a nil!");

        XFree(fbc);
    }

    override void initialize() @trusted
    {
        _context = glXCreateNewContext(runtime.display, bestFbcs, GLX_RGBA_TYPE, null, True);
    }

    override void destroy() @trusted
    {
        glXDestroyContext(runtime.display, context);
        if(visual) XFree(visual);
    }

    XVisualInfo* visualInfo() @safe @property
    {
        return visual;
    }

    GLXContext context() @safe @property
    {
        return _context;
    }

    ~this() @safe
    {
        this.destroy();
    }
}

/// X11 window structure
version(Posix)
class Window : IWindow
{
    import tida.x11, tida.runtime, tida.graph.image;
    import std.utf;

    private
    {
        uint _width;
        uint _height;

        string _title;

        bool _fullscreen;
        bool _border;
        bool _resizable;

        IContext _context;

        tida.x11.Window window;

        Visual* _visual;
        int _depth;
    }

    void bindWindow(tida.x11.Window window) @trusted
    {
        this.window = window;
        XWindowAttributes attrib;

        XGetWindowAttributes(runtime.display, window, &attrib);
        _width = attrib.width;
        _height = attrib.height;

        scope XSizeHints* sh = XAllocSizeHints();
        scope(exit) XFree(sh);

        long flags;

        XGetWMNormalHints(runtime.display, window, sh, &flags);

        _resizable = (sh.flags & PMinSize) == PMinSize;

        this._visual = attrib.visual;
        this._depth = attrib.depth;
    }

    this(uint newWidth,uint newHeight,string newTitle) @safe
    {
        _width = newWidth;
        _height = newHeight;
        _title = newTitle;
    }

    void createFromXVisual(XVisualInfo* vinfo,int posX = 100,int posY = 100) @trusted 
    {
        scope Visual* visual = vinfo.visual;
        int depth = vinfo.depth;

        _visual = visual;
        _depth = depth;

        auto rootWindow = runtime.rootWindow;

        XSetWindowAttributes windowAttribs;
        windowAttribs.border_pixel = 0x000000;
        windowAttribs.background_pixel = 0xFFFFFF;
        windowAttribs.override_redirect = True;
        windowAttribs.colormap = XCreateColormap(runtime.display, rootWindow, 
                                                 visual, AllocNone);

        windowAttribs.event_mask = ExposureMask | ButtonPressMask | KeyPressMask |
                                   KeyReleaseMask | ButtonReleaseMask | EnterWindowMask |
                                   LeaveWindowMask | PointerMotionMask;

        window = XCreateWindow (runtime.display, rootWindow, posX, posY, width, height, 0, depth,
                                InputOutput, visual, CWBackPixel | CWColormap | CWBorderPixel | CWEventMask, 
                                &windowAttribs);

        title = _title;

        auto wmAtom = GetAtom!"WM_DELETE_WINDOW";

        XSetWMProtocols(runtime.display, window, &wmAtom, 1);
    }

    /++
        Window initialization. In the class, it must be executed as a template to generate the appropriate context.
        You can initialize the window of the following types:
        * Simple    -   Generates a window without a graphics pipeline. Those. a simple window will be created, 
                        if you need a context, you have to make it yourself and send it to the window.
        * ContextIn -   Generates a window with a graphics pipeline for OpenGL.
        Params:
            Type = The type initial window.
            posX = The initial x position of the window.
            posY = The initial y position of the window.
            isShow = Whether to show the window.
    +/
    void initialize(ubyte Type)(int posX = 100,int posY = 100,bool isShow = true) @trusted
    {
        static if(Type == Simple)
        {
            scope Visual* visual = XDefaultVisual(runtime.display, runtime.displayID);
            int depth = XDefaultDepth(runtime.display, runtime.displayID);

            XVisualInfo* info = new XVisualInfo();
            info.visual = visual;
            info.depth = depth;

            createFromXVisual(info);
        }else
        static if(Type == ContextIn)
        {
            _context = new Context();
            _context.attributeInitialize(GLAttribAutoColorSize!8);

            scope Visual* visual = (cast(Context) _context).visualInfo.visual;
            int depth = (cast(Context) _context).visualInfo.depth;

            createFromXVisual((cast(Context) _context).visualInfo);

            _context.initialize();

            context = _context;
        }

        if(isShow) show();
    }

    override void show() @trusted
    {
        XMapWindow(runtime.display, window);
        XClearWindow(runtime.display, window);
    }

    override void hide() @trusted
    {
        XUnmapWindow(runtime.display, window);
    }

    override void context(IContext ofcontext) @trusted
    {
        glXMakeCurrent(runtime.display, window, (cast(Context) ofcontext).context);

        _context = ofcontext;
    }

    override IContext context() @safe
    {
        return _context;
    }

    override void swapBuffers() @trusted
    {
        glXSwapBuffers(runtime.display, window);
    }

    override int x() @trusted @property
    {
        XWindowAttributes xwa;
        XGetWindowAttributes(runtime.display, window, &xwa);

        return xwa.x;
    }

    override int y() @trusted @property
    {
        XWindowAttributes xwa;
        XGetWindowAttributes(runtime.display, window, &xwa);

        return xwa.y;
    }

    override void resize(uint newWidth,uint newHeight) @trusted
    {
        if(!resizable)
            return;

        _width = newWidth;
        _height = newHeight;

        XResizeWindow(runtime.display, window, newWidth, newHeight);
    }

    override void move(int posX,int posY) @trusted
    {
        XMoveWindow(runtime.display, window, posX, posY);
    }

    override void resizable(bool value) @trusted @property
    {
        long flags;

        scope XSizeHints* sh = XAllocSizeHints();

        scope(exit) XFree(sh);

        XGetWMNormalHints(runtime.display, window, sh, &flags);
        
        if(!value)
        {
            sh.flags |= PMinSize | PMaxSize;
            sh.min_width = _width;
            sh.max_width = _width;
            sh.min_height = _height;
            sh.max_height = _height;
        }else
        {
            sh.flags &= ~(PMinSize | PMaxSize);
        }

        _resizable = value;

        XSetWMNormalHints(runtime.display, window, sh);
    }

    override bool resizable() @safe @property
    {
        return _resizable;
    }

    override void fullscreen(bool value) @trusted @property
    {
        XEvent event;
        
        const wmState = GetAtom!"_NET_WM_STATE";
        const wmFullscreen = GetAtom!"_NET_WM_STATE_FULLSCREEN";

        event.xany.type = ClientMessage;
        event.xclient.message_type = wmState;
        event.xclient.format = 32;
        event.xclient.window = window;
        event.xclient.data.l[1] = wmFullscreen;
        event.xclient.data.l[3] = 0;

        event.xclient.data.l[0] = fullscreen ? 1 : 0;

        XSendEvent(runtime.display,runtime.rootWindow,0,
                SubstructureNotifyMask | SubstructureRedirectMask, &event);

        _fullscreen = value;
    }

    override bool fullscreen() @safe @property
    {
        return _fullscreen;
    }

    override void border(bool value) @trusted @property
    {
        import std.conv : to;

        struct MWMHints {
            ulong flags;
            ulong functions;
            ulong decorations;
            long inputMode;
            ulong status;
        }

        auto hint = MWMHints(1 << 1, 0, value.to!ulong, 0, 0);

        auto wmHINTS = GetAtom!"_MOTIF_WM_HINTS";

        XChangeProperty(runtime.display, window, wmHINTS, wmHINTS, 32,
            PropModeReplace, cast(ubyte*) &hint, MWMHints.sizeof / long.sizeof);

        _border = value;
    }

    override bool border() @safe @property
    {
        return _border;
    }

    override void title(string newTitle) @trusted @property
    {
        XStoreName(runtime.display, window, newTitle.toUTFz!(char*));
        XSetIconName(runtime.display, window, newTitle.toUTFz!(char*));

        _title = newTitle;
    }

    override string title() @safe @property
    {
        return _title;
    }

    override void icon(Image image) @trusted @property
    {
        import tida.color;

        ulong[] pixels = [cast(ulong) image.width,cast(ulong) image.height];

        foreach(pixel; image.pixels)
            pixels ~= pixel.to!(ulong,PixelFormat.ARGB);

        auto event = WMEvent();
        event.first = GetAtom!"_NET_WM_ICON";
        event.second = GetAtom!"CARDINAL";
        event.data = cast(ubyte*) pixels;
        event.length = pixels.length;
        event.mode = PropModeReplace;
        event.format = 32;
        event.window = window;

        event.send();
    }

    override uint width() @safe @property
    {
        return _width;
    }

    override uint height() @safe @property
    {
        return _height;
    }

    override void destroyWindow() @trusted
    {
        XDestroyWindow(runtime.display, window);
    }

    override void eventResize(uint[2] size) @safe
    {
        _width = size[0];
        _height = size[1];
    }

    ulong handle() @safe @property
    {
        return window;
    }

    Visual* getVisual() @safe
    {
        return _visual;
    }

    int getDepth() @safe
    {
        return _depth;
    }

    /++
        Sets the alpha value to the window. Only applicable to x11 windows.
        Params:
            alpha = Alpha value.
    +/
    void alpha(float alpha) @trusted @property
    {
        auto atom = GetAtom!"_NET_WM_WINDOW_OPACITY";
        auto cardinal = GetAtom!"CARDINAL";

        auto tAlpha = cast(ulong) (cast(ulong) 0xFFFFFF * alpha);

        XChangeProperty(runtime.display, window, atom, cardinal, 32,
                PropModeReplace, cast(ubyte*) &tAlpha, 1);
    }

    ~this() @safe
    {
        destroyWindow();
    }
}

version(Windows)
class Context : IContext
{
    import tida.winapi, tida.runtime;

    private
    {
        HDC deviceHandle;
        HGLRC _context;
        PIXELFORMATDESCRIPTOR pfd;
    }

    void deviceMake(HWND window) @trusted
    {
        deviceHandle = GetDC(window);
    }

    override void attributeInitialize(GLAttributes attributes = GLAttribAutoColorSize!8) @trusted
    {
        const flags = (attributes.doubleBuffer ? 
            PFD_DOUBLEBUFFER | PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL : PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL);

        pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
        pfd.nVersion = 1;
        pfd.dwFlags = flags;
        pfd.iPixelType = PFD_TYPE_RGBA;
        pfd.cRedBits = cast(ubyte) attributes.redSize;
        pfd.cGreenBits = cast(ubyte) attributes.greenSize;
        pfd.cBlueBits = cast(ubyte) attributes.blueSize;
        pfd.cAlphaBits = cast(ubyte) attributes.alphaSize;
        pfd.cDepthBits = cast(ubyte) attributes.depthSize;
        pfd.cStencilBits = cast(ubyte) attributes.stencilSize;
        pfd.iLayerType = PFD_MAIN_PLANE;

        auto chsPixel = ChoosePixelFormat(deviceHandle, &pfd);

        if(chsPixel == 0)
            throw new Exception("Not found pixel format!");

        SetPixelFormat(deviceHandle, chsPixel, &pfd);
    }

    PIXELFORMATDESCRIPTOR* pixelformat() @safe {
        return &pfd;
    }

    auto device() @safe {
        return deviceHandle;
    }

    override void initialize() @trusted
    {
        _context = wglCreateContext(deviceHandle);
    }

    override void destroy() @trusted
    {
        wglDeleteContext(_context);
    }

    HGLRC context() @safe
    {
        return _context;
    }

    ~this() @safe
    {
        destroy();
    }
}

version(Windows)
{
    import tida.winapi;

    alias FwglChoosePixelFormatARB = extern(C) bool function( HDC hdc,
                                                    int *piAttribIList,
                                                    float *pfAttribFList,
                                                    uint nMaxFormats,
                                                    int *piFormats,
                                                    uint *nNumFormats);

    alias FwglGetExtensionsStringARB = extern(C) char* function(HDC hdc);

    alias FwglCreateContextAttribsARB = extern(C) HGLRC function(HDC, HGLRC, int*);

    __gshared FwglChoosePixelFormatARB wglChoosePixelFormatARB; 
    __gshared FwglGetExtensionsStringARB wglGetExtensionsStringARB;
    __gshared FwglCreateContextAttribsARB wglCreateContextAttribsARB;

    enum
    {
        WGL_DRAW_TO_WINDOW_ARB = 0x2001,
        WGL_RED_BITS_ARB = 0x2015,
        WGL_GREEN_BITS_ARB = 0x2017,
        WGL_BLUE_BITS_ARB = 0x2019,
        WGL_ALPHA_BITS_ARB = 0x201B,
        WGL_DOUBLE_BUFFER_ARB = 0x2011,
        WGL_DEPTH_BITS_ARB = 0x2022,
        WGL_CONTEXT_MAJOR_VERSION_ARB = 0x2091,
        WGL_CONTEXT_MINOR_VERSION_ARB = 0x2092,
        WGL_CONTEXT_FLAGS_ARB = 0x2094,
        WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB = 0x0002,
        WGL_SUPPORT_OPENGL_ARB = 0x2010,
        WGL_COLOR_BITS_ARB = 0x2014,
        WGL_STENCIL_BITS_ARB = 0x2023,
        WGL_ACCELERATION_ARB = 0x2003,
        WGL_FULL_ACCELERATION_ARB = 0x2027,
        WGL_PIXEL_TYPE_ARB = 0x2013,
        WGL_TYPE_RGBA_ARB = 0x202B,
        WGL_CONTEXT_PROFILE_MASK_ARB = 0x9126,
        WGL_CONTEXT_CORE_PROFILE_BIT_ARB = 0x00000001

    }
}

/// Windows window structure
version(Windows)
class Window : IWindow
{
    import tida.winapi, tida.runtime, tida.graph.image, tida.color;
    import std.utf;

    private
    {
        uint _width;
        uint _height;

        string _title;

        bool _fullscreen;
        bool _border;
        bool _resizable;

        IContext _context;

        LONG style;
        LONG oldStyle;
        WINDOWPLACEMENT wpc;

        HWND window;
    }   

    this(uint newWidth,uint newHeight,string newTitle) @safe
    {
        _width = newWidth;
        _height = newHeight;
        _title = newTitle;
    }

    void initialize(ubyte Type)(int posX = 100,int posY = 100,bool isShow = true) @trusted
    {
        static if(Type == Simple)
        {
            extern(Windows) auto _wndProc(HWND hWnd, uint message, WPARAM wParam, LPARAM lParam) nothrow
            {
                int maxW = 64, maxH = 64, minW = 2048, minH = 2048;

                switch(message) {
                    default:
                        return DefWindowProc(hWnd, message, wParam, lParam);
                }
            }

            WNDCLASSEX wc;

            wc.cbSize = wc.sizeof;
            wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
            wc.lpfnWndProc = &_wndProc;
            wc.hInstance = runtime.instance;
            wc.hCursor = LoadCursor(null, IDC_ARROW);
            wc.lpszClassName = _title.toUTFz!(wchar*);

            RegisterClassEx(&wc);

            window = CreateWindow(_title.toUTFz!(wchar*),_title.toUTFz!(wchar*),
                     WS_CAPTION | WS_SYSMENU | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | WS_THICKFRAME,
                     posX,posY,width,height,null,null,runtime.instance,null);
        }else
        static if(Type == ContextIn)
        {
            import std.exception;

            initialize!Simple(posX,posY,false);

            auto attributes = GLAttributes();

            _context = new Context();
            (cast(Context) _context).deviceMake(window);
            _context.attributeInitialize(attributes);
            _context.initialize();

            auto oldctx = (cast(Context) _context).context;
            auto deviceHandle = (cast(Context) _context).device;

            context = _context;

            void* data = wglGetProcAddress("wglGetExtensionsStringARB");
            enforce(data,"wglGetExtensionsStringARB pointer is null");
            wglGetExtensionsStringARB = cast(FwglGetExtensionsStringARB) data;
            data = null;

            data = wglGetProcAddress("wglChoosePixelFormatARB");
            enforce(data,"wglChoosePixelFormatARB pointer is null");
            wglChoosePixelFormatARB = cast(FwglChoosePixelFormatARB) data;
            data = null;

            data = wglGetProcAddress("wglCreateContextAttribsARB");
            enforce(data,"wglCreateContextAttribsARB pointer is null");
            wglCreateContextAttribsARB = cast(FwglCreateContextAttribsARB) data;
            data = null;

            int[] iattrib =  [
                                WGL_SUPPORT_OPENGL_ARB, true,
                                WGL_DRAW_TO_WINDOW_ARB, true,
                                WGL_DOUBLE_BUFFER_ARB, attributes.doubleBuffer,
                                //WGL_RED_BITS_ARB, attributes.redSize,
                                //WGL_GREEN_BITS_ARB, attributes.greenSize,
                                //WGL_BLUE_BITS_ARB, attributes.blueSize,
                                //WGL_ALPHA_BITS_ARB, attributes.alphaSize,
                                WGL_DEPTH_BITS_ARB, attributes.depthSize,
                                WGL_COLOR_BITS_ARB, attributes.colorDepth,
                                WGL_STENCIL_BITS_ARB, attributes.stencilSize,
                                WGL_PIXEL_TYPE_ARB, WGL_TYPE_RGBA_ARB,
                                WGL_ACCELERATION_ARB, WGL_FULL_ACCELERATION_ARB,
                                0
                            ];

            uint nNumFormats;
            int nPixelFormat;

            wglChoosePixelFormatARB(deviceHandle,   iattrib.ptr, 
                                                    null,
                                                    1, &nPixelFormat,
                                                    &nNumFormats);

            enforce(nPixelFormat, "nNumFormats error!");

            PIXELFORMATDESCRIPTOR pfd;
            DescribePixelFormat(deviceHandle, nPixelFormat, pfd.sizeof, &pfd);
            SetPixelFormat(deviceHandle, nPixelFormat, &pfd);

            int[] attributess =  [
                                    WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
                                    WGL_CONTEXT_MINOR_VERSION_ARB, 0,
                                    WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB,
                                    WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
                                    0
                                ];

            auto ctx = wglCreateContextAttribsARB(deviceHandle, null, attributess.ptr);
            enforce(ctx, "ContextARB is not a create!");

            wglMakeCurrent(null, null);
            wglDeleteContext((cast(Context) _context).context);
            wglMakeCurrent(deviceHandle, ctx);
        }

        if(isShow) show();
    }

    override void show() @trusted
    {
        ShowWindow(window, 1);
    }

    override void hide() @trusted
    {
        ShowWindow(window,SW_HIDE);
    }

    override void context(IContext ofcontext) @trusted @property
    {
        wglMakeCurrent(GetDC(window),(cast(Context) ofcontext).context);

        _context = ofcontext;
    }

    override IContext context() @safe @property
    {
        return _context;
    }

    override void swapBuffers() @trusted @property
    {
        SwapBuffers(GetDC(window));
    }

    override int x() @trusted @property
    {
        RECT rect;

        GetWindowRect(window,&rect);

        return rect.left;
    }

    override int y() @trusted @property
    {
        RECT rect;

        GetWindowRect(window,&rect);

        return rect.top;
    }

    override void resize(uint newWidth,uint newHeight) @trusted
    {
        SetWindowPos(window, null, x, y ,newWidth, newHeight, 0);

        _width = newWidth;
        _height = newHeight;
    }

    override void move(int posX,int posY) @trusted
    {
        SetWindowPos(window, null, posX, posY, _width, _height, 0);
    }

    override void resizable(bool value) @trusted @property
    {
        auto lStyle = GetWindowLong(window, GWL_STYLE);
        
        if(value) {
            lStyle |= WS_THICKFRAME;
        }else {
            lStyle &= ~(WS_THICKFRAME);
        }

        SetWindowLong(window, GWL_STYLE, lStyle);

        _resizable = value;
    }

    override bool resizable() @safe @property
    {
        return _resizable;
    }

    override void fullscreen(bool value) @trusted @property
    {
        if(value) 
        {
            GetWindowPlacement(window, &wpc);
            if(style == 0)
                style = GetWindowLong(window, GWL_STYLE);
            if(oldStyle == 0)
                oldStyle = GetWindowLong(window,GWL_EXSTYLE);

            auto NewHWNDStyle = style;
            NewHWNDStyle &= ~WS_BORDER;
            NewHWNDStyle &= ~WS_DLGFRAME;
            NewHWNDStyle &= ~WS_THICKFRAME;

            auto NewHWNDStyleEx = oldStyle;
            NewHWNDStyleEx &= ~WS_EX_WINDOWEDGE;

            SetWindowLong(window, GWL_STYLE, NewHWNDStyle | WS_POPUP );
            SetWindowLong(window, GWL_EXSTYLE, NewHWNDStyleEx | WS_EX_TOPMOST);
            ShowWindow(window, SHOW_FULLSCREEN);
        } else 
        {
            SetWindowLong(window, GWL_STYLE, style);
            SetWindowLong(window, GWL_EXSTYLE, oldStyle);
            ShowWindow(window, SW_SHOWNORMAL);
            SetWindowPlacement(window, &wpc);

            style = 0;
            oldStyle = 0;
        }

        _fullscreen = value;
    }

    override bool fullscreen() @safe @property
    {
        return _fullscreen;
    }

    override void border(bool value) @trusted @property
    {
        auto style = GetWindowLong(window, GWL_STYLE);

        if(!value)
        {
            style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
        }else
        {
            style |= (WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX | WS_SYSMENU);
        }

        SetWindowLong(window, GWL_STYLE, style);

        SetWindowPos(window, null, 0,0,0,0, SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER);

        _border = value;
    }

    override bool border() @trusted @property
    {
        return _border;
    }

    override void title(string newTitle) @trusted @property
    {
        SetWindowTextA(window,newTitle.toUTFz!(char*));

        _title = newTitle;
    }

    override string title() @safe @property
    {
        return _title;
    }

    override void icon(Image image) @trusted @property
    {
        HICON icon;

        ubyte[] pixels = image.bytes!(PixelFormat.BGRA);

        ICONINFO icInfo;

        auto bitmap = CreateBitmap(image.width,image.height,1,32,cast(PCVOID) pixels);

        icInfo.hbmColor = bitmap;
        icInfo.hbmMask = CreateBitmap(width,height,1,1,null);

        icon = CreateIconIndirect(&icInfo);

        SendMessage(window, WM_SETICON, ICON_SMALL, cast(LPARAM) icon);
        SendMessage(window, WM_SETICON, ICON_BIG, cast(LPARAM) icon);
    }

    override uint width() @safe @property
    {
        return _width;
    }

    override uint height() @safe @property
    {
        return _height;
    }

    override void destroyWindow() @trusted
    {
        DestroyWindow(window);
    }

    override void eventResize(uint[2] size) @safe
    {
        _width = size[0];
        _height = size[1];
    }

    HWND handle() @safe
    {
        return window;
    }

    ~this() @safe
    {
        destroyWindow();
    }
}
