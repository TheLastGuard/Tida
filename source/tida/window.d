/++
    A module for working with windows in a cross-platform environment. 
    A window is created in both Windows and Linux environments. OS X 
    and other operating systems are currently not supported due to 
    lack of testing on these platforms.

    The window is created primarily not in the constructor, in the constructor 
    the window parameters are initialized for its creation. All this is created 
    by the `initialize` method, with an indication of the template parameter, 
    which window to create.

    A window can be created either with a ready-made context or without it 
    (i.e., created manually)(Please note that the context is strictly created 
    only for the opengl library).

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
    context.attribInitialize(window);
    context.initialize(window);

    /*
        Sets the context to this window.
    */
    window.contextSet(context);
    ---

    Then you can draw something on the window, control it and so on.

    Also, please note that creating multiple windows is currently not supported.

    TODO: 
        * Make it possible to create several windows at the same time.
          Namely, to make `shared` methods for working in different threads, 
          both for the window and for the context, event handler and render.

    Authors: TodNaz
    License: MIT
+/
module tida.window;

/+
    Needed for the WGL function.
+/
version(Windows) pragma(lib,"opengl32.lib");

/++
    A property to create just a window, without creating a context. 
    Initialize it like this:
    ---
    window.initialize!Simple;
    ---
+/
static immutable ubyte Simple = 0;

/++
    Property for creating a window with a context for graphics. 
    It is initialized like this:
    ---
    window.initialize!ContextIn;
    ---
+/
static immutable ubyte ContextIn = 1;

/++
    Property for creating a window on another thread. It is not used now.
+/
static immutable ubyte ParrarelContext = 2;

/// The shell is empty. Only needed in WebAssembly mode.
static immutable ubyte Empty = 3;

/++
    Attributes for creating context.
+/
public struct GLAttributes
{
    public
    {
        int redSize = 8; /// Red size
        int greenSize = 8; /// Green size
        int blueSize = 8; /// Blue size
        int alphaSize = 8; /// Alpha channel size
        int depthSize = 8; /// Depth size
        int stencilSize = 8; /// Stencil size
        int colorDepth = 32; /// Color depth
    }
}

version(WebAssembly)
{
    public import tida.betterc.window;
}

version(WebAssembly) {}
else:

/++
    Class for describing and creating context for the window.
+/
public class Context
{
    version(Posix)
    {
        import x11.X, x11.Xlib, x11.Xutil;
        import dglx.glx;
    }

    version(Windows)
    {
        import core.sys.windows.windows;
    }

    import tida.runtime, tida.exception;

    private
    {
        version(Posix)
        {
            GLXContext ctx;
            XVisualInfo* visual;
            GLXFBConfig bestFbcs;
        }

        version(Windows)
        {
            HDC deviceHandle;
            HGLRC ctx;
        }
    }

    public
    {
        GLAttributes attrib; /// Attributes for creating context.
    }

    /// 
    version(Windows) public HDC DC() @safe nothrow
    {
        return deviceHandle;
    }

    /++
        Context from x11 environment (`GLXContext`).
    +/
    version(Posix) public GLXContext xContext() @safe @property nothrow
    {
        return ctx;
    }

    /++
        Context from windows environment ('HGLRC').
    +/
    version(Windows) public HGLRC wContext() @safe @property nothrow
    {
        return ctx;
    }

    ///
    version(Windows) public void wAttribInitialize(Window window) @trusted 
    {
        PIXELFORMATDESCRIPTOR pfd;

        pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
        pfd.nVersion = 1;
        pfd.dwFlags = PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER;
        pfd.iPixelType = PFD_TYPE_RGBA;
        pfd.cRedBits = cast(ubyte) attrib.redSize;
        pfd.cGreenBits = cast(ubyte) attrib.greenSize;
        pfd.cBlueBits = cast(ubyte) attrib.blueSize;
        pfd.cAlphaBits = cast(ubyte) attrib.alphaSize;
        pfd.cDepthBits = cast(ubyte) attrib.depthSize;
        pfd.cStencilBits = cast(ubyte) attrib.stencilSize;

        deviceHandle = GetDC(window.wWindow);

        auto chsPixel = ChoosePixelFormat(deviceHandle, &pfd);
        SetPixelFormat(deviceHandle, chsPixel, &pfd);
    }

