/++
Implementation of cross-platform creation and management of a window.

Also, at the same time, it is possible to create a graphical context for the 
window to be able to use hardware acceleration using a common open API - OpenGL.

Creating_a_window:
First of all, creating a window begins with allocating memory and setting 
the input parameters:
---
Window window = new Window(640, 480, "Example title");
---

Only input parameters are set in the constructor, this does not mean that the 
window is ready for use. Here only the initial width, height and title of the 
window are set. Other properties do not affect creation, everything is done 
after the window is created.

The window is created by the $(LREF windowInitialize) function:
---
windowInitialize(window, 100, 100);
...
window.windowInitialize(100, 100); // UFCS
---

Now, you can interact with the window or create a graphics context to access 
hardware acceleration. To do this, again, allocate the mod memory for the 
context collector and create a structure with a description of the 
context properties:
---
Context context = new Context();

// We just set the parameters by color. Each color will weigh 8 bits.
GraphicsAttributes attributes = AttribBySizeOfTheColor!8;
context.setAttributes(attributes);
context.create(window);

// We set the current context to the window.
window.context = context;
---
Now you will have access to hardware acceleration according to the attributes 
you specified, what you can do next is load open graphics libraries and start 
drawing primitives. To display primitives on the screen, 
use the $(HREF window/IWindow.swapBuffers.html, IWindow.swapBuffers) function.

OS_specific_actions:
It may be that the built-in tools are not enough and you need, say, to change 
some properties that other platforms cannot do. For this, each object has an 
open $(B `handle`) field. Getting it is easy, however, be careful with what you do 
with it. You can do such things that the interaction interface after your 
manipulations will not be able to control it. To do this, it is enough not to 
change the properties that can be controlled by the interaction interface.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>
    PHOBREF = <a href="https://dlang.org/phobos/$1.html#$2">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.window;

enum ConfFindError = 
"The required configuration for the specified graphic attributes was not found!";

enum WithoutContext = 0; /// Without creating a graphical context.
enum WithContext = 1; /// With the creation of a graphical context.

/++
Graphics attributes for creating a special graphics pipeline 
(default parameters are indicated in the structure).
+/
struct GraphicsAttributes
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

/++
Automatic determination of the structure of graphic attributes by the total 
size of the color unit.

Params:
    colorSize = Color unit size.
+/
template AttribBySizeOfTheColor(int colorSize)
{
    enum AttribBySizeOfTheColor = GraphicsAttributes(   colorSize,
                                                        colorSize,
                                                        colorSize,
                                                        colorSize);
}

/++
Graphics context creation interface for hardware graphics acceleration.

With this technology, the context can be easily created with the given
attributes, and it is obligatory $(U after) the window is created.

Example:
---
// Window creation code . . .
Context contex = new Context();
context.setAttribute(attributes...);
context.create(window);
// The graphics context has been created!
---
+/
interface IContext
{
@safe:
    /++
    Sets the input attributes for creating the graphics context.
    At the same time, he must simultaneously give these attributes
    unsparingly to the very object of the pixel description,
    if such is possible. As a rule, this method is followed by the creation
    of the context, but the function itself should not do this.

    Params:
        attributes = graphic context description attributes.

    Throws:
    $(PHOBREF object,Exception) if the graphics attributes did not fit the creation
    of the context (see what parameters you could set, maybe inconsistent with
    each other).
    +/
    void setAttributes(GraphicsAttributes attributes);

    /++
    Creates directly, a graphics context object for a specific platform,
    based on the previously specified graphics context attributes.

    Params:
        window = Pointer to the window to create the graphics context.

    Throws:
    $(PHOBREF object,Exception) if the creation of the graphics context was
    not successful. The attributes were probably not initialized.
    +/
    void create(IWindow window);

    /++
    Destroys the context.
    +/
    void destroy();
}

