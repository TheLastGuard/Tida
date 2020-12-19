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
    context.attribInitialize(window);
    context.initialize(window);

    /*
        Sets the context to this window.
    */
    window.contextSet(context);
    ---

    At the moment, windows cannot work in parallel, as well as event tracking and object rendering, so 
    you shouldn't even try to create windows in different threads, this will lead to data segmentation.
    
    It is also recommended to create a window in the recommended way, but if you want to create your 
    own render, then immediately put a context in the window so that there are no errors when creating 
    a render or manual rendering.

    TODO: 
        * Make it possible to create several windows at the same time. Namely, to make `shared` methods for 
          working in different threads, both for the window and for the context, event handler and render.
          
        * Make normal full screen and resize. The fact is that when the size is changed, the render is not 
          updated, even if you do a redraw. Apparently, the nodes allocate a buffer.

    Authors: TodNaz
    License: MIT
+/
module tida.window;

version(Windows) {
    private struct WindowSizeInfo
    {
        int minimumWidth, minimumHeight;
        int maximumWidth, maximumHeight;
    }
}

/+
    Needed for the WGL function.
+/
version(Windows) pragma(lib,"opengl32.lib");

version(Posix)
{
    static immutable _NET_WM_STATE_ADD = 0; /// Add state
    static immutable _NET_WM_STATE_REMOVE = 1; /// Remove state
}

static immutable ubyte Empty = 0;
static immutable ubyte Simple = 1;
static immutable ubyte ContextIn = 2;

/++
    Attributes for creating context.
+/
public struct GLAttributes
{
    import tida.x11;

    public
    {
        int redSize = 8; /// Red size
        int greenSize = 8; /// Green size
        int blueSize = 8; /// Blue size
        int alphaSize = 8; /// Alpha channel size
        int depthSize = 24; /// Depth size
        int stencilSize = 8; /// Stencil size
        int colorDepth = 32; /// Color depth
        bool doubleBuffer = true;
    }
}

/++
	Returns a list of extensions. Because Openg of the second version is used here, it is unlikely that 
	it will be useful, but there is also a third version in the plan.
	
	Returns: `string[]`
+/
version(Posix) public string[] extensionList() @trusted
{
    import std.conv : to;
    import std.array : split;
    import dglx.glx;
    import tida.runtime;

    return glXQueryExtensionsString(runtime.display,runtime.displayID)
        .to!string
        .split(' ')[0 .. $ - 1];
}

/++
	Indicates if the following extension is supported.
	
	Params:
		name = Extension name.
+/
public bool isExtensionSupported(string name) @trusted
{
    return 0;
}

/++
    An object for describing the context for rendering objects in the opengl library. Able to create a context 
    in both Linux and Windows using the glx (for x11) and wgl (for Windows) libraries.

    The contest is also easily set to a window using the window's `contextSet` method:
    ---
    window.contextSet(myContext);
    ---
+/
public class Context
{
    version(Posix)
    {
        import tida.x11;
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
        /++
            Context creation attributes. It is not necessary to specify them, the attributes 
            are already pre-specified.
        +/
        GLAttributes attrib;
    }

    ///
    this() @safe {}

    /++
        Initializes a ready-made context.
        
        Params:
            ctx = GLXContext.
            info = Rendering information: Optional.
    +/
    version(Posix) this(GLXContext ctx,XVisualInfo* info = null) @safe
    {
        this.ctx = ctx;
        this.visual = info;
    }

    /++
    	Initializes a ready-made context.
        
        Params:
            ctx = GLXContext.
            info = Rendering information: Optional.
    +/		
    version(Windows) this(HGLRC ctx,HDC deviceHandle) @safe
    {
        this.ctx = ctx;
        this.deviceHandle = deviceHandle;
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

        auto flags = (attrib.doubleBuffer ? 
            PFD_DOUBLEBUFFER | PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL : PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL);

        pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
        pfd.nVersion = 1;
        pfd.dwFlags = flags;
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
    version(Windows) public auto wContextInitialize(Window window) @trusted 
    {
        return this.ctx = wglCreateContext(deviceHandle);
    }

    /++
        Initializes the context parameters in the x11 environment.

        All parameters are taken from the attrib variable. The default will always be double buffering.
    +/
    version(Posix) public auto xAttribInitialize() @trusted @live
    {
        import std.conv : to;

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
                GLX_DOUBLEBUFFER    , attrib.doubleBuffer.to!int,
                None
            ];

        int fbcount;
        auto fbc = glXChooseFBConfig(runtime.display,runtime.displayID,glxAttribs.ptr,&fbcount);

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

        auto visual = glXGetVisualFromFBConfig(runtime.display, bestFbcs);
        XFree(fbc);

        return visual;
    }