    ///
    version(Windows) public void wContextInitialize(Window window) @trusted 
    {
        ctx = wglCreateContext(deviceHandle);
    }

    /++
        Initializes the context parameters in the x11 environment.

        All parameters are taken from the attrib variable. The default will always be double buffering.
    +/
    version(Posix) public void xAttribInitialize() @trusted @live
    {
        int[] glxAttribs = 
            [
                GLX_X_RENDERABLE    , True,
                GLX_DRAWABLE_TYPE   , GLX_WINDOW_BIT,
                GLX_RENDER_TYPE     , GLX_RGBA_BIT,
                GLX_X_VISUAL_TYPE   , GLX_TRUE_COLOR,
                GLX_RED_SIZE        , attrib.redSize,
                GLX_GREEN_SIZE      , attrib.greenSize,
                GLX_BLUE_SIZE       , attrib.blueSize,
                GLX_ALPHA_SIZE      , attrib.alphaSize,
                GLX_DEPTH_SIZE      , attrib.depthSize,
                GLX_STENCIL_SIZE    , attrib.stencilSize,
                GLX_DOUBLEBUFFER    , True,
                None
            ];

        int fbcount;
        scope GLXFBConfig* fbc = glXChooseFBConfig(runtime.display, runtime.displayID, cast(int*) glxAttribs, &fbcount);

        scope(exit) XFree(fbc);

        if(fbc is null)
            throw new ContextException(ContextError.fbsNull,"fbc config is null!");

        int bestFbc = -1, worstFbc = -1, bestNumSamp = -1, worstNumSamp = 999;

        for(int i = 0; i < fbcount; ++i) {
            XVisualInfo *vi = glXGetVisualFromFBConfig(runtime.display,fbc[i]);
            if(vi !is null) 
            {
                int sampBuf, samples;

                glXGetFBConfigAttrib(runtime.display,fbc[i],GLX_SAMPLE_BUFFERS,&sampBuf);
                glXGetFBConfigAttrib(runtime.display,fbc[i],GLX_SAMPLES,&samples);

                if(bestFbc < 0 || (sampBuf && samples > bestNumSamp)) {
                    bestFbc = i;
                    bestNumSamp = samples;
                }

                if(worstFbc < 0 || !sampBuf || samples < worstNumSamp)
                    worstFbc = i;

                worstNumSamp = samples;
            }

            XFree(vi);
        }

        bestFbcs = fbc[bestFbc];

        visual = glXGetVisualFromFBConfig(runtime.display, bestFbcs);
    }

    /++
        Creates a context in the x11 environment.
    +/
    version(Posix) public void xContextInitialize() @trusted
    {
        ctx = glXCreateNewContext(runtime.display, bestFbcs, GLX_RGBA_TYPE, null, true);
    }

    ///
    version(Posix) public XVisualInfo* xGetVisual() @safe nothrow
    {
        return visual;
    }

    /++
        Initializes the parameters of the context.
    +/
    public void attribInitialize(Window window) @safe
    {
        version(Posix) xAttribInitialize();
        version(Windows) wAttribInitialize(window);
    }

    /++
        Initializes the context.
    +/
    public void initialize(Window window) @safe
    {
        version(Posix) xContextInitialize();
        version(Windows) wContextInitialize(window);
    }

    ~this() @trusted
    {
        version(Posix) glXDestroyContext(runtime.display, ctx);
        version(Windows) wglDeleteContext(ctx);
    }
}

/++
    Window.
+/
public class Window
{
    version(Posix)
    {
        import x11.X, x11.Xlib, x11.Xutil, dglx.glx;
    }

    version(Windows)
    {
        import core.sys.windows.windows;
    }