/++
Window interaction interface. It does not provide its creation, it is created by
a separate function within the interface implementation, in particular 
the `initialize` function.
+/
interface IWindow
{
    import tida.image;

@safe:
    /// The position of the window in the plane of the desktop.
    @property int x();

    /// The position of the window in the plane of the desktop.
    @property int y();

    /// Window width
    @property uint width();

    /// Window height
    @property uint height();

    /// Window mode, namely whether windowed or full screen
    @property void fullscreen(bool value);

    /// Window mode, namely whether windowed or full screen
    @property bool fullscreen();

    /// Whether the window can be resized by the user.
    @property void resizable(bool value);

    /// Whether the window can be resized by the user.
    @property bool resizable();

    /// Frames around the window.
    @property void border(bool value);

    /// Frames around the window.
    @property bool border();

    /// Window title.
    @property void title(string value);

    /// Window title.
    @property string title();

    /// Whether the window is always on top of the others.
    @property void alwaysOnTop(bool value);

    /// Whether the window is always on top of the others.
    @property bool alwaysOnTop();

    /// Dynamic window icon.
    @property void icon(Image iconimage);

    /// Grahphics context
    @property void context(IContext ctx);

    /// Grahphics context
    @property IContext context();

    /++
    Window resizing function.

    Params:
        w = Window width.
        h = Window height.
    +/
    void resize(uint w, uint h);

    /++
    Changes the position of the window in the plane of the desktop.

    Params:
        xposition = Position x-axis.
        yposition = Position y-axis.
    +/
    void move(int xposition, int yposition);

    /++
    Shows a window in the plane of the desktop.
    +/
    void show();

    /++
    Hide a window in the plane of the desktop. 
    (Can be tracked in the task manager.)
    +/
    void hide();

    /++
    Swap two buffers.
    +/
    void swapBuffers();

    /++
    Destroys the window and its associated data (not the structure itself, all values are reset to zero).
    +/
    void destroy();
}

version (Posix)
class Context : IContext
{
    import tida.runtime;
    import x11.X, x11.Xlib, x11.Xutil;
    import dglx.glx;

private:
    GLXContext _context;
    XVisualInfo* visual;
    GLXFBConfig bestFbcs;

public @trusted override:
    void setAttributes(GraphicsAttributes attributes)
    {
        import std.exception : enforce;
        import std.conv : to;

        int[] glxAttributes = 
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
        scope fbc = glXChooseFBConfig(  runtime.display, runtime.displayID, 
                                        glxAttributes.ptr, &fbcount);
        scope(success) XFree(fbc);
        enforce!Exception(fbc, ConfFindError);

        int bestFbc = -1, bestNum = -1;
        foreach (int i; 0 .. fbcount)
        {
            int sampBuff, samples;
            glXGetFBConfigAttrib(   runtime.display, fbc[i], 
                                    GLX_SAMPLE_BUFFERS, &sampBuff);
            glXGetFBConfigAttrib(   runtime.display, fbc[i], 
                                    GLX_SAMPLES, &samples);

            if (bestFbc < 0 || (sampBuff && samples > bestNum)) 
            {
                bestFbc = i;
                bestNum = samples;
            }
        }

        this.bestFbcs = fbc[bestFbc];
        enforce!Exception(bestFbcs, ConfFindError);

        this.visual = glXGetVisualFromFBConfig(runtime.display, bestFbcs);
        enforce!Exception(visual, ConfFindError);
    }

    void create(IWindow window)
    {
        _context = glXCreateNewContext( runtime.display, this.bestFbcs, 
                                        GLX_RGBA_TYPE, null, true);
    }

    void destroy()
    {
        glXDestroyContext(runtime.display, _context);
        if(visual) XFree(visual);
    }
}

version (Posix)
class Window : IWindow
{
    import tida.runtime, tida.image;
    import x11.X, x11.Xlib, x11.Xutil;
    import dglx.glx;
    import std.utf : toUTFz;

private:
    string _title;
    bool _fullscreen;
    bool _border;
    bool _resizable;
    bool _alwaysTop;
    IContext _context;
    uint _widthInit;
    uint _heightInit;

public:
    x11.X.Window handle;
    Visual* visual;
    int depth;

@trusted:
    this(uint w, uint h, string caption)
    {
        this._widthInit = w;
        this._heightInit = h;
    }

