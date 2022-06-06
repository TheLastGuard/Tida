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
    Destroys the window and its associated data (not the structure itself, all values are reset to zero).
    +/
    void destroy();
}

version (Posix)
{
    version(UseXCB)
    {
        class Window : IWindow
        {
            import tida.runtime, tida.image;
            import xcb.xcb;
            import core.stdc.stdlib;
            import std.utf : toUTFz;

        private:
            string _title;
            bool _fullscreen;
            bool _border;
            bool _resizable;
            bool _alwaysTop;
            //IContext _context;
            uint _widthInit;
            uint _heightInit;

        public:
            xcb_window_t handle;
            xcb_void_cookie_t cookie;

            this(uint w, uint h, string caption) @safe
            {
                this._widthInit = w;
                this._heightInit = h;
                this._title = caption;
            }

            void createFromVisual(xcb_visualid_t visual, uint posX, uint posY) @trusted
            {
                immutable(uint) mask = XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK;
                immutable(uint[]) values = [
                    runtime.screen.white_pixel,
                    XCB_EVENT_MASK_EXPOSURE |
                    XCB_EVENT_MASK_KEY_PRESS |
                    XCB_EVENT_MASK_KEY_RELEASE |
                    XCB_EVENT_MASK_BUTTON_PRESS |
                    XCB_EVENT_MASK_BUTTON_RELEASE |
                    XCB_EVENT_MASK_POINTER_MOTION |
                    XCB_EVENT_MASK_FOCUS_CHANGE |
                    XCB_EVENT_MASK_STRUCTURE_NOTIFY
                ];

                handle = xcb_generate_id(runtime.connection);
                cookie = xcb_create_window(
                    runtime.connection,
                    XCB_COPY_FROM_PARENT,
                    handle,
                    runtime.screen.root,
                    cast(short) posX, cast(short) posY,
                    cast(short) _widthInit, cast(short) _heightInit,
                    1,
                    XCB_WINDOW_CLASS_INPUT_OUTPUT,
                    visual,
                    mask,
                    values.ptr
                );

                xcb_map_window(runtime.connection, handle);
                title = _title;
                xcb_flush(runtime.connection);

                auto wmProtocols = getAtom("WM_PROTOCOLS");
                auto wmDelete = getAtom("WM_DELETE_WINDOW");
                xcb_change_property(runtime.connection, XCB_PROP_MODE_REPLACE, handle, wmProtocols, 4, 32, 1, &wmDelete);
                xcb_flush(runtime.connection);
            }

            auto getAtom(string name) @trusted
            {
                import std.string : toStringz;

                auto c = xcb_intern_atom(runtime.connection, 0, cast(ushort) name.length, name.toStringz);
                xcb_flush(runtime.connection);
                auto atomReply = xcb_intern_atom_reply(runtime.connection, c, null);

                auto atom = atomReply.atom;
                free(atomReply);

                return atom;
            }

            /// The position of the window in the plane of the desktop.
            @property int x() @trusted
            {
                auto c = xcb_get_geometry(runtime.connection, handle);
                xcb_flush(runtime.connection);
                auto reply = xcb_get_geometry_reply(runtime.connection, c, null);

                uint xPos = reply.x;
                free(reply);

                return xPos;
            }

            /// The position of the window in the plane of the desktop.
            @property int y() @trusted
            {
                auto c = xcb_get_geometry(runtime.connection, handle);
                xcb_flush(runtime.connection);
                auto reply = xcb_get_geometry_reply(runtime.connection, c, null);

                uint yPos = reply.y;
                free(reply);

                return yPos;
            }

            /// Window width
            @property uint width() @trusted
            {
                auto c = xcb_get_geometry(runtime.connection, handle);
                xcb_flush(runtime.connection);
                auto reply = xcb_get_geometry_reply(runtime.connection, c, null);

                uint w = reply.width;
                free(reply);

                return w;
            }

            /// Window height
            @property uint height() @trusted
            {
                auto c = xcb_get_geometry(runtime.connection, handle);
                xcb_flush(runtime.connection);
                auto reply = xcb_get_geometry_reply(runtime.connection, c, null);

                uint h = reply.height;
                free(reply);

                return h;
            }

            /// Window mode, namely whether windowed or full screen
            @property void fullscreen(bool value) @trusted
            {
                auto state = getAtom("_NET_WM_STATE");
                auto fullscr = getAtom("_NET_WM_STATE_FULLSCREEN");

                xcb_client_message_event_t event;
                event.response_type = XCB_CLIENT_MESSAGE;
                event.type = state;
                event.format = 32;
                event.window = handle;
                event.data.data32[0] = value;
                event.data.data32[1] = fullscr;
                event.data.data32[2] = XCB_ATOM_NONE;

                xcb_send_event(
                    runtime.connection,
                    0,
                    runtime.screen.root,
                    XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT
                    | XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY,
                    cast(const char*) &event
                );

                xcb_flush(runtime.connection);

                _fullscreen = value;
            }

            /// Window mode, namely whether windowed or full screen
            @property bool fullscreen()
            {
                return _fullscreen;
            }

            /// Whether the window can be resized by the user.
            @property void resizable(bool value) @trusted
            {
                import xcb.icccm;

                xcb_icccm_wm_hints_t wmHints;

                auto c = xcb_icccm_get_wm_hints(runtime.connection, handle);
                xcb_flush(runtime.connection);
                xcb_icccm_get_wm_hints_reply(
                    runtime.connection,
                    c,
                    &wmHints,
                    null
                );

                if (!value)
                {
                    xcb_size_hints_t hints;

                    auto gc = xcb_get_geometry(runtime.connection, handle);
                    xcb_flush(runtime.connection);
                    auto reply = xcb_get_geometry_reply(runtime.connection, gc, null);

                    uint w = reply.width;
                    uint h = reply.height;

                    free(reply);

                    hints.flags = XCB_ICCCM_SIZE_HINT_P_MIN_SIZE | XCB_ICCCM_SIZE_HINT_P_MAX_SIZE;
                    wmHints.flags |= hints.flags;
                    hints.max_width = w;
                    hints.max_height = h;
                    hints.min_width = w;
                    hints.min_height = h;

                    xcb_icccm_set_wm_size_hints(runtime.connection, handle, XCB_ATOM_WM_NORMAL_HINTS, &hints);
                } else
                {
                    wmHints.flags &= ~(XCB_ICCCM_SIZE_HINT_P_MIN_SIZE | XCB_ICCCM_SIZE_HINT_P_MAX_SIZE);
                }

                _resizable = value;

                xcb_icccm_set_wm_hints(runtime.connection, handle, &wmHints);
                xcb_flush(runtime.connection);
            }

            /// Whether the window can be resized by the user.
            @property bool resizable() @safe
            {
                return _resizable;
            }

            /// Frames around the window.
            @property void border(bool value) @trusted
            {
                import std.conv : to;

                struct MWMHints {
                    ulong flags;
                    ulong functions;
                    ulong decorations;
                    long inputMode;
                    ulong status;
                }

                const hint = MWMHints(2, 0, value.to!ulong, 0, 0);
                const wmHINTS = getAtom("_MOTIF_WM_HINTS");

                xcb_change_property(
                    runtime.connection,
                    XCB_PROP_MODE_REPLACE,
                    handle,
                    wmHINTS,
                    wmHINTS,
                    32,
                    MWMHints.sizeof / long.sizeof,
                    cast(char*) &hint
                );
                xcb_flush(runtime.connection);

                _border = value;
            }

            /// Frames around the window.
            @property bool border()
            {
                return _border;
            }

            /// Window title.
            @property void title(string value) @trusted
            {
                import std.string : toStringz;

                xcb_change_property(
                    runtime.connection,
                    XCB_PROP_MODE_REPLACE,
                    handle,
                    XCB_ATOM_WM_NAME,
                    XCB_ATOM_STRING,
                    8,
                    cast(uint) value.length,
                    cast(void*) value.toStringz
                );
                xcb_flush(runtime.connection);

                _title = value;
            }

            /// Window title.
            @property string title()
            {
                return _title;
            }

            /// Whether the window is always on top of the others.
            @property void alwaysOnTop(bool value) @trusted
            {
                import std.string : toStringz;

                auto wmAbove = getAtom("_NET_WM_STATE_ABOVE");
                auto wmState = getAtom("_NET_WM_STATE");

                xcb_client_message_event_t* event = cast(xcb_client_message_event_t*) malloc(xcb_client_message_event_t.sizeof);
                event.window = handle;
                event.format = 32;
                event.data.data32[0] = value;
                event.data.data32[1] = wmAbove;
                event.data.data32[2] = XCB_ATOM_NONE;
                event.type = wmState;

                xcb_send_event(runtime.connection, 0, runtime.screen.root, XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT | XCB_EVENT_MASK_STRUCTURE_NOTIFY, cast(char*) event);
                xcb_flush(runtime.connection);

                _alwaysTop = value;
            }

            /// Whether the window is always on top of the others.
            @property bool alwaysOnTop()
            {
                return _alwaysTop;
            }

            /// Dynamic window icon.
            @property void icon(Image iconimage) @trusted
            {
                import tida.color;
                import std.string : toStringz;

                ulong[] pixels = [  cast(ulong) iconimage.width,
                                    cast(ulong) iconimage.height];

                foreach(pixel; iconimage.pixels)
                    pixels ~= pixel.to!(ulong, PixelFormat.ARGB);

                immutable wmName = "_NET_WM_ICON";
                auto c = xcb_intern_atom(runtime.connection, 0, wmName.length, wmName.toStringz);
                xcb_flush(runtime.connection);
                auto atomReply = xcb_intern_atom_reply(runtime.connection, c, null);
                auto atom = atomReply.atom;
                free(atomReply);

                xcb_change_property(
                    runtime.connection,
                    XCB_PROP_MODE_REPLACE,
                    handle,
                    atom,
                    XCB_ATOM_CARDINAL,
                    32,
                    cast(uint) pixels.length,
                    cast(void*) pixels.ptr
                );
                xcb_flush(runtime.connection);
            }

            /++
            Window resizing function.

            Params:
                w = Window width.
                h = Window height.
            +/
            void resize(uint w, uint h) @trusted
            {
                immutable(uint) mask = XCB_CONFIG_WINDOW_WIDTH | XCB_CONFIG_WINDOW_HEIGHT;
                immutable(uint[]) values = [
                    w, h
                ];

                xcb_configure_window(runtime.connection, handle, mask, values.ptr);
                xcb_flush(runtime.connection);
            }

            /++
            Changes the position of the window in the plane of the desktop.

            Params:
                xposition = Position x-axis.
                yposition = Position y-axis.
            +/
            void move(int xposition, int yposition) @trusted
            {
                immutable(uint) mask = XCB_CONFIG_WINDOW_X | XCB_CONFIG_WINDOW_Y;
                immutable(uint[]) values = [
                    xposition, yposition
                ];

                xcb_configure_window(runtime.connection, handle, mask, values.ptr);
                xcb_flush(runtime.connection);
            }

            /++
            Shows a window in the plane of the desktop.
            +/
            void show() @trusted
            {
                xcb_map_window(runtime.connection, handle);
                xcb_flush(runtime.connection);
            }

            /++
            Hide a window in the plane of the desktop.
            (Can be tracked in the task manager.)
            +/
            void hide() @trusted
            {
                xcb_unmap_window(runtime.connection, handle);
                xcb_flush(runtime.connection);
            }

            /++
            Destroys the window and its associated data (not the structure itself, all values are reset to zero).
            +/
            void destroy() @trusted
            {
                xcb_destroy_window(runtime.connection, handle);
            }
        }
    } else
    {
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
            //IContext _context;
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
                                           LeaveWindowMask | PointerMotionMask | StructureNotifyMask;

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

            void destroy()
            {
                XDestroyWindow(runtime.display, this.handle);
                this.handle = 0;
            }
        }
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
        deviceHandle = (cast(Window) window).dc;
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
            WGL_CONTEXT_MAJOR_VERSION_ARB, this.attributes.glmajor,
            WGL_CONTEXT_MINOR_VERSION_ARB, this.attributes.glminor,
            WGL_CONTEXT_FLAGS_ARB, WGL_CONTEXT_FORWARD_COMPATIBLE_BIT_ARB,
            WGL_CONTEXT_PROFILE_MASK_ARB, WGL_CONTEXT_CORE_PROFILE_BIT_ARB,
            0
        ];
        this._context = wglCreateContextAttribsARB( deviceHandle, 
                                                    null, 
                                                    attrib.ptr);
        enforce(this._context, "ContextARB is not a create!");

        wglMakeCurrent(null, null);
        wglDeleteContext(ctx);
    }

    void destroy()
    {
        wglDeleteContext(_context);
    }
}

