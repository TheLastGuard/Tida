/++
    

    Authors: TodNaz
    License: MIT
+/
module tida.event;

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

    import tida.window;
    import tida.runtime;

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

    public bool update() @safe
    {
        version(Posix) return xUpdate();
        version(Windows) return wUpdate();
    }

    version(Windows) public bool wUpdate() @trusted
    {
        TranslateMessage(&msg); 
        DispatchMessage(&msg);

        return PeekMessage(&msg, window.wWindow,0,0,PM_REMOVE) != 0;
    }

    version(Posix) public bool xUpdate() @trusted
    {
        auto pen = XPending(runtime.display);
        
        if(pen != 0)
            XNextEvent(runtime.display, &event);

        return pen != 0;
    }  

    version(Posix) public bool xIsQuit() @trusted
    {
        return event.xclient.data.l[0] == destroyWindowEvent;
    }

    version(Windows) public bool wIsQuit() @trusted
    {
        return msg.message == WM_QUIT || msg.message == WM_CLOSE || 
               (msg.message == WM_SYSCOMMAND && msg.wParam == SC_CLOSE);
    }

    public bool isQuit() @safe
    {
        version(Posix) return xIsQuit();
        version(Windows) return wIsQuit();
    }
}