    void createFromXVisual(XVisualInfo* vinfo, int posX = 100, int posY = 100)
    {
        visual = vinfo.visual;
        depth = vinfo.depth;

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

        this.handle = XCreateWindow (runtime.display, rootWindow, posX, posY, _widthInit, _heightInit, 0, depth,
                                InputOutput, visual, CWBackPixel | CWColormap | CWBorderPixel | CWEventMask, 
                                &windowAttribs);

        title = _title;

        Atom wmAtom = XInternAtom(runtime.display, "WM_DELETE_WINDOW", 0);
        XSetWMProtocols(runtime.display, this.handle, &wmAtom, 1);
    }

    int getDepth()
    {
        return depth;
    }

    Visual* getVisual()
    {
        return visual;
    }

    ~this()
    {
        this.destroy();
    }
override:
    @property int x()
    {
        XWindowAttributes winAttrib;
        XGetWindowAttributes(runtime.display, this.handle, &winAttrib);

        return winAttrib.x;
    }

    @property int y()
    {
        XWindowAttributes winAttrib;
        XGetWindowAttributes(runtime.display, this.handle, &winAttrib);

        return winAttrib.y;
    }

    @property uint width()
    {
        XWindowAttributes winAttrib;
        XGetWindowAttributes(runtime.display, this.handle, &winAttrib);

        return winAttrib.width;
    }

    @property uint height()
    {
        XWindowAttributes winAttrib;
        XGetWindowAttributes(runtime.display, this.handle, &winAttrib);

        return winAttrib.height;
    }

    @property void fullscreen(bool value)
    {
        XEvent event;
        
        const wmState = XInternAtom(runtime.display, 
                                    "_NET_WM_STATE", 0);
        const wmFullscreen = XInternAtom(   runtime.display, 
                                            "_NET_WM_STATE_FULLSCREEN", 0);

        event.xany.type = ClientMessage;
        event.xclient.message_type = wmState;
        event.xclient.format = 32;
        event.xclient.window = this.handle;
        event.xclient.data.l[1] = wmFullscreen;
        event.xclient.data.l[3] = 0;

        event.xclient.data.l[0] = value;

        XSendEvent(runtime.display,runtime.rootWindow,0,
                SubstructureNotifyMask | SubstructureRedirectMask, &event);

        this._fullscreen = value;
    }

    @property bool fullscreen()
    {
        return this._fullscreen;
    }

    @property void resizable(bool value)
    {
        long flags;

        scope XSizeHints* sh = XAllocSizeHints();
        scope(exit) XFree(sh);

        XGetWMNormalHints(runtime.display, this.handle, sh, &flags);
        
        if(!value)
        {
            sh.flags |= PMinSize | PMaxSize;
            sh.min_width = this.width;
            sh.max_width = this.width;
            sh.min_height = this.height;
            sh.max_height = this.height;
        }else
        {
            sh.flags &= ~(PMinSize | PMaxSize);
        }

        this._resizable = value;
        XSetWMNormalHints(runtime.display, this.handle, sh);
    }

    @property bool resizable()
    {
        return this._resizable;
    }

    @property void border(bool value)
    {
        import std.conv : to;

        struct MWMHints {
            ulong flags;
            ulong functions;
            ulong decorations;
            long inputMode;
            ulong status;
        }

        const hint = MWMHints(1 << 1, 0, value.to!ulong, 0, 0);
        const wmHINTS = XInternAtom(runtime.display, "_MOTIF_WM_HINTS", 0);

        XChangeProperty(runtime.display, this.handle, wmHINTS, wmHINTS, 32,
            PropModeReplace, cast(ubyte*) &hint, MWMHints.sizeof / long.sizeof);

        this._border = value;
    }

