/++
    Runtime module. Serves to save some globally significant variables in the library.

    To create a runtime, you just need to call one function for this:
    ---
    TidaRuntime.initialize(args);
    ---

    So it will automatically remember the program arguments and create all the 
    conditions for creating a window.

    Authors: TodNaz
    License: MIT
+/
module tida.runtime;

version(WebAssembly)
{
    public import tida.betterc.runtime;
}
else:

__gshared TidaRuntime __runtime = null;

/// 
public TidaRuntime runtime() @trusted nothrow
{
    return __runtime;
}

/++
    Ranttime. Required to create windows.
+/
public class TidaRuntime
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

    import tida.graph.text, tida.sound.al;

    private
    {
        string[] mainArguments;

        version(Posix)
        {
            Display* _xDisplay;
            int _xDisplayID;
        }

        version(Windows)
        {
            HINSTANCE _wHInstance;
        }

        Device device;
    }

    this(string[] args) @safe
    {
        mainArguments = args;

        FreeTypeLoad();
        initSoundLibrary();
        device = new Device();
    }

    /++
        Creates and initializes a runtime for the program.
    +/
    static void initialize(string[] args = []) @trusted
    {
        __runtime = new TidaRuntime(args);

        version(Posix) {
            GLXLoadLibrary();
            
            __runtime.xDisplayOpen();
        }

        version(Windows) {
            __runtime.wInstanceOpen();
        }
    }

    /// Returns the arguments that were passed at runtime.
    public string[] args() @safe @property nothrow
    {
        return mainArguments;
    }

    /// Returns a display open in x11 environment.
    version(Posix) public Display* display() @trusted @property nothrow
    {
        return _xDisplay;
    }

    /// Returns a display identificator.
    version(Posix) public int displayID() @safe @property nothrow
    {
        return _xDisplayID;
    }

    /// Opens the display in x11 environment.
    version(Posix) public void xDisplayOpen() @trusted @property nothrow
    {
        _xDisplay = XOpenDisplay(null);
        _xDisplayID = DefaultScreen(_xDisplay);
    }

    /// Returns an instance obtained in a Windows environment.
    version(Windows) public HINSTANCE hInstance() @trusted @property nothrow
    {
        return _wHInstance;
    }

    /// Gets an instance for working with WinAPI.
    version(Windows) public void wInstanceOpen() @trusted @property nothrow
    {
        _wHInstance = GetModuleHandle(null);
    }
}