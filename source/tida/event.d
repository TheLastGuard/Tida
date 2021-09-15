/++
A module for listening to incoming events from the window manager for their 
subsequent processing.

Such a layer does not admit events directly to the data, but whether it can show
what is happening at the moment, which can serve as a cross-plotter tracking 
of events.

Using the IEventHandler.nextEvent function, you can scroll through the queue of 
events that can be processed and at each queue, the programmer needs to track 
the events he needs by the functions of the same interface:
---
while (event.nextEvent()) {
    if (event.keyDown == Key.Space) foo();
}
---
As you can see, we loop through each event and read what happened.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.event;

enum DeprecatedMethodSize = 
"This function is useless. Use the parameters `IWindow.width/IWindow.height`.";

/// Mouse keys.
enum MouseButton
{
    unknown = 0, /// Unknown mouse button
    left = 1, /// Left mouse button
    right = 3, /// Right mouse button
    middle = 2 /// Middle mouse button
}

/++
Interface for cross-platform listening for events from the window manager.
+/
interface IEventHandler
{
@safe:
    /++
    Moves to the next event. If there are no more events, it returns false, 
    otherwise, it throws true and the programmer can safely check which event 
    s in the current queue.
    +/
    bool nextEvent();

    /++
    Checking if any key is pressed in the current event.
    +/
    bool isKeyDown();

    /++
    Checking if any key is released in the current event.
    +/
    bool isKeyUp();

    /++
    Will return the key that was pressed. Returns zero if no key is pressed 
    in the current event.
    +/
    @property int key();

    /++
    Returns the key at the moment the key was pressed, 
    otherwise it returns zero.
    +/
    @property final int keyDown()
    {
        return isKeyDown ? key : 0;
    }

    /++
    Returns the key at the moment the key was released, 
    otherwise it returns zero.
    +/
    @property final int keyUp()
    {
        return isKeyUp ? key : 0;
    }

    /++
    Check if the mouse button is pressed in the current event.
    +/
    bool isMouseDown();

    /++
    Check if the mouse button is released in the current event.
    +/
    bool isMouseUp();

    /++
    Returns the currently pressed or released mouse button.
    +/
    @property MouseButton mouseButton();

    /++
    Returns the mouse button at the moment the key was pressed; 
    otherwise, it returns zero.
    +/
    @property final MouseButton mouseDownButton()
    {
        return isMouseDown ? mouseButton : MouseButton.unknown;
    }

    /++
    Returns the mouse button at the moment the key was released; 
    otherwise, it returns zero.
    +/
    @property final MouseButton mouseUpButton()
    {
        return isMouseUp ? mouseButton : MouseButton.unknown;
    }

    /++
    Returns the position of the mouse in the window.
    +/
    @property int[2] mousePosition();

    /++
    Returns in which direction the user is turning the mouse wheel. 
    1 - down, -1 - up, 0 - does not twist. 

    This iteration is convenient for multiplying with some real movement coefficient.
    +/
    @property int mouseWheel();

    /++
    Indicates whether the window has been resized in this event.
    +/
    bool isResize();

    /++
    Returns the new size of the window 
    
    deprecated: 
    although this will already be available directly in the 
    window structure itself.
    +/
    deprecated(DeprecatedMethodSize) 
    uint[2] newSizeWindow();

    /++
    Indicates whether the user is attempting to exit the program.
    +/
    bool isQuit();

    /++
    Indicates whether the user has entered text information.
    +/
    bool isInputText();

    /++
    User entered data.
    +/
    @property string inputChar();

@trusted:
    final int opApply(scope int delegate(ref int) dg)
    {
        int count = 0;

        while (this.nextEvent()) 
        {
            dg(++count);
        }

        return 0;
    }
}

version(Posix)
class EventHandler : IEventHandler
{
    import x11.X, x11.Xlib, x11.Xutil;
    import tida.window, tida.runtime;

private:
    tida.window.Window window;
    Atom destroyWindowEvent;
    _XIC* ic;

public:
    XEvent event;

@trusted:
    this(tida.window.Window window)
    {   
        this.window = window;

        this.destroyWindowEvent = XInternAtom(runtime.display, "WM_DELETE_WINDOW", 0);

        ic = XCreateIC( XOpenIM(runtime.display, null, null, null), 
                        XNInputStyle, XIMPreeditNothing | XIMStatusNothing, 
                        XNClientWindow, this.window.handle, null);
        XSetICFocus(ic);
        XSetLocaleModifiers("@im=none");
    }

override:
    bool nextEvent()
    {
        auto pen = XPending(runtime.display);
        
        if (pen != 0) 
        {
            XNextEvent(runtime.display, &this.event);
        }

        return pen != 0;
    }

