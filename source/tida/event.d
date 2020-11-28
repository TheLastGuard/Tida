/++
    Event handler module.

    Authors: TodNaz
    License: MIT
+/
module tida.event;

/// Event handler.
public class EventHandler
{
    version(Posix)
    {
        import x11.Xlib;
        import x11.X;
        import x11.Xutil;
    }

    version(Windows)
    {
        import core.sys.windows.windows;
    }

    import tida.runtime, tida.window;

    private
    {
        tida.window.Window window;

        version(Posix) 
        {
            Atom destroyWindowEvent;
            XEvent event;
        }

        version(Windows)
        {
            MSG msg;
        }
    }

    /++
        Initializes an event handler.

        Params:
            window = For which window to process events.
    +/
    this(tida.window.Window window) @trusted
    {
        this.window = window;

        version(Posix)
        {
            XSync(runtime.display, false);

            XSelectInput(runtime.display, window.xWindow, ExposureMask | ButtonPressMask | KeyPressMask |
                                                          KeyReleaseMask | ButtonReleaseMask | EnterWindowMask |
                                                          LeaveWindowMask | ResizeRedirectMask);

            destroyWindowEvent = XInternAtom(runtime.display, "WM_DELETE_WINDOW", False);

            XSetWMProtocols(runtime.display, window.xWindow, &destroyWindowEvent, 1);
        }
    }

    public void handle(void delegate() @safe func) @safe @property
    {
        while(this.update)
        {
            func();
        }
    }

    /++
        Updates the event queue. Returns whether there are events in the queue. 
        On each call, the queue is advanced.
    +/
    public bool update() @safe
    {
        version(Posix) return xUpdate();
        version(Windows) return wUpdate();
    }

    ///
    version(Windows) public bool wUpdate() @trusted
    {
        TranslateMessage(&msg); 
        DispatchMessage(&msg);

        return PeekMessage(&msg, window.wWindow,0,0,PM_REMOVE) != 0;
    }

    ///
    version(Posix) public bool xUpdate() @trusted
    {
        auto pen = XPending(runtime.display);
        
        if(pen != 0)
            XNextEvent(runtime.display, &event);

        return pen != 0;
    }  

    ///
    version(Posix) public bool xIsKeyDown() @trusted
    {
        return event.type == KeyPress;
    }

    ///
    version(Posix) public bool xIsKeyUp() @trusted
    {
        return event.type == KeyRelease;
    }

    ///
    version(Windows) public bool wIsKeyDown() @trusted
    {
        return msg.message == WM_KEYDOWN;
    }

    ///
    version(Windows) public bool wIsKeyUp() @trusted
    {
        return msg.message == WM_KEYUP;
    }

    ///
    version(Posix) public auto xGetKey() @trusted
    {
        return event.xkey.keycode;
    }

    ///
    version(Windows) public auto wGetKey() @trusted
    {
        return msg.wParam;
    }

    /++
        Returns the pressed key.
    +/
    public auto getKeyDown() @safe
    {
        version(Posix) return xIsKeyDown ? xGetKey() : 0;
        version(Windows) return wIsKeyDown ? wGetKey() : 0;
    }

    /++
        Returns the released key.
    +/
    public auto getKeyRelease() @safe
    {
        version(Posix) return xIsKeyUp ? xGetKey() : 0;
        version(Windows) return wIsKeyUp ? wGetKey() : 0;
    }

    /++
        Returns the key.
    +/
    public auto getKey() @safe
    {
        version(Posix) return xGetKey();
        version(Windows) return wGetKey();
    }

    /++
        Returns a state indicating whether a key is pressed.
    +/
    public bool isKeyDown() @safe
    {
        version(Posix) return xIsKeyDown();
        version(Windows) return wIsKeyDown();
    }

    /++
        Returns a state indicating whether a key is released.
    +/ 
    public bool isKeyUp() @safe
    {
        version(Posix) return xIsKeyUp();
        version(Windows) return wIsKeyUp();
    }

    ///
    version(Posix) public bool xIsMouseDown() @trusted
    {
        return event.type == ButtonPress;
    }

    ///
    version(Posix) public bool xIsMouseUp() @trusted
    {
        return event.type == ButtonRelease;
    }

    ///
    version(Posix) public auto xGetMouseButton() @trusted
    {
        return event.xbutton.button;
    }

    ///
    version(Windows) public bool wIsMouseDown() @trusted
    {
        return msg.message == WM_LBUTTONDOWN ||
               msg.message == WM_RBUTTONDOWN ||
               msg.message == WM_MBUTTONDOWN;
    }

    ///
    version(Windows) public bool wIsMouseUp() @trusted
    {
        return msg.message == WM_LBUTTONUP ||
               msg.message == WM_RBUTTONUP ||
               msg.message == WM_MBUTTONUP;
    }

    ///
    version(Windows) public auto wGetMouseButton() @trusted
    {
        if(msg.message == WM_LBUTTONUP || msg.message == WM_LBUTTONDOWN)
            return MouseButton.left;

        if(msg.message == WM_RBUTTONUP || msg.message == WM_RBUTTONDOWN)
            return MouseButton.right;

        if(msg.message == WM_MBUTTONUP || msg.message == WM_MBUTTONDOWN)
            return MouseButton.middle;

        return 0;
    }

    /++
        Returns the pressed mouse button.
    +/
    public auto getMouseDown() @safe
    {
        version(Posix) return xIsMouseDown ? xGetMouseButton() : 0;
        version(Windows) return wIsMouseDown ? wGetMouseButton() : 0;
    }

    /++
        Returns the released mouse button.
    +/
    public auto getMouseUp() @safe
    {
        version(Posix) return xIsMouseUp ? xGetMouseButton() : 0;
        version(Windows) return wIsMouseUp ? wGetMouseButton() : 0;
    }

    ///
    version(Posix) public int[2] xMousePosition() @trusted
    {
        int x,y;
        uint mask;

        auto win = window.xWindow;

        XQueryPointer(runtime.display, win, 
                      &win, &win, &x, &y, &x, &y, &mask);

        return [x,y];
    }

    ///
    version(Windows) public int[2] wMousePosition() @trusted
    {
        POINT p;

        GetCursorPos(&p);

        ScreenToClient(window.wWindow,&p);

        return [p.x,p.y];
    }

    ///
    version(Posix) public bool xIsResize() @trusted
    {
        return event.type == ResizeRequest;
    }

    ///
    version(Windows) public bool wIsResize() @trusted
    {
        return msg.message == WM_SIZE;
    }

    /++
        Returns whether the window has been resized.
    +/
    public bool isResize() @safe
    {
        version(Posix) return xIsResize();
        version(Windows) return wIsResize();
    } 

    ///
    version(Posix) public int[2] xResizeWindowSize() @trusted
    {
        return [event.xresizerequest.width,event.xresizerequest.height];
    }

    ///
    version(Windows) public int[2] wResizeWindowSize() @trusted
    {
        RECT rect;

        GetWindowRect(window.wWindow,&rect);

        return [rect.right,rect.bottom];
    }

    /++
        Returns whether the window has been resized.
    +/
    public int[2] resizeWindowSize() @safe
    {
        version(Posix) return xResizeWindowSize();
        version(Windows) return wResizeWindowSize();
    }

    /++
        Returns mouse position.
    +/
    public int[2] mouse() @safe @property
    {
        version(Posix) return xMousePosition();
        version(Windows) return wMousePosition();
    }

    ///
    version(Posix) public bool xIsQuit() @trusted
    {
        return event.xclient.data.l[0] == destroyWindowEvent;
    }

    ///
    version(Windows) public bool wIsQuit() @trusted
    {
        return msg.message == WM_QUIT || msg.message == WM_CLOSE || 
               (msg.message == WM_SYSCOMMAND && msg.wParam == SC_CLOSE);
    }

    /++
        Do they close the window.
    +/
    public bool isQuit() @safe
    {
        version(Posix) return xIsQuit();
        version(Windows) return wIsQuit();
    }
}

///
static enum MouseButton
{
    left = 1,
    right = 3,
    middle = 2
}

version(Posix)///
static enum Key
{
    Escape = 9,
    F1 = 67,
    F2 = 68,
    F3 = 69,
    F4 = 70,
    F5 = 71,
    F6 = 72,
    F7 = 73,
    F8 = 74,
    F9 = 75,
    F10 = 76,
    F11 = 95,
    F12 = 96,
    PrintScrn = 111,
    ScrollLock = 78,
    Pause = 110,
    Backtick = 49,
    K1 = 10,
    K2 = 11,
    K3 = 12,
    K4 = 13,
    K5 = 14,
    K6 = 15,
    K7 = 16,
    K8 = 17,
    K9 = 18,
    K0 = 19,
    Minus = 20,
    Equal = 21,
    Backspace = 22,
    Insert = 106,
    Home = 97,
    PageUp = 99,
    NumLock = 77,
    KPSlash = 112,
    KPStar = 63,
    KPMinus = 82,
    Tab = 23,
    Q = 24,
    W = 25,
    E = 26,
    R = 27,
    T = 28,
    Y = 29,
    U = 30,
    I = 31,
    O = 32,
    P = 33,

    SqBrackLeft = 34,
    SqBrackRight = 35,
    SquareBracketLeft = 34,
    SquareBracketRight = 35,

    Return = 36,
    Delete = 107,
    End = 103,
    PageDown = 105,

    KP7 = 79,
    KP8 = 80,
    KP9 = 81,

    CapsLock = 66,
    A = 38,
    S = 39,
    D = 40,
    F = 41,
    G = 42,
    H = 43,
    J = 44,
    K = 45,
    L = 46,
    Semicolons = 47,
    Apostrophe = 48,

    KP4 = 83,
    KP5 = 84,
    KP6 = 85,

    ShiftLeft = 50,
    International = 94,

    Z = 52,
    X = 53,
    C = 54,
    V = 55,
    B = 56,
    N = 57,
    M = 58,
    Comma = 59,
    Point = 60,
    Slash = 61,

    ShiftRight = 62,

    BackSlash = 51,
    Up = 98,

    KP1 = 87,
    KP2 = 88,
    KP3 = 89,

    KPEnter = 108,
    CtrlLeft = 37,
    SuperLeft = 115,
    AltLeft = 64,
    Space = 65,
    AltRight = 113,
    LogoRight = 116,
    Menu = 117,
    CtrlRight = 109,
    Left = 100,
    Down = 104,
    Right = 102,
    KP0 = 90,
    KPPoint = 91
}

version(Windows)///
static enum Key
{
    Escape = 0x1B,
    F1 = 0x70,
    F2 = 0x71,
    F3 = 0x72,
    F4 = 0x73,
    F5 = 0x74,
    F6 = 0x75,
    F7 = 0x76,
    F8 = 0x77,
    F9 = 0x78,
    F10 = 0x79,
    F11 = 0x7A,
    F12 = 0x7B,
    PrintScrn = 0x2A,
    ScrollLock = 0x91,
    Pause = 0x13,
    Backtick = 0xC0,
    K1 = 0x31,
    K2 = 0x32,
    K3 = 0x33,
    K4 = 0x34,
    K5 = 0x35,
    K6 = 0x36,
    K7 = 0x37,
    K8 = 0x38,
    K9 = 0x39,
    K0 = 0x30,
    Minus = 0xBD,
    Equal = 0xBB,
    Backspace = 0x08,
    Insert = 0x2D,
    Home = 0x24,
    PageUp = 0x21,
    NumLock = 0x90,
    KPSlash = 0x6F,
    KPStar = 0xBB,
    KPMinus = 0xBD,
    Tab = 0x09,
    Q = 0x51,
    W = 0x57,
    E = 0x45,
    R = 0x52,
    T = 0x54,
    Y = 0x59,
    U = 0x55,
    I = 0x49,
    O = 0x4F,
    P = 0x50,

    SqBrackLeft = 0xDB,
    SqBrackRight = 0xDD,
    SquareBracketLeft = 0x30,
    SquareBracketRight = 0xBD,

    Return = 0x0D,
    Delete = 0x2E,
    End = 0x23,
    PageDown = 0x22,

    KP7 = 0x67,
    KP8 = 0x68,
    KP9 = 0x69,

    CapsLock = 0x14,
    A = 0x41,
    S = 0x53,
    D = 0x44,
    F = 0x46,
    G = 0x47,
    H = 0x48,
    J = 0x4A,
    K = 0x4B,
    L = 0x4C,
    Semicolons = 0xBA,
    Apostrophe = 0xBF,

    KP4 = 0x64,
    KP5 = 0x65,
    KP6 = 0x66,

    ShiftLeft = 0xA0,
    International = 0xA4,

    Z = 0x5A,
    X = 0x58,
    C = 0x43,
    V = 0x56,
    B = 0x42,
    N = 0x4E,
    M = 0x4D,
    Comma = 0xBC,
    Point = 0xBE,
    Slash = 0xBF,

    ShiftRight = 0xA1,

    BackSlash = 0xE2,
    Up = 0x26,

    KP1 = 0x61,
    KP2 = 0x62,
    KP3 = 0x63,

    KPEnter = 0x6A,
    CtrlLeft = 0xA2,
    SuperLeft = 0xA4,
    AltLeft = 0xA4,
    Space = 0x20,
    AltRight = 0xA5,
    SuperRight = 0xA5,
    Menu = 0,
    CtrlRight = 0xA3,
    Left = 0x25,
    Down = 0x28,
    Right = 0x27,
    KP0 = 0x60,
    KPPoint = 0x6F
}