    @property bool border()
    {
        return this._border;
    }

    @property void title(string value)
    {
        XStoreName(runtime.display, this.handle, value.toUTFz!(char*));
        XSetIconName(runtime.display, this.handle, value.toUTFz!(char*));

        this._title = value;
    }

    @property string title()
    {
        return this._title;
    }

    @property void alwaysOnTop(bool value)
    {
        const wmState = XInternAtom(runtime.display, "_NET_WM_STATE", 0);
        const wmAbove = XInternAtom(runtime.display, "_NET_WM_STATE_ABOVE", 0);

        XEvent event;
        event.xclient.type = ClientMessage;
        event.xclient.serial = 0;
        event.xclient.send_event = true;
        event.xclient.display = runtime.display;
        event.xclient.window = this.handle;
        event.xclient.message_type = wmState;
        event.xclient.format = 32;
        event.xclient.data.l[0] = value;
        event.xclient.data.l[1] = wmAbove;
        event.xclient.data.l[2 .. 5] = 0;

        XSendEvent( runtime.display, runtime.rootWindow, false, 
                    SubstructureRedirectMask | SubstructureNotifyMask, &event);
        XFlush(runtime.display);

        this._alwaysTop = value;
    }

    @property bool alwaysOnTop()
    {
        return this._alwaysTop;
    }

    void icon(Image iconimage)
    {
        import tida.color;

        ulong[] pixels = [  cast(ulong) iconimage.width,
                            cast(ulong) iconimage.height];

        foreach(pixel; iconimage.pixels)
            pixels ~= pixel.to!(ulong, PixelFormat.ARGB);

        const first = XInternAtom(runtime.display, "_NET_WM_ICON", 0);
        const second = XInternAtom(runtime.display, "CARDINAL", 0);

        XChangeProperty(runtime.display, this.handle, first, second, 32,
                        PropModeReplace, cast(ubyte*) pixels, 
                        cast(int) pixels.length);
    }

    @property void context(IContext ctx)
    {
        this._context = ctx;
        glXMakeCurrent(runtime.display, this.handle, (cast(Context) ctx)._context);
    }

    @property IContext context()
    {
        return this._context;
    }

    void resize(uint w, uint h)
    {
        XResizeWindow(runtime.display, this.handle, w, h);
    }

    void move(int xposition, int yposition)
    {
        XMoveWindow(runtime.display, this.handle, xposition, yposition);
    }

    void show()
    {
        XMapWindow(runtime.display, this.handle);
        XClearWindow(runtime.display, this.handle);
    }

    void hide()
    {
         XUnmapWindow(runtime.display, this.handle);
    }

    void swapBuffers()
    {
        import dglx.glx : glXSwapBuffers; 

        glXSwapBuffers(runtime.display, this.handle);
    }

    void destroy()
    {
        XDestroyWindow(runtime.display, this.handle);
        this.handle = 0;
    }
}

version(Windows)
class Context : IContext
{
    import tida.runtime;
    import core.sys.windows.windows;
    import std.exception : enforce;

private:
    GraphicsAttributes attributes;
    HDC deviceHandle;
    
    PIXELFORMATDESCRIPTOR pfd;

    alias FwglChoosePixelFormatARB = extern(C) bool function( HDC hdc,
                                                    int *piAttribIList,
                                                    float *pfAttribFList,
                                                    uint nMaxFormats,
                                                    int *piFormats,
                                                    uint *nNumFormats);

    alias FwglGetExtensionsStringARB = extern(C) char* function(HDC hdc);

    alias FwglCreateContextAttribsARB = extern(C) HGLRC function(HDC, HGLRC, int*);

