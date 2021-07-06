/++
    This module is designed to connect with graphic pipelines, load libraries necessary for the engine, and the like. 
    The most important thing is to initialize it at the beginning.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.runtime;

/// Struct library loader
struct LibraryLoader
{
    bool openAL = true; /// OpenAL
    bool freeType = true; /// FreeType
    version(Posix) bool glx = true; /// GLX
}

enum NoLibrary = LibraryLoader(false,false); /// Without library
enum AllLibrary = LibraryLoader(true,true); /// With all library

version(Posix)
{
    __gshared bool _glxIsLoad = false;

    /// Is load glx library
    bool glxIsLoad() @trusted
    {
        return _glxIsLoad;
    }
}

__gshared TidaRuntime _runtime;

/// Runtime instance.
TidaRuntime runtime() @trusted
{
    return _runtime;
}

/++
    The main functions of the runtime that should be.
+/
interface ITidaRuntime
{
    /++
        Loads dynamic libraries that will be needed into memory.
    +/
    void loadLibraries(LibraryLoader libstr) @trusted;

    /++
        Terminates the program immediately.

        Params:
            errorCode = Terminates the program immediately.
    +/
    final void terminate(ubyte errorCode) @trusted
    {
        import core.stdc.stdlib : exit;

        exit(errorCode);
    }

    /// Program arguments.
    string[] args() @safe;
}

version(Posix)
{
    enum XDGSession
    {
        Undefined,
        X11,
        Wayland
    }

    __gshared XDGSession _sessionType = XDGSession.Undefined;

    XDGSession sessionType() @trusted
    {
        return _sessionType;
    }
}
/++
    Runtime on Linux. Used to connect to the x11 server and initialize the runtime, load libraries and its components.
+/
version(Posix)
class TidaRuntime : ITidaRuntime
{
    import tida.x11;
    import tida.sound.al;
    import std.process;

    private
    {
        Display* xDisplay;

        int xDisplayID;

        string[] mainArguments;
        Device device;
    }

    /++
        Initializes a runtime by connecting to the windowing server and opening libraries.

        Params:
            args = Program arguments.
            libstr = Library struct.
    +/
    static void initialize(string[] args,LibraryLoader libstr = AllLibrary) @trusted
    {
        _runtime = new TidaRuntime(args);

        if(sessionType == XDGSession.Undefined)
        {
            auto env = environment.get("XDG_SESSION_TYPE");
            if(env == "wayland") {
                _sessionType = XDGSession.Wayland;
            } else {
                _sessionType = XDGSession.X11;
            }
        }

        runtime.loadLibraries(libstr);

        if(sessionType == XDGSession.X11)
        {
            if(libstr.glx) runtime.xDisplayOpen();
        } else {
            
        }
    }

    override void loadLibraries(LibraryLoader libstr) @trusted
    {
        import tida.graph.text;

        try
        {
            version(Dynamic_GLX)
            {
                if(libstr.glx) {
                    GLXLoadLibrary();

                    _glxIsLoad = true;
                }
            }
        }catch(Exception e)
        {
            _glxIsLoad = false;
        }finally
        {
            if(libstr.freeType) FreeTypeLoad();

            if(libstr.openAL) {
                InitSoundLibrary();
                device = new Device();
                device.open();
            }
        }
    }

    /++
        Writes program arguments to global memory for later use.

        Params:
            mainArguments = Program arguments.
    +/
    this(string[] mainArguments) @safe
    {
        this.mainArguments = mainArguments;
    }

    override string[] args() @safe
    {
        return mainArguments;
    }

    private void xDisplayOpen() @trusted
    {
        import std.exception : enforce;

        xDisplay = XOpenDisplay(null);

        enforce(xDisplay, "Failed to connect to x11 server!");

        xDisplayID = DefaultScreen(xDisplay);
    }

    /++
        Gives the main window to the window system.
    +/
    Window rootWindow() @trusted @property nothrow
    {
        return RootWindow(xDisplay, xDisplayID);
    }

    /++
        Gives an instance of the connection to the x11 server.
    +/
    Display* display() @trusted @property nothrow
    {
        return xDisplay;
    }

    /++
        Gives an identifier to the display.
    +/
    int displayID() @trusted @property nothrow
    {
        return xDisplayID;
    }

    void closeDisplay() @trusted @property nothrow
    {
        if(xDisplay !is null) XCloseDisplay(xDisplay);
    }

    ~this() 
    {
        this.closeDisplay();
    } 
}

/++
    Runtime for working with WinAPI. Also, downloads the required libraries.
+/
version(Windows)
class TidaRuntime : ITidaRuntime
{
    import tida.winapi, tida.sound.al;

    pragma(lib,"opengl32.lib");

    private
    {
        string[] mainArguments;

        HINSTANCE hInstance;
        Device device;
    }

    /++
        Initializes a runtime by connecting to the windowing server and opening libraries.

        Params:
            args = Program arguments.
            libstr = Library struct.
    +/
    static void initialize(string[] args,LibraryLoader libstr = AllLibrary) @trusted
    {
        _runtime = new TidaRuntime(args);

        runtime.instanceOpen();
        runtime.loadLibraries(libstr);
    }

    override void loadLibraries(LibraryLoader libstr) @trusted
    {
        import tida.graph.text;

        if(libstr.freeType) FreeTypeLoad();

        if(libstr.openAL) {
            InitSoundLibrary();
            device = new Device();
            device.open();
        }
    }

    /++
        Writes program arguments to global memory for later use.

        Params:
            mainArguments = Program arguments.
    +/
    this(string[] mainArguments) @safe
    {
        this.mainArguments = mainArguments;
    }

    override string[] args() @safe
    {
        return mainArguments;
    }

    private void instanceOpen() @trusted
    {
        import std.exception : enforce;

        hInstance = GetModuleHandle(null);

        ShowWindow(GetConsoleWindow(), SW_HIDE);

        enforce(hInstance, "hInstance is not open!");
    }

    /// Returns an instance for working with WinAPI functions.
    HINSTANCE instance() @safe nothrow
    {
        return hInstance;
    }
}