    import tida.runtime, tida.color, tida.exception, tida.graph.image;
    import std.utf;

    private
    {
        int _width;
        int _height;

        string _title;
        Color!ubyte _background = Color!ubyte(255,255,255);

        version(Posix)
        {
            x11.Xlib.Window window;
        }

        version(Windows)
        {
            HWND window;
        }

        Context context;
    }

    /++
        Initialization of window parameters.

        Note:
            * The window will not be created, but the parameters for its creation will be initialized.

        Params:
            newWidth = The width of the window when created.
            newHeight = The height of the window when created.
            newTitle = The title of the window when created.
    +/
    this(int newWidth,int newHeight,string newTitle) @safe
    {
        _width = newWidth;
        _height = newHeight;
        _title = newTitle;
    }

    invariant
    {
        assert(_width > 0,"A window cannot be without content!.");
        assert(_height > 0,"A window cannot be without content!");
    }

    /++
        Initializes the window according to the parameters.

        A window can be created with the following parameters:
        * `Simple` - Will create a simple window with no context when 
                     you need to manually create it.
        * `ContextIn` - Creates a window with a context for graphics.

        Params:
            Type = What type of window to initialize.
            posX = The x-axis position.
            posY = The y-axis position.
    +/
    public void initialize(ubyte Type)(int posX = 100,int posY = 100) @safe
    in
    {
        assert(posX > 0,"The position of the window cannot be negative!");
        assert(posY > 0,"The position of the window cannot be negative!");
    }
    do
    {
        static if(Type == Simple)
        {
            version(Posix) xWindowSimpleInitialize(posX,posY);
            version(Window) wWindowInit(posX,posY);
        }else
        static if(Type == ContextIn)
        {
            version(Posix)
            {
                context = new Context();
                context.attribInitialize(this);

                xWindowInit(posX,posY,context.xGetVisual());

                context.xContextInitialize();

                contextSet(context);
                
                xWindowShow();
            }

            version(Windows)
            {
                wWindowInit(posX,posY);

                context = new Context();
                context.attribInitialize(this);
                context.initialize(this);

                contextSet(context);

                wWindowShow();
            }
        }else
            static assert(null,"It is impossible not to initialize the window if you have called such a command.");
    }

    /++
        Initializes the window for the context.

        Params:
            posX = The x-axis position.
            posY = The y-axis position.
    +/
    version(Windows) public void wWindowInit(int posX,int posY) @trusted
    {
        extern(Windows) auto _wndProc(HWND hWnd, uint message, WPARAM wParam, LPARAM lParam) nothrow
        {
            return DefWindowProc(hWnd, message, wParam, lParam);
        }

        WNDCLASSEX wc;

        wc.cbSize = wc.sizeof;
        wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
        wc.lpfnWndProc = &_wndProc;
        wc.hInstance = runtime.hInstance;
        wc.hCursor = LoadCursor(null, IDC_ARROW);
        wc.lpszClassName = _title.toUTFz!(wchar*);

        RegisterClassEx(&wc);

        window = CreateWindow(_title.toUTFz!(wchar*),_title.toUTFz!(wchar*),
                 WS_CAPTION | WS_SYSMENU | WS_CLIPSIBLINGS | WS_CLIPCHILDREN,
                 posX,posY,width,height,null,null,runtime.hInstance,null);

        if(window is null)
            throw new WindowException(WindowError.noCreate,"Window is not create!");
    }  

    /++
        Initializes the window for the context.

        Params:
            posX = The x-axis position.
            posY = The y-axis position.
            visual = Information from context for create window.
    +/
    version(Posix) public void xWindowInit(int posX,int posY,XVisualInfo* visual = null) @trusted
    {
        XSetWindowAttributes windowAttribs;
        windowAttribs.border_pixel = Color!ubyte(0,0,0).conv!uint;
        windowAttribs.background_pixel = _background.conv!uint;
        windowAttribs.override_redirect = True;
        windowAttribs.colormap = XCreateColormap(runtime.display, RootWindow(runtime.display, runtime.displayID), 
                                                 visual.visual, AllocNone);

        window = XCreateWindow(runtime.display, RootWindow(runtime.display, runtime.displayID), posX, posY, 
                               width, height,0,visual.depth,InputOutput,visual.visual,
                               CWBackPixel|CWColormap|CWBorderPixel|CWEventMask, &windowAttribs);

        XStoreName(runtime.display, window, _title.toUTFz!(char*));
    }

