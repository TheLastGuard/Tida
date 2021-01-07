/++
    A module for working with windows in a cross-platform environment. A window is created in both Windows and Linux 
    environments. OS X and other operating systems are currently not supported due to lack of testing on these 
    platforms.

    The window is created primarily not in the constructor, in the constructor the window parameters are initialized 
    for its creation. All this is created by the `initialize` method, with an indication of the template parameter, 
    which window to create.

    A window can be created either with a ready-made context or without it (i.e., created manually)(Please note that 
    the context is strictly created only for the opengl library).

    Creating a simple window is done with a simple `initialize` function:
    ---
    /*
        We just allocate memory for the window, this is not yet the 
        stages of its creation.
    */
    Window window = new Window(640,480,"MyTitle");

    /*
        Creates a simple window with no graphics context.
    */
    window.initialize!Simple;
    ---

    There are two ways to create a context:
    1. Initialize the window immediately with the context:
    ---
    window.initialize!ContextIn;
    ---
    2. Create it manually:
    ---
    window.initialize!Simple;

    Context context = new Context();

    /*
        Indicates the attributes of the context.
    */
    context.attrib = GLAttributes(...);
    context.attributeInitialize();
    context.initialize();

    /*
        Sets the context to this window.
    */
    window.context = context;
    ---

    At the moment, windows cannot work in parallel, as well as event tracking and object rendering, so 
    you shouldn't even try to create windows in different threads, this will lead to data segmentation.
    
    It is also recommended to create a window in the recommended way, but if you want to create your 
    own render, then immediately put a context in the window so that there are no errors when creating 
    a render or manual rendering.

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
    +/
    void attributeInitialize(GLAttributes attributes) @safe;

    /++
        Initializes the contest itself.
    +/
    void initialize() @safe;

    /// 
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

    /// Shows a window.
    void context(IContext context) @safe @property;

    /// ditto
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

    void destroyWindow() @safe;

    void eventResize(uint[2] size) @safe;
}

version(Posix)
class Context : IContext
{
    import dglx.glx;
    import tida.x11, tida.runtime;

    private
    {
        GLXContext _context;
        XVisualInfo* visual;
        GLXFBConfig bestFbcs;   
    }

    override void attributeInitialize(GLAttributes attributes) @trusted
    in(glxIsLoad,"GLX libraries were not loaded!")
    {
        import std.conv : to;

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

        int fbcount;
        auto fbc = glXChooseFBConfig(runtime.display,runtime.displayID,glxAttribs.ptr,&fbcount);
        
        assert(fbc, "fbc was not found!");

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

        bestFbcs = fbc[bestNum];

        visual = glXGetVisualFromFBConfig(runtime.display, bestFbcs);

        XFree(fbc);
    }

    override void initialize() @trusted
    {
        _context = glXCreateNewContext(runtime.display, bestFbcs, GLX_RGBA_TYPE, null, True);
    }

    override void destroy() @trusted
    {
        glXDestroyContext(runtime.display, context);
        XFree(visual);
        XFree(bestFbcs);
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

version(Posix)
class Window : IWindow
{
    import tida.x11, tida.runtime, tida.graph.image;
    import dglx.glx;
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

    this(uint newWidth,uint newHeight,string newTitle) @safe
    {
        _width = newWidth;
        _height = newHeight;
        _title = newTitle;
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
        }else
        static if(Type == ContextIn)
        {
            _context = new Context();
            _context.attributeInitialize(GLAttributes());

            scope Visual* visual = (cast(Context) _context).visualInfo.visual;
            int depth = (cast(Context) _context).visualInfo.depth;

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
            pixels ~= pixel.conv!(ulong,PixelFormat.ARGB);

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
    }

    void deviceMake(HWND window) @trusted
    {
        deviceHandle = GetDC(window);
    }

    override void attributeInitialize(GLAttributes attributes) @trusted
    {
        PIXELFORMATDESCRIPTOR pfd;

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

        auto chsPixel = ChoosePixelFormat(deviceHandle, &pfd);
        SetPixelFormat(deviceHandle, chsPixel, &pfd);
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
            initialize!Simple(posX,posY,false);

            _context = new Context();
            (cast(Context) _context).deviceMake(window);
            _context.attributeInitialize(GLAttributes());
            _context.initialize();

            context = _context;
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