    FwglChoosePixelFormatARB wglChoosePixelFormatARB;
    FwglGetExtensionsStringARB wglGetExtensionsStringARB;
    FwglCreateContextAttribsARB wglCreateContextAttribsARB;

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

public:
    HGLRC _context;

@trusted:
    ~this()
    {
        destroy();
    }
override:
    void setAttributes(GraphicsAttributes attributes)
    {
        this.attributes = attributes;

        const flags = 
            (attributes.doubleBuffer ? 
            (PFD_DOUBLEBUFFER | PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL) : 
            (PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL));

        pfd.nSize = PIXELFORMATDESCRIPTOR.sizeof;
        pfd.nVersion = 1;
        pfd.dwFlags = flags;
        pfd.iPixelType = PFD_TYPE_RGBA;
        pfd.cRedBits = cast(ubyte) this.attributes.redSize;
        pfd.cGreenBits = cast(ubyte) this.attributes.greenSize;
        pfd.cBlueBits = cast(ubyte) this.attributes.blueSize;
        pfd.cAlphaBits = cast(ubyte) this.attributes.alphaSize;
        pfd.cDepthBits = cast(ubyte) this.attributes.depthSize;
        pfd.cStencilBits = cast(ubyte) this.attributes.stencilSize;
        pfd.iLayerType = PFD_MAIN_PLANE;
    }

    void create(IWindow window)
    {
        scope handle = (cast(Window) window).handle;
        deviceHandle = GetDC(handle);
        auto chsPixel = ChoosePixelFormat(deviceHandle, &pfd);
        enforce!Exception(chsPixel != 0, ConfFindError);

        SetPixelFormat(deviceHandle, chsPixel, &pfd);

        scope ctx = wglCreateContext(deviceHandle);
        wglMakeCurrent(deviceHandle, ctx);

        void* data = wglGetProcAddress("wglGetExtensionsStringARB");
        enforce!Exception(data,"wglGetExtensionsStringARB pointer is null");
        wglGetExtensionsStringARB = cast(FwglGetExtensionsStringARB) data;
        data = null;

        data = wglGetProcAddress("wglChoosePixelFormatARB");
        enforce!Exception(data,"wglChoosePixelFormatARB pointer is null");
        wglChoosePixelFormatARB = cast(FwglChoosePixelFormatARB) data;
        data = null;

        data = wglGetProcAddress("wglCreateContextAttribsARB");
        enforce!Exception(data,"wglCreateContextAttribsARB pointer is null");
        wglCreateContextAttribsARB = cast(FwglCreateContextAttribsARB) data;
        data = null;

        int[] iattrib =  
        [
            WGL_SUPPORT_OPENGL_ARB, true,
            WGL_DRAW_TO_WINDOW_ARB, true,
            WGL_DOUBLE_BUFFER_ARB, attributes.doubleBuffer,
            WGL_RED_BITS_ARB, attributes.redSize,
            WGL_GREEN_BITS_ARB, attributes.greenSize,
            WGL_BLUE_BITS_ARB, attributes.blueSize,
            WGL_ALPHA_BITS_ARB, attributes.alphaSize,
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
        enforce(nPixelFormat, "nPixelFormats error!");

        DescribePixelFormat(deviceHandle, nPixelFormat, pfd.sizeof, &pfd);
        SetPixelFormat(deviceHandle, nPixelFormat, &pfd);

        int[] attrib =  
        [
            WGL_CONTEXT_MAJOR_VERSION_ARB, 3,
            WGL_CONTEXT_MINOR_VERSION_ARB, 0,
            WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB,
            WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
            0
        ];
        this._context = wglCreateContextAttribsARB( deviceHandle, 
                                                    null, 
                                                    attrib.ptr);
        enforce(ctx, "ContextARB is not a create!");

        wglMakeCurrent(null, null);
        wglDeleteContext(ctx);
    }

    void destroy()
    {
        wglDeleteContext(_context);
    }
}

version(Windows)
class Window : IWindow
{
    import tida.runtime;
    import std.utf : toUTFz;
    import std.exception : enforce;
    import core.sys.windows.windows;

    pragma(lib, "opengl32.lib");

private:
    uint _widthInit;
    uint _heightInit;