    /++
        Creates a context in the x11 environment.
    +/
    version(Posix) public auto xContextInitialize() @trusted
    {
        return this.ctx = glXCreateNewContext(runtime.display, bestFbcs, GLX_RGBA_TYPE, null, True);
    }

    ///
    version(Posix) public XVisualInfo* xGetVisual() @safe nothrow
    {
        return visual;
    }

    /++
        Initializes the parameters of the context.
    +/
    public auto attribInitialize(Window window) @safe
    {
        version(Posix) return xAttribInitialize();
        version(Windows) wAttribInitialize(window);
    }

    /++
        Initializes the context.
    +/
    public auto initialize(Window window) @safe
    {
        version(Posix) xContextInitialize();
        version(Windows) wContextInitialize(window);
    }

    ~this() @trusted
    {
        version(Posix) {
            glXDestroyContext(runtime.display, ctx);
            XFree(xGetVisual());
            XFree(bestFbcs);
        }

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
        import tida.x11, dglx.glx;
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

        int oldWidth;
        int oldHeight;

        bool oldResizable = false;

        string _title;
        Color!ubyte _background = Color!ubyte(255,255,255);

        ubyte typeInitialize;

        version(Posix)
        {
            x11.Xlib.Window window;
        }

        version(Windows)
        {
            HWND window;
            LONG style;
            LONG oldStyle;
            WINDOWPLACEMENT wpc;
        }

        Context context;
        bool _resizable = false;

        uint _maxWidth = 2048, _maxHeight = 2048;
        uint _minWidth = 64,   _minHeight = 64;

        bool _fullscreen = false;
        Window _parent;
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

    /++
		Initializes the window, assuming the window has an owner.
		
		Params:
			parent = Owner. 
			newWidth = The width of the window when created.
			newHeight = The height of the window when created.
			newTitle = The title of the window when created.
    +/
    this(Window parent,int newWidth,int newHeight,string newTitle) @safe
    {
        this(newWidth,newHeight,newTitle);
        this._parent = parent;
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
            
        Also, see if another window has been created. at the moment, multi-window mode is not yet 
        supported in the program, which will lead to errors in the window manager server.
        
        Also, if you need to reinitialize the window, delete the previous window.
            
        Example:
        ---
        auto window = new Window(640,480,"Title.");
        window.initialize!Simple(100,100);
        ---
        
        initializing a window when you need your own context:
        ---
        auto context = new Context();
        context.attrib = GLAttributes(...);
        context.attribInitialize(window);
        
        window.initialize!Simple(100,100);
        
        context.initialize(window);
        window.contextSet(context);
        ---
        
        Or you can simply trust the window itself to create the context:
        ---
        window.initialize!ContextIn;
        ---
    +/
    public void initialize(ubyte Type)(int posX = 100,int posY = 100) @trusted
    in(posX > 0,"The position of the window cannot be negative!")
    in(posY > 0,"The position of the window cannot be negative!")
    do
    {
        static if(Type == Simple)
        {
            version(Posix) xWindowInit(posX,posY);
            version(Window) wWindowInit(posX,posY);
            
            show();
        }else
        static if(Type == ContextIn)
        {
            version(Posix)
            {
                context = new Context();

                xWindowInit(posX,posY,context.xAttribInitialize);
                xWindowShow();

                xContextSet(context.xContextInitialize);

                XSync(runtime.display, false);
                XFlush(runtime.display);
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

        typeInitialize = Type;
    }

    /++
    	Finds out if there is a context. Note that the context must be created by the window, 
    	or passed to it. If he does not know, but there is such a function, such a function will 
    	not work, call the runtime command to find the context.
    +/
    public bool isContext() @safe
    {
        return context is null;
    }

    /++
    	Initialization of a window using an already created window.
    	
    	Params:
    		window = X11 Window structure.
    +/
    version(Posix) public void initFrom(x11.Xlib.Window window) @trusted
    in(window != 0,"Window is bad.")
    body
    {
        this.window = window;
        XWindowAttributes attrib;
        XGetWindowAttributes(runtime.display, window, &attrib);

        _width = attrib.width;
        _height = attrib.height;
    }
    
    /++
    	Initialization of a window using an already created window.
    	
    	Params:
    		window = Windows Window structure.
    +/
    version(Windows) public void initFrom(HNDW window) @trusted
    in(window !is null,"Window is bad.")
    body
    {
    	this.window = window;
    	RECT rect;
    	GetWindowRect(window,&rect);
    	
    	_width = rect.right;
    	_height = rect.bottom;
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
            int maxW = 64, maxH = 64, minW = 2048, minH = 2048;

            switch(message) {
                version(WindowMaxType)
                {
                    case WM_USER:
                        if(wParam == 0x01) {
                            scope window = cast(WindowSizeInfo*) lParam;

                            maxW = window.maximumWidth;
                            maxH = window.maximumHeight;
                            minW = window.minimumWidth;
                            minH = window.minimumHeight;

                            window = null;
                        }

                        return DefWindowProc(hWnd, message, wParam, lParam);

                    case WM_GETMINMAXINFO:
                        scope MINMAXINFO* info = cast(MINMAXINFO*) lParam;

                        info.ptMaxTrackSize.x = maxW;
                        info.ptMaxTrackSize.y = maxH;
                        info.ptMinTrackSize.x = minW;
                        info.ptMinTrackSize.y = minH;

                        info = null;

                        return DefWindowProc(hWnd, message, wParam, lParam);
                }

                default:
                    return DefWindowProc(hWnd, message, wParam, lParam);
            }
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
                 WS_CAPTION | WS_SYSMENU | WS_CLIPSIBLINGS | WS_CLIPCHILDREN | WS_THICKFRAME,
                 posX,posY,width,height,_parent is null ? null : _parent.wWindow,null,runtime.hInstance,null);

        if(window is null)
            throw new WindowException(WindowError.noCreate,"Window is not create!");
    }  

	version(Posix) public void add(ref Atom atom) @trusted
	{
		XSetWMProtocols(runtime.display, xWindow, &atom, 1);
	}

    /++
        Initializes the window for the context.

        Params:
            posX = The x-axis position.
            posY = The y-axis position.
            visual = Information from context for create window.
    +/
    version(Posix) public void xWindowInit(int posX,int posY,XVisualInfo* visual = null,int depth = -1) @trusted
    {
        import tida.info;

        scope Visual* tryVisual = null; 
        int tryDepth = -1;
        x11.Xlib.Window rootWindow;

        if(visual is null)
        {
            tryVisual = XDefaultVisual(runtime.display,runtime.displayID);

            if(depth == -1) 
            {
                tryDepth = XDefaultDepth(runtime.display,runtime.displayID);
            }

            rootWindow = runtime.rootWindow;
        }else
        {
            tryVisual = visual.visual;
            tryDepth = visual.depth;
            rootWindow = runtime.rootWindowBy(visual.screen);
        }

        XSetWindowAttributes windowAttribs;
        windowAttribs.border_pixel = Color!ubyte(0,0,0).conv!uint;
        windowAttribs.background_pixel = _background.conv!uint;
        windowAttribs.override_redirect = True;
        windowAttribs.colormap = XCreateColormap(runtime.display, rootWindow, 
                                                 tryVisual, AllocNone);

        windowAttribs.event_mask = ExposureMask | ButtonPressMask | KeyPressMask |
                                   KeyReleaseMask | ButtonReleaseMask | EnterWindowMask |
                                   LeaveWindowMask | PointerMotionMask;

        window = XCreateWindow(runtime.display, _parent is null ? rootWindow : _parent.xWindow, posX, posY, 
                               width,
                               height,0,tryDepth,InputOutput,tryVisual,
                               CWBackPixel | CWColormap | CWBorderPixel | CWEventMask, &windowAttribs);

        xEventName(_title);
 
 		auto wmAtom = getAtom!"WM_DELETE_WINDOW";
        add(wmAtom);
    }

    /++
        Show window in workspace.
    +/
    version(Posix) public void xWindowShow() @trusted
    {
        XMapWindow(runtime.display, window);
        XClearWindow(runtime.display, window);
    }

    /// ditto
    version(Windows) public void wWindowShow() @trusted
    {
        ShowWindow(window, 1);
    }

    public void show() @safe
    {
        version(Posix) xWindowShow();
        version(Windows) wWindowShow();
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

        if(!glXIsDirect(runtime.display, ctx))
            return;
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
    in(posX > 0,"The position of the window cannot be negative!")
	in(posY > 0,"The position of the window cannot be negative!")
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
    in(newWidth > 0,"A window cannot be without content!")
    in(newHeight > 0,"A window cannot be without content!")
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
    version(Posix) public void xMaxWidth(int value) @trusted @live nothrow
    {
        long flags;

        scope XSizeHints* sh = XAllocSizeHints();

        scope(exit) XFree(sh);

        XGetWMNormalHints(runtime.display, xWindow, sh, &flags);

        sh.flags |= PMinSize | PMaxSize;
        sh.max_width = value;
        sh.max_height = _maxHeight;
        sh.min_width = _minWidth;
        sh.min_height = _minHeight;

        XSetWMNormalHints(runtime.display, xWindow, sh);

        _maxWidth = value;
    }

    ///
    version(Posix) public void xMaxHeight(int value) @trusted @live nothrow
    {
        long flags;

        scope XSizeHints* sh = XAllocSizeHints();

        scope(exit) XFree(sh);

        XGetWMNormalHints(runtime.display, xWindow, sh, &flags);

        sh.flags |= PMinSize | PMaxSize;
        sh.max_width = _maxWidth;
        sh.max_height = value;
        sh.min_width = _minWidth;
        sh.min_height = _minHeight;

        XSetWMNormalHints(runtime.display, xWindow, sh);

        _maxHeight = value;
    }

    ///
    version(Posix) public void xMinWidth(int value) @trusted @live nothrow
    in(value > 64,"You can't make the window so narrow!")
    body
    {
        long flags;

        scope XSizeHints* sh = XAllocSizeHints();

        scope(exit) XFree(sh);

        XGetWMNormalHints(runtime.display, xWindow, sh, &flags);

        sh.flags |= PMinSize | PMaxSize;
        sh.max_width = _maxWidth;
        sh.max_height = _maxHeight;
        sh.min_width = value;
        sh.min_height = _minHeight;

        _minWidth = value;
    }

    ///
    version(Posix) public void xMinHeight(int value) @trusted @live nothrow
    in(value > 64,"You can't make the window so narrow!")
    body
    {
        long flags;

        scope XSizeHints* sh = XAllocSizeHints();

        scope(exit) XFree(sh);

        XGetWMNormalHints(runtime.display, xWindow, sh, &flags);

        sh.flags |= PMinSize | PMaxSize;
        sh.max_width = _maxWidth;
        sh.max_height = _maxHeight;
        sh.min_width = _minWidth;
        sh.min_height = value;

        _minHeight = value;
    }

    ///
    version(Windows) public void wMaxWidth(int value) @trusted nothrow
    {
        _maxWidth = value;

        MINMAXINFO mmi;

        mmi.ptMaxTrackSize.x = value;
        mmi.ptMaxTrackSize.y = _maxHeight;
        mmi.ptMinTrackSize.x = _minWidth;
        mmi.ptMinTrackSize.y = _minHeight;

        auto info = WindowSizeInfo(minimumWidth,minimumHeight,
                                   maximumWidth,maximumHeight);

        SendMessage(wWindow, WM_USER, 0x01, cast(LPARAM) &info);
        SendMessage(wWindow, WM_GETMINMAXINFO, 0, cast(LPARAM) &mmi);
    }

    ///
    version(Windows) public void wMaxHeight(int value) @trusted nothrow
    {
        MINMAXINFO mmi;

        mmi.ptMaxTrackSize.x = _maxWidth;
        mmi.ptMaxTrackSize.y = value;
        mmi.ptMinTrackSize.x = _minWidth;
        mmi.ptMinTrackSize.y = _minHeight;

        auto info = WindowSizeInfo(minimumWidth,minimumHeight,
                                   maximumWidth,maximumHeight);

        SendMessage(wWindow, WM_USER, 0x01, cast(LPARAM) &info);
        SendMessage(wWindow, WM_GETMINMAXINFO, 0, cast(LPARAM) &mmi);
        
        _maxHeight = value;
    }

    ///
    version(Windows) public void wMinWidth(int value) @trusted nothrow
    in(value > 64,"You can't make the window so narrow!")
    body
    {
        MINMAXINFO mmi;

        mmi.ptMaxTrackSize.x = _maxWidth;
        mmi.ptMaxTrackSize.y = _maxHeight;
        mmi.ptMinTrackSize.x = value;
        mmi.ptMinTrackSize.y = _minHeight;

        auto info = WindowSizeInfo(minimumWidth,minimumHeight,
                                   maximumWidth,maximumHeight);

        SendMessage(wWindow, WM_USER, 0x01, cast(LPARAM) &info);
        SendMessage(wWindow, WM_GETMINMAXINFO, 0, cast(LPARAM) &mmi);
        
        _minWidth = value;
    }

    ///
    version(Windows) public void wMinHeight(int value) @trusted nothrow
    in(value > 64,"You can't make the window so narrow!")
    body
    {
        MINMAXINFO mmi;

        mmi.ptMaxTrackSize.x = _maxWidth;
        mmi.ptMaxTrackSize.y = _maxHeight;
        mmi.ptMinTrackSize.x = _minWidth;
        mmi.ptMinTrackSize.y = value;

        auto info = WindowSizeInfo(minimumWidth,minimumHeight,
                                   maximumWidth,maximumHeight);

        SendMessage(wWindow, WM_USER, 0x01, cast(LPARAM) &info);
        SendMessage(wWindow, WM_GETMINMAXINFO, 0, cast(LPARAM) &mmi);
        
        _minHeight = value;
    }

    ///
    public void minimumWidth(int value) @safe @property nothrow
    {
        version(Posix) xMinWidth(value);
        version(Windows) wMinWidth(value);
    }

    ///
    public int minimumWidth() @safe @property nothrow
    {
        return _minWidth;
    }

    ///
    public void minimumHeight(int value) @safe @property nothrow
    {
        version(Posix) xMinHeight(value);
        version(Windows) wMinHeight(value);
    }

    ///
    public int minimumHeight() @safe @property nothrow
    {
        return _minHeight;
    }

    ///
    public void maximumWidth(int value) @safe @property nothrow
    {
        version(Posix) xMaxWidth(value);
        version(Windows) wMaxWidth(value);
    }

    ///
    public int maximumWidth() @safe @property nothrow
    {
        return _maxWidth;
    }

    ///
    public void maximumHeight(int value) @safe @property nothrow
    {
        version(Posix) xMaxHeight(value);
        version(Windows) wMaxHeight(value);
    }

    ///
    public int maximumHeight() @safe @property nothrow
    {
        return _maxHeight;
    }

    ///
    version(Posix) public void xResizable(bool value) @trusted @live
    {
        long flags;

        scope XSizeHints* sh = XAllocSizeHints();

        scope(exit) XFree(sh);

        XGetWMNormalHints(runtime.display, xWindow, sh, &flags);
        
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

        XSetWMNormalHints(runtime.display, xWindow, sh);
    }

    /++
        Bug: The state does not change when you put false.
    +/
    version(Windows) public void wResizable(bool value) @trusted
    {
        auto lStyle = GetWindowLong(wWindow, GWL_STYLE);
        
        if(value) {
            lStyle |= WS_THICKFRAME;
        }else {
            lStyle &= ~(WS_THICKFRAME);
        }

        SetWindowLong(wWindow, GWL_STYLE, lStyle);

        _resizable = value;
    }

    /++
        Window resizing permission state.
    +/
    public void resizable(bool value) @safe @property
    {
        version(Posix) xResizable(value);
        version(Windows) wResizable(value);
    }

    /// ditto
    public bool resizable() @safe @property
    {
        return _resizable;
    }

    ///
    version(Posix) public void xIcon(Image image) @trusted
    {
        ulong[] pixels = [cast(ulong) image.width,cast(ulong) image.height] ~ image.colors!ulong(PixelFormat.ARGB);

        auto event = WMEvent();
        event.first = XInternAtom(runtime.display,"_NET_WM_ICON", False);
        event.second = XInternAtom(runtime.display,"CARDINAL", False);
        event.data = cast(ubyte*) pixels;
        event.length = pixels.length;
        event.mode = PropModeReplace;
        event.format = 32;
        event.window = xWindow;

        sendEvent(event);
    }

    version(Posix) public void xEventName(string caption) @trusted nothrow
    {
        XStoreName(runtime.display, window, caption.toUTFz!(char*));
        XSetIconName(runtime.display, window, caption.toUTFz!(char*));
    }

    ///
    version(Windows) public void wIcon(Image image) @trusted
    {
        import imageformats, std.file : remove;

        HICON icon;

        ubyte[] pixels = image.bytes!ubyte(PixelFormat.BGRA);

        ICONINFO icInfo;

        auto bitmap = CreateBitmap(image.width,image.height,1,32,cast(PCVOID) pixels);

        icInfo.hbmColor = bitmap;
        icInfo.hbmMask = CreateBitmap(width,height,1,1,null);

        icon = CreateIconIndirect(&icInfo);

        SendMessage(wWindow, WM_SETICON, ICON_SMALL, cast(LPARAM) icon);
        SendMessage(wWindow, WM_SETICON, ICON_BIG, cast(LPARAM) icon);
    }

    ///
    public void icon(Image image) @safe @property
    {
        version(Posix) xIcon(image);
        version(Windows) wIcon(image);
    }

    ///
    public void resizeEvent(uint rWidth,uint rHeight) @safe 
    {
        _width = rWidth;
        _height = rHeight;
    }

    ///
    public void resizeEvent(T)(T[2] size) @safe
    {
        resizeEvent(size[0],size[1]);
    }

    ///
    version(Windows) public void wFullscreen(bool value) @trusted
    {
        import tida.info;

        if(value) 
        {
            GetWindowPlacement(wWindow, &wpc);
            if(style == 0)
                style = GetWindowLong(wWindow, GWL_STYLE);
            if(oldStyle == 0)
                oldStyle = GetWindowLong(wWindow,GWL_EXSTYLE);

            auto NewHWNDStyle = style;
            NewHWNDStyle &= ~WS_BORDER;
            NewHWNDStyle &= ~WS_DLGFRAME;
            NewHWNDStyle &= ~WS_THICKFRAME;

            auto NewHWNDStyleEx = oldStyle;
            NewHWNDStyleEx &= ~WS_EX_WINDOWEDGE;

            SetWindowLong(wWindow, GWL_STYLE, NewHWNDStyle | WS_POPUP );
            SetWindowLong(wWindow, GWL_EXSTYLE, NewHWNDStyleEx | WS_EX_TOPMOST);
            ShowWindow(wWindow, SHOW_FULLSCREEN);
        } else 
        {
            SetWindowLong(wWindow, GWL_STYLE, style);
            SetWindowLong(wWindow, GWL_EXSTYLE, oldStyle);
            ShowWindow(wWindow, SW_SHOWNORMAL);
            SetWindowPlacement(wWindow, &wpc);

            style = 0;
            oldStyle = 0;
        }

        _fullscreen = value;
    }

    ///
    version(Posix) public void xFullscreen(bool value) @trusted
    {   
        import tida.info;

        XEvent event;
        
        Atom wmState = XInternAtom(runtime.display,"_NET_WM_STATE",False);
        Atom wmFullscreen = XInternAtom(runtime.display,"_NET_WM_STATE_FULLSCREEN",False);

        event.xany.type = ClientMessage;
        event.xclient.message_type = wmState;
        event.xclient.format = 32;
        event.xclient.window = xWindow;
        event.xclient.data.l[1] = wmFullscreen;
        event.xclient.data.l[3] = 0;

        event.xclient.data.l[0] = fullscreen ? _NET_WM_STATE_ADD : _NET_WM_STATE_REMOVE;

        XSendEvent(runtime.display,RootWindow(runtime.display,runtime.displayID),0,
                SubstructureNotifyMask | SubstructureRedirectMask, &event);

        _fullscreen = value;
    }

    /++
        Set to fullscreen mode
    +/
    public void fullscreen(bool value) @safe @property
    {
        version(Posix) xFullscreen(value);
        version(Windows) wFullscreen(value);
    }

    /// ditto
    public bool fullscreen() @safe @property
    {
        return _fullscreen;
    }

    /// ditto
    public bool fullscreen() @safe @property const
    {
        return _fullscreen;
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
        version(Posix) xEventName(newTitle);
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

    ///
    public void destroyWindow() @trusted
    {
        version(Posix) {
            XDestroyWindow(runtime.display, window);
        }

        version(Windows) {
            DestroyWindow(wWindow);
        }
    }

    ~this() @trusted
    {
        destroyWindow();
    }
}