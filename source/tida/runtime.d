/++
    This module is designed to connect with graphic pipelines, load libraries necessary for the engine, and the like. 
    The most important thing is to initialize it at the beginning.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.runtime;

import tida.templates;

/// Struct library loader
struct LibraryLoader
{
    bool openAL = true; /// OpenAL
    bool freeType = true; /// FreeType
    version(Posix) bool glx = true; /// GLX
}

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

/++
    Runtime on Linux. Used to connect to the x11 server and initialize the runtime, load libraries and its components.
+/
version(Posix)
class TidaRuntime : ITidaRuntime
{
    import tida.x11;
    import dglx.glx;
    import tida.sound.al;

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
    static void initialize(string[] args,LibraryLoader libstr = LibraryLoader()) @trusted
    {
        _runtime = new TidaRuntime(args);
        
        runtime.loadLibraries(libstr);
        if(libstr.glx) runtime.xDisplayOpen();
    }

    override void loadLibraries(LibraryLoader libstr) @trusted
    {
        import tida.graph.text;

        try
        {
            if(libstr.glx) {
                GLXLoadLibrary();

                _glxIsLoad = true;
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
        xDisplay = XOpenDisplay(null);

        assert(xDisplay,"Failed to connect to x11 server!");

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
}

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

    static void initialize(string[] args,LibraryLoader libstr = LibraryLoader()) @trusted
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
        hInstance = GetModuleHandle(null);

        assert(hInstance, "hInstance is not open!");
    }

    HINSTANCE instance() @safe nothrow
    {
        return hInstance;
    }
}