    string _title;

    bool _fullscreen;
    bool _border;
    bool _resizable;
    bool _alwaysTop;

    IContext _context;

    LONG style;
    LONG oldStyle;
    WINDOWPLACEMENT wpc;
    HDC dc;

public:
    HWND handle;

    this(uint w, uint h, string caption)
    {
        this._widthInit = w;
        this._heightInit = h;
        _title = caption;
    }

@trusted:
    void create(int posX, int posY)
    {
        extern(Windows) auto _wndProc(HWND hWnd, uint message, WPARAM wParam, LPARAM lParam) nothrow
        {
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

        this.handle = CreateWindow( _title.toUTFz!(wchar*), 
                                    _title.toUTFz!(wchar*),
                                    WS_CAPTION | WS_SYSMENU | WS_CLIPSIBLINGS | 
                                    WS_CLIPCHILDREN | WS_THICKFRAME,
                                    posX, posY, this._widthInit, 
                                    this._heightInit, null, null, 
                                    runtime.instance, null);
                 
        enforce!Exception(this.handle, "Window is not create!");

        dc = GetDC(this.handle);
    }

override:
    @property int x()
    {
        RECT rect;
        GetWindowRect(this.handle, &rect);

        return rect.left;
    }

    @property int y()
    {
        RECT rect;
        GetWindowRect(this.handle, &rect);

        return rect.top;
    }

    @property uint width()
    {
        RECT rect;
        GetWindowRect(this.handle, &rect);

        return rect.right;
    }

    @property uint height()
    {
        RECT rect;
        GetWindowRect(this.handle, &rect);

        return rect.bottom;
    }

    @property void fullscreen(bool value)
    {
        if (value) 
        {
            GetWindowPlacement(this.handle, &wpc);

            if(style == 0)
                style = GetWindowLong(this.handle, GWL_STYLE);
            if(oldStyle == 0)
                oldStyle = GetWindowLong(this.handle, GWL_EXSTYLE);

            auto NewHWNDStyle = style;
            NewHWNDStyle &= ~WS_BORDER;
            NewHWNDStyle &= ~WS_DLGFRAME;
            NewHWNDStyle &= ~WS_THICKFRAME;

            auto NewHWNDStyleEx = oldStyle;
            NewHWNDStyleEx &= ~WS_EX_WINDOWEDGE;

            SetWindowLong(  this.handle, GWL_STYLE, 
                            NewHWNDStyle | WS_POPUP );
            SetWindowLong(  this.handle, GWL_EXSTYLE, 
                            NewHWNDStyleEx | WS_EX_TOPMOST);

            ShowWindow(this.handle, SHOW_FULLSCREEN);
        } else 
        {
            SetWindowLong(this.handle, GWL_STYLE, style);
            SetWindowLong(this.handle, GWL_EXSTYLE, oldStyle);
            ShowWindow(this.handle, SW_SHOWNORMAL);
            SetWindowPlacement(this.handle, &wpc);

            style = 0;
            oldStyle = 0;
        }

        this._fullscreen = value;
    }

    @property bool fullscreen()
    {
        return this._fullscreen;
    }

    @property void resizable(bool value)
    {
        auto lStyle = GetWindowLong(this.handle, GWL_STYLE);
        
        if (value) 
            lStyle |= WS_THICKFRAME;
        else 
            lStyle &= ~(WS_THICKFRAME);

        SetWindowLong(this.handle, GWL_STYLE, lStyle);

        this._resizable = value;
    }

    @property bool resizable()
    {
        return this._resizable;
    }

    @property void border(bool value)
    {
        auto style = GetWindowLong(this.handle, GWL_STYLE);

        if (!value)
            style &=    ~(  
                            WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | 
                            WS_MAXIMIZEBOX | WS_SYSMENU
                        );
        else
            style |=    (
                            WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | 
                            WS_MAXIMIZEBOX | WS_SYSMENU
                        );

        SetWindowLong(this.handle, GWL_STYLE, style);

        SetWindowPos(   this.handle, null, 0, 0, 0, 0,
                        SWP_FRAMECHANGED | SWP_NOMOVE |
                        SWP_NOSIZE | SWP_NOZORDER |
                        SWP_NOOWNERZORDER);

        this._border = value;
    }

    @property bool border()
    {
        return this._border;
    }

    @property void title(string value)
    {
        SetWindowTextA(this.handle, title.toUTFz!(char*));

        this._title = value;
    }

    @property string title()
    {
        return this._title;
    }

    @property void alwaysOnTop(bool value)
    {
        SetWindowPos(   this.handle, 
                        value ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0, 
                        SWP_NOMOVE | SWP_NOSIZE);

        this._alwaysTop = value;
    }

    @property bool alwaysOnTop()
    {
        return this._alwaysTop;
    }

    @property void icon(Image iconimage)
    {
        HICON icon;

        ubyte[] pixels = iconimage.bytes!(PixelFormat.BGRA);

        ICONINFO icInfo;

        auto bitmap = CreateBitmap( iconimage.width,
                                    iconimage.height,
                                    1,32,cast(PCVOID) pixels);

        icInfo.hbmColor = bitmap;
        icInfo.hbmMask = CreateBitmap(iconimage.width,iconimage.height,1,1,null);

        icon = CreateIconIndirect(&icInfo);

        SendMessage(window, WM_SETICON, ICON_SMALL, cast(LPARAM) icon);
        SendMessage(window, WM_SETICON, ICON_BIG, cast(LPARAM) icon);
    }

    @property void context(IContext ctx)
    {
        wglMakeCurrent(GetDC(this.handle),(cast(Context) ctx)._context);

        this._context = ctx;
    }

    @property IContext context()
    {
        return this._context;
    }

    void resize(uint w, uint h)
    {
        SetWindowPos(this.handle, null, x, y ,w, h, 0);
    }

    void move(int xposition, int yposition)
    {
        SetWindowPos(this.handle, null, xposition, yposition, width, height, 0);
    }

    void show()
    {
        ShowWindow(this.handle, 1);
    }

    void hide()
    {
        ShowWindow(this.handle, SW_HIDE);
    }

    void swapBuffers()
    {
        SwapBuffers(dc);
    }

    void destroy()
    {
        DestroyWindow(this.handle);
        this.handle = null;
    }
}

/++
Creating a window in the window manager. When setting a parameter in a template, 
it can create both its regular version and with hardware graphics acceleration.

Params:
    type =  Method of creation. 
            `WithoutContext` -  Only the window is created. 
                                The context is created after.
            `WithContext` - Creates both a window and a graphics context for 
                            using hardware graphics acceleration.
    window = Window pointer.
    posX = Position in the plane of the desktop along the x-axis.
    posY = Position in the plane of the desktop along the y-axis.

Throws:
`Exception` If a window has not been created in the process 
(and this also applies to the creation of a graphical context).

Examples:
---
windowInitialize!WithoutContext(window, 100, 100); /// Without context
...
windowInitialize!WithContext(window, 100, 100); /// With context
---
+/
void windowInitialize(int type = WithoutContext)(   Window window, 
                                                    int posX, 
                                                    int posY) @trusted
{
    version(Posix) {
        import tida.runtime;
        import x11.X, x11.Xlib, x11.Xutil;

        scope XVisualInfo* vinfo = new XVisualInfo();
        vinfo.visual = XDefaultVisual(runtime.display, runtime.displayID);
        vinfo.depth = XDefaultDepth(runtime.display, runtime.displayID);
        
        window.createFromXVisual(vinfo);

        destroy(vinfo);
    }
    else
        window.create(posX, posY);
    
    static if(type == WithContext)
    {
        Context context = new Context();
        context.setAttributes(AttribBySizeOfTheColor!8);
        context.create(window);

        window.context = context;
    }

    window.show();
}