    /++
        Created simple window in environment x11.

        Params:
            posX = The x-axis position.
            posY = The y-axis position.
    +/
    version(Posix) public void xWindowSimpleInitialize(int posX,int posY) @trusted
    {
        window = XCreateSimpleWindow(runtime.display, RootWindow(runtime.display,runtime.displayID),
                                     posX,posY,width,height,1,Color!ubyte(0,0,0).conv!uint,_background.conv!uint);

        XStoreName(runtime.display, window, _title.toUTFz!(char*));
    }

    /++
        Show window in workspace.
    +/
    version(Posix) public void xWindowShow() @trusted
    {
        XMapWindow(runtime.display, window);
    }

    /// ditto
    version(Windows) public void wWindowShow() @trusted
    {
        ShowWindow(window, 1);
    }

    /++
        Sets an _initialized_ context.

        Params:
            context = Initialized context.
    +/
    public void contextSet(Context context) @trusted
    {
        version(Posix)
        {
            xContextSet(context.xContext);
        }

        version(Windows)
        {
            wContextSet(context.wContext);
        }
    }

    /++
        Sets an _initialized_ context of windows environment.
    +/
    version(Windows) public void wContextSet(HGLRC ctx) @trusted
    {
        wglMakeCurrent(context.DC,ctx);
    }

    /++
        Sets an _initialized_ context of x11 environment.
    +/
    version(Posix) public void xContextSet(GLXContext ctx) @trusted
    {
        glXMakeCurrent(runtime.display, xWindow, ctx);
    }

    /++
        Swaps buffers.
    +/
    public void swapBuffers() @trusted
    {
        version(Posix) xSwapBuffers();
        version(Windows) wSwapBuffers();
    }

    /++
        Swaps buffers in windows environment. 
    +/
    version(Windows) public void wSwapBuffers() @trusted
    {
        SwapBuffers(context.DC);
    }

    /++
        Swaps buffers in x11 environment. 
    +/
    version(Posix) public void xSwapBuffers() @trusted
    {
        glXSwapBuffers(runtime.display, xWindow);
    }

    /++
        Window in x11 environment.
    +/
    version(Posix) x11.Xlib.Window xWindow() @trusted @property nothrow 
    {
        return window;
    }

    /++
        Window in windows environment.
    +/
    version(Windows) HWND wWindow() @trusted @property nothrow
    {
        return window;
    }

    ///
    version(Windows) public int wGetX() @trusted
    {
        RECT rect;

        GetWindowRect(window,&rect);

        return rect.left;
    }

    ///
    version(Windows) public int wGetY() @trusted
    {
        RECT rect;

        GetWindowRect(window,&rect);

        return rect.top;
    }

    ///
    version(Posix) public int xGetX() @trusted
    {
        XWindowAttributes xwa;
        XGetWindowAttributes(runtime.display, window, &xwa);

        return xwa.x;
    }

    ///
    version(Posix) public int xGetY() @trusted
    {
        XWindowAttributes xwa;
        XGetWindowAttributes(runtime.display, window, &xwa);

        return xwa.y;
    }

    /++
        X-axis position of the window.
    +/
    public int x() @safe @property
    {
        version(Windows) return wGetX();
        version(Posix)   return xGetX();
    }

    /++
        Y-axis position of the window.
    +/
    public int y() @safe @property
    {
        version(Windows) return wGetY();
        version(Posix)   return xGetY();
    }

    ///
    version(Windows) public void wResize(immutable uint newWidth,immutable uint newHeight) @trusted
    {
        SetWindowPos(window, null, wGetX(),wGetY(),newWidth,newHeight, 0);
    }