__gshared Window _wndptr;

version(Windows)
class Window : IWindow
{
    import tida.runtime;
    import tida.image;
    import tida.color;

    import std.utf : toUTFz;
    import std.exception : enforce;
    import core.sys.windows.windows;

    class WindowException : Exception
    {
        import std.conv : to;
        
        this(ulong errorID) @trusted
        {
            LPSTR messageBuffer = null;

            size_t size = FormatMessageA(
                FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                null, 
                cast(uint) errorID, 
                MAKELANGID(LANG_ENGLISH, SUBLANG_ENGLISH_US), 
                cast(LPSTR) &messageBuffer, 
                0, 
                null);
                            
        
            super("[WinAPI] " ~ messageBuffer.to!string);
        }
    }

private:
    uint _widthInit;
    uint _heightInit;

    string _title;

    bool _fullscreen = false;
    bool _border = true;
    bool _resizable = true;
    bool _alwaysTop = false;

    IContext _context;

    LONG style;
    LONG oldStyle;
    WINDOWPLACEMENT wpc;

public:
    HWND handle;
    HDC dc;
    bool isClose = false;
    bool isResize = false;

    this(uint w, uint h, string caption)
    {
        this._widthInit = w;
        this._heightInit = h;
        _title = caption;
    }

@trusted:
    void create(int posX, int posY)
    {
        import std.traits : Signed;
    
        extern(Windows) auto _wndProc(HWND hWnd, uint message, WPARAM wParam, LPARAM lParam)
        {
            switch (message)
            {
                case WM_CLOSE:
                    if (_wndptr is null || _wndptr.__vptr is null) return 0;
                    
                    _wndptr.sendCloseEvent();
                    return 0;

                case WM_SIZE:
                    if (_wndptr is null || _wndptr.__vptr is null) return 0;

                    _wndptr.isResize = true;
                    return 0;

                default:
                    return DefWindowProc(hWnd, message, wParam, lParam);
            }
        }

        alias WinFun = extern (Windows) Signed!size_t function(void*, uint, size_t, Signed!size_t) nothrow @system;

        WNDCLASSEX wc;

        wc.cbSize = wc.sizeof;
        wc.style = CS_HREDRAW | CS_VREDRAW | CS_OWNDC;
        wc.lpfnWndProc = cast(WinFun) &_wndProc;
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
                 
        if (this.handle is null)
            throw new WindowException(GetLastError());

        dc = GetDC(this.handle);
        
        resize(this._widthInit, this._heightInit);

        _wndptr = this;
    }

    void sendCloseEvent()
    {
        this.isClose = true;
    }
    
    @property auto windowBorderSize() @trusted
    {
        if (_fullscreen || !_border)
        {
            return 0;
        } else
        {
            RECT rcClient, rcWind;
            GetClientRect(this.handle, &rcClient);
            GetWindowRect(this.handle, &rcWind);
            
            return ((rcWind.bottom - rcWind.top) - rcClient.bottom) / 2;
        }
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

        return rect.right - rect.left;
    }

    @property uint height()
    {
        RECT rect;
        GetWindowRect(this.handle, &rect);

        return rect.bottom - rect.top - windowBorderSize;
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
        int bs;
        
        if (border)
            bs = windowBorderSize;
    
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

        SendMessage(handle, WM_SETICON, ICON_SMALL, cast(LPARAM) icon);
        SendMessage(handle, WM_SETICON, ICON_BIG, cast(LPARAM) icon);
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
        RECT rcClient, rcWind;

        GetClientRect(this.handle, &rcClient);
        GetWindowRect(this.handle, &rcWind);
        immutable offsetY = (rcWind.bottom - rcWind.top) - rcClient.bottom;
        
        SetWindowPos(this.handle, null, x, y, w, h + offsetY - 1, 0);
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
void windowInitialize(  Window window,
                        int posX,
                        int posY) @trusted
{
    version(Posix)
    {
        version(UseXCB)
        {
            import tida.runtime;

            window.createFromVisual(runtime.screen.root_visual, posX, posY);
            window.show();
        } else
        {
            import tida.runtime;
            import x11.X, x11.Xlib, x11.Xutil;

            scope XVisualInfo* vinfo = new XVisualInfo();
            vinfo.visual = XDefaultVisual(runtime.display, runtime.displayID);
            vinfo.depth = XDefaultDepth(runtime.display, runtime.displayID);

            window.createFromXVisual(vinfo);

            destroy(vinfo);

            window.show();
        }
    }
    else
    version(Windows)
    {
        window.create(posX, posY);
    
        static if(type == WithContext)
        {
            GraphicsAttributes attribs = AttribBySizeOfTheColor!8;
            attribs.glmajor = 4;
            attribs.glminor = 5;

            Context context;
            
            void ctxCreate()
            {
                context = new Context();
                context.setAttributes(attribs);
                context.create(window);
            }

            try
            {
                ctxCreate();
            } catch(Exception e)
            {
                attribs.glmajor = 3;
                attribs.glminor = 3;

                try
                {
                    ctxCreate();
                } catch(Exception e)
                {
                    attribs.glmajor = 3;
                    attribs.glminor = 0;
                    
                    ctxCreate();
                }
            }

            window.context = context;
        }

        window.show();
    }
}
