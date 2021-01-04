/++
    Module for handling events.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.event;

/// Mouse keys.
enum MouseButton
{
    unknown = 0,
    left = 1,
    right = 3,
    middle = 2
}

///
interface IEventHandler
{
    /++
        Shows the key pressed or released in the current event.

        Returns: state, whether there is still an event in the queue.
    +/
    bool update() @safe;

    /// Indicates whether any key is pressed.
    bool isKeyDown() @safe;

    /// Indicates whether any key is released.
    bool isKeyUp() @safe;

    /// Shows the key pressed or released in the current event.
    int key() @safe @property;

    /// Whether any mouse button is pressed.
    bool isMouseDown() @safe;

    /// Whether any mouse button is released.
    bool isMouseUp() @safe;

    /// The currently pressed mouse button.
    MouseButton mouseButton() @safe @property;

    /// The current position of the cursor.
    int[2] mousePosition() @safe @property;

    /// Whether the window is resized.
    bool isResize() @safe;

    /// Gives the new window size if it was changed by the user.
    uint[2] newSizeWindow() @safe;

    /// Did they send a signal to end the program.
    bool isQuit() @safe;

    /// Returns the pressed key.
    final int keyDown() @safe
    {
        return isKeyDown ? key : 0;
    }

    /// Returns the released key.
    final int keyUp() @safe
    {
        return isKeyUp ? key : 0;
    }

    /// Returns the pressed mouse button.
    final MouseButton mouseDownButton() @safe
    {
        return isMouseDown ? mouseButton : MouseButton.unknown;
    }

    /// Returns the released mouse button.
    final MouseButton mouseUpButton() @safe
    {
        return isMouseDown ? mouseButton : MouseButton.unknown;
    }
}

version(Posix)
class EventHandler : IEventHandler
{
    import tida.x11, tida.runtime;

    private 
    {
        tida.window.Window window;
        Atom destroyWindowEvent;
        XEvent event;
    }

    this(tida.window.Window window) @safe
    {
        this.window = window;

        destroyWindowEvent = GetAtom!"WM_DELETE_WINDOW";
    }

    override bool update() @trusted
    {
        auto pen = XPending(runtime.display);
        
        if(pen != 0) {
            XNextEvent(runtime.display, &event);
        }

        return pen != 0;
    }

    override bool isKeyDown() @safe
    {
        return event.type == KeyPress;
    }

    override bool isKeyUp() @safe
    {
        return event.type == KeyRelease;
    }

    override int key() @trusted
    {
        return event.xkey.keycode;
    }

    override bool isMouseDown() @safe
    {
        return event.type == ButtonPress;
    }

    override bool isMouseUp() @safe
    {
        return event.type == ButtonRelease;
    }

    override MouseButton mouseButton() @trusted
    {
        return cast(MouseButton) event.xbutton.button;
    }

    override int[2] mousePosition() @trusted
    {
        int x = event.xmotion.x;
        int y = event.xmotion.y;

        return [x,y];
    }

    override bool isResize() @trusted
    {
        XWindowAttributes attr;
        XGetWindowAttributes(runtime.display, (cast(tida.window.Window) window).handle, &attr);
        return (window.width != attr.width || window.height != attr.height);
    }

    override uint[2] newSizeWindow() @trusted
    {
        XWindowAttributes attr;
        XGetWindowAttributes(runtime.display, (cast(tida.window.Window) window).handle, &attr);

        return [attr.width,attr.height];
    }

    override bool isQuit() @trusted
    {
        return event.xclient.data.l[0] == destroyWindowEvent;
    }
}

version(Windows)
class EventHandler : IEventHandler
{
    import tida.winapi, tida.window;

    private
    {
        MSG msg;
        tida.window.Window window;
    }

    this(tida.window.Window window)
    {
        this.window = window;
    }

    override bool update() @trusted
    {
        TranslateMessage(&msg); 
        DispatchMessage(&msg);

        return PeekMessage(&msg, window.handle,0,0,PM_REMOVE) != 0;
    }

    override bool isKeyDown() @safe
    {
        return msg.message == WM_KEYDOWN;
    }

    override bool isKeyUp() @safe
    {
        return msg.message == WM_KEYUP;
    }

    override int key() @safe
    {
        return cast(int) msg.wParam;
    }

    override bool isMouseDown() @safe
    {
        return msg.message == WM_LBUTTONDOWN ||
               msg.message == WM_RBUTTONDOWN ||
               msg.message == WM_MBUTTONDOWN;
    }

    override bool isMouseUp() @safe
    {
        return msg.message == WM_LBUTTONUP ||
               msg.message == WM_RBUTTONUP ||
               msg.message == WM_MBUTTONUP;
    }

    override MouseButton mouseButton() @safe
    {
        if(msg.message == WM_LBUTTONUP || msg.message == WM_LBUTTONDOWN)
            return MouseButton.left;

        if(msg.message == WM_RBUTTONUP || msg.message == WM_RBUTTONDOWN)
            return MouseButton.right;

        if(msg.message == WM_MBUTTONUP || msg.message == WM_MBUTTONDOWN)
            return MouseButton.middle;

        return MouseButton.unknown;
    }

    override int[2] mousePosition() @trusted
    {
        POINT p;

        GetCursorPos(&p);

        ScreenToClient((cast(Window) window).handle,&p);

        return [p.x,p.y];
    }

    override bool isResize() @safe
    {
        return msg.message == WM_SIZE;
    }

    override uint[2] newSizeWindow() @trusted
    {
        RECT rect;

        GetWindowRect((cast(Window) window).handle, &rect);

        return [rect.right,rect.bottom];
    }

    override bool isQuit() @safe
    {
        return msg.message == WM_QUIT || msg.message == WM_CLOSE || 
               (msg.message == WM_SYSCOMMAND && msg.wParam == SC_CLOSE);
    }
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