    ///
    version(Windows) public void wMove(immutable int posX,immutable int posY) @trusted
    {
        SetWindowPos(window, null, posX, posY, width, height, 0);
    }

    ///
    version(Posix) public void xResize(immutable uint newWidth,immutable uint newHeight) @trusted
    {
        XResizeWindow(runtime.display, window, newWidth, newHeight);
    }

    ///
    version(Posix) public void xMove(immutable int posX,immutable int posY) @trusted
    {
        XMoveWindow(runtime.display, window, posX, posY);
    }

    /++
        Moves the window to the specified location.

        Params:
            posX = New X-axis position window.
            posY = New Y-axis position window.
    +/
    public void move(immutable int posX,immutable int posY) @safe 
    in
    {
        assert(posX > 0,"The position of the window cannot be negative!");
        assert(posY > 0,"The position of the window cannot be negative!");
    }
    do
    {
        version(Posix) xMove(posX,posY);
        version(Windows) wMove(posX,posY);
    }

    /++
        Resizes the window.

        Params:
            newWidth = Window width.
            newHeight = Window height.
    +/
    public void resize(immutable uint newWidth,immutable uint newHeight) @safe
    in
    {
        assert(newWidth > 0,"A window cannot be without content!");
        assert(newHeight > 0,"A window cannot be without content!");
    }
    do
    {
        version(Posix) xResize(newWidth,newHeight);
        version(Windows) wResize(newWidth,newHeight);

        _width = newWidth;
        _height = newHeight;
    }

    ///
    version(Posix) public void xHide() @trusted
    {
        XUnmapWindow(runtime.display, window);
    }

    ///
    version(Windows) public void wHide() @trusted
    {
        ShowWindow(window,SW_HIDE);
    }

    /++
        Hides the window.
    +/
    public void hide() @safe
    {
        version(Posix) xHide();
        version(Windows) wHide();
    }

    ///
    version(Posix) public void xIcon(Image image) @trusted
    {
        Atom wmIcon     = XInternAtom(runtime.display,"_NET_WM_ICON", false);
        Atom cardinal   = XInternAtom(runtime.display,"CARDINAL",false);

        uint[] pixels = [image.width,image.height] ~ image.colors(PixelFormat.ARGB);

        XChangeProperty(runtime.display, window, wmIcon, cardinal,
                32, PropModeReplace, cast(ubyte*) pixels.ptr,cast(int) pixels.length);

        XFlush(runtime.display);
    }

    ///
    public void icon(Image image) @safe @property @disable
    {
        version(Posix) xIcon(image);
    }

    ///
    public void resizeEvent(uint rWidth,uint rHeight) @safe @disable 
    {
        _width = rWidth;
        _height = rHeight;
    }

    /// Window title.
    public immutable(string) title() @safe @property nothrow
    {
        return _title;
    }

    /// ditto
    public immutable(string) title() @safe @property nothrow const
    {
        return _title;
    }

    /// ditto
    public void title(string newTitle) @trusted @property nothrow
    {
        version(Posix) XStoreName(runtime.display, xWindow, newTitle.toUTFz!(char*));
        version(Windows) SetWindowTextA(wWindow,newTitle.toUTFz!(char*));
    }

    /// Window width.
    public immutable(uint) width() @safe @property nothrow
    {
        return _width;
    }

    /// ditto
    public immutable(uint) width() @safe @property nothrow const
    {
        return _width;
    }

    /// Window height.
    public immutable(uint) height() @safe @property nothrow
    {
        return _height;
    }

    /// ditto
    public immutable(uint) height() @safe @property nothrow const
    {
        return _height;
    }

    override string toString() @safe const
    {
        import std.conv : to;

        return "Window(width: "~width.to!string~",height: "~height.to!string~",title: "~title~")";
    }

    ~this() @trusted
    {
        version(Posix)
        {
            XDestroyWindow(runtime.display, window);
        }

        version(Windows)
        {
            DestroyWindow(window);
        }
    }
}