    bool isKeyDown()
    {
        return this.event.type == KeyPress;
    }

    bool isKeyUp()
    {
        return this.event.type == KeyRelease;
    }

    @property int key()
    {
        return this.event.xkey.keycode;
    }

    bool isMouseDown()
    {
        return this.event.type == ButtonPress;
    }

    bool isMouseUp()
    {
        return this.event.type == ButtonRelease;
    }

    @property MouseButton mouseButton()
    {
        return cast(MouseButton) this.event.xbutton.button;
    }

    @property int[2] mousePosition() @trusted
    {
        return [this.event.xmotion.x, this.event.xmotion.y];
    }

    @property int mouseWheel()
    {
        return this.isMouseDown ? 
            (this.mouseButton == 4 ? -1 : (this.mouseButton == 5 ? 1 : 0)) : 0;
    }

    bool isResize()
    {
        return this.event.type == ConfigureNotify;
    }

    uint[2] newSizeWindow()
    {
        XWindowAttributes attr;
        XGetWindowAttributes(   runtime.display, 
                                (cast(tida.window.Window) this.window).handle, &attr);

        return [attr.width, attr.height];
    }

    bool isQuit()
    {
        return this.event.xclient.data.l[0] == this.destroyWindowEvent;
    }

    bool isInputText() 
    {
        return this.isKeyDown;
    } 

    @property string inputChar()
    {
        int count;
        string buf = new string(20);
        KeySym ks;
        Status status = 0;

        count = Xutf8LookupString(  this.ic, cast(XKeyPressedEvent*) &this.event.xkey, 
                                    cast(char*) buf.ptr, 20, &ks, &status);

        return buf[0 .. count];
    }
}

version(Windows)
class EventHandler : IEventHandler
{
    import tida.window, tida.runtime;
    import core.sys.windows.windows;

private:
    tida.window.Window window;

public:
    MSG msg;

@safe:
    this(tida.window.Window window)
    {
        this.window = window;
    }

@trusted:
    bool nextEvent()
    {
        TranslateMessage(&this.msg); 
        DispatchMessage(&this.msg);

        return PeekMessage(&this.msg, this.window.handle, 0, 0, PM_REMOVE) != 0;
    }

    bool isKeyDown()
    {
        return this.msg.message == WM_KEYDOWN;
    }

    bool isKeyUp()
    {
        return this.msg.message == WM_KEYUP;
    }

    @property int key()
    {
        return cast(int) this.msg.wParam;
    }

    bool isMouseDown()
    {
        return this.msg.message == WM_LBUTTONDOWN ||
               this.msg.message == WM_RBUTTONDOWN ||
               this.msg.message == WM_MBUTTONDOWN;
    }

    bool isMouseUp()
    {
        return this.msg.message == WM_LBUTTONUP ||
               this.msg.message == WM_RBUTTONUP ||
               this.msg.message == WM_MBUTTONUP;
    }

    @property MouseButton mouseButton()
    {
        if (this.msg.message == WM_LBUTTONUP || this.msg.message == WM_LBUTTONDOWN)
            return MouseButton.left;

        if (this.msg.message == WM_RBUTTONUP || this.msg.message == WM_RBUTTONDOWN)
            return MouseButton.right;

        if (this.msg.message == WM_MBUTTONUP || this.msg.message == WM_MBUTTONDOWN)
            return MouseButton.middle;

        return MouseButton.unknown;
    }

    @property int[2] mousePosition()
    {
        POINT p;
        GetCursorPos(&p);
        ScreenToClient((cast(Window) this.window).handle, &p);

        return [p.x, p.y];
    }

    @property int mouseWheel()
    {
        if (this.msg.message != WM_MOUSEWHEEL) return 0;

        return (cast(int) this.msg.wParam) > 0 ? -1 : 1;
    }

    bool isResize()
    {
        return this.msg.message == WM_SIZE;
    }

    uint[2] newSizeWindow()
    {
        RECT rect;
        GetWindowRect((cast(Window) this.window).handle, &rect);

        return [rect.right, rect.bottom];
    }

    bool isQuit()
    {
        return  this.msg.message == WM_QUIT || this.msg.message == WM_CLOSE || 
               (this.msg.message == WM_SYSCOMMAND && this.msg.wParam == SC_CLOSE);
    }

    bool isInputText()
    {
        return this.msg.message == WM_CHAR;
    }

    string inputChar()
    {
        import std.utf : toUTF8;

        wstring text = [];
        text = [cast(wchar) msg.wParam];

        string utftext = text.toUTF8;

        return [utftext[0]];
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
    Up = 111,

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
    Left = 113,
    Down = 116,
    Right = 114,
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
