/++
A module for connecting to the window manager and also loading the necessary 
libraries, everything that does runtime, to which other objects can access 
the necessary objects.

$(LREF runtime) Gives access to runtime. Before that, you need to initialize the 
runtime with the $(HREF runtime/ITidaRuntime.initialize,ITidaRuntime.initialize)
function if it has not been initialized earlier.

The easiest way to initialize:
---
void main(string[] args) {
    TidaRuntime.initialize(args);
    ...
}
---

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.runtime;

__gshared TidaRuntime _runtimeObject;

/++
Global access to runtime. An object can be called from anywhere, 
but cannot be replaced.
+/
@property TidaRuntime runtime() @trusted
{
    return _runtimeObject;
}

enum : int
{
    OpenAL = 0, /// Open Audio Library
    FreeType, /// Free Type Library
    GLX, /// Graphics library X11
    EGL /// EGL library wayland
}

alias LibraryUnite = int; /// 

enum AllLibrary = [OpenAL, FreeType, GLX];
enum WithoutLibrary  = [GLX];

/++
The interface of interaction between the program and the window manager.
+/
interface ITidaRuntime
{
@safe:
    /++
    A function for loading external libraries that are needed when implementing
    internal functions.

    Params:
        libs =  What external libraries need to be loaded. 
                (allLibrary to load all external libraries,
                 WithoutLibrary in order not to load unnecessary 
                 external libraries.)

    Throws:
    $(OBJECTREF Exception) If the libraries were not installed on the machine 
    being started or they were damaged.
    +/
    void loadExternalLibraries(LibraryUnite[] libs);

    /++
    Connects to the window manager.

    Throws:
    $(OBJECTREF Exception) If the libraries were not installed on the machine 
    being started or they were damaged. And also if the connection to the 
    window manager was not successful (for example, there is no such component 
    in the OS or the connection to an unknown window manager is not supported).
    +/
    void connectToWndMng();

    /++
    Closes the session with the window manager.
    +/
    void closeWndMngSession();

    /++
    Arguments given to the program.
    +/
    @property string[] mainArguments();

    /++
    Accepts program arguments for subsequent operations with them.
    +/
    void acceptArguments(string[] arguments);

@trusted:
    /++
    Runtime initialization. It includes such stages as:
    1. Loading external libraries.
    2. Connection to the window manager.
    3. Preparation of objects for work.

    Params:
        arguments = Arguments given to the program.
        libs = What external libraries need to be loaded. 
                (allLibrary to load all external libraries,
                 WithoutLibrary in order not to load unnecessary 
                 external libraries.)

    Throws:
    $(OBJECTREF Exception) If the libraries were not installed on the machine
    being started or they were damaged. And also if the connection to the 
    window manager was not successful (for example, there is no such 
    component in the OS or the connection to an unknown window manager 
    is not supported).
    +/
    static final void initialize(   string[] arguments  = [], 
                                    LibraryUnite[] libs = AllLibrary)
    {
        _runtimeObject = new TidaRuntime();
        _runtimeObject.acceptArguments(arguments);
        _runtimeObject.loadExternalLibraries(libs);
        _runtimeObject.connectToWndMng();
    }
}

/++
The interface of interaction between the program and the window manager.
+/
version (Posix)
class TidaRuntime : ITidaRuntime
{
    import x11.X, x11.Xlib, x11.Xutil;
    import std.exception : enforce;
    import tida.sound : initSoundlibrary, Device;
    import tida.text : initFontLibrary;

    enum SessionType
    {
        unknown,
        x11,
        wayland
    }

    enum SessionWarning =
    "WARNING! The session is not defined. Perhaps she simply does not exist?";

private:
    Display* _display;
    int _displayID;
    string[] arguments;
    SessionType _session;
    Device _device;

public @trusted:
    this()
    {
        import std.process;
        import std.stdio : stderr, writeln;

        auto env = environment.get("XDG_SESSION_TYPE");
        if (env == "x11")
        {
            _session = SessionType.x11;
        } else
        if (env == "wayland")
        {
            _session = SessionType.wayland;
        } else
        {
            _session = SessionType.unknown;
            stderr.writeln(SessionWarning);
        }

    }

    override void loadExternalLibraries(LibraryUnite[] libs)
    {
        import dglx.glx : loadGLXLibrary;

        foreach (e; libs)
        {
            if (e == OpenAL)
            {
                initSoundlibrary();
                _device = new Device();
                _device.open();
            }
            else
            if (e == FreeType)
                initFontLibrary();
            else
            if (e == GLX) {
                if (_session == SessionType.x11)
                    loadGLXLibrary();
            }
        }
    }

    override void connectToWndMng()
    {
        this._display = XOpenDisplay(null);
        enforce!Exception(this._display,
        "Failed to connect to window manager.");

        this._displayID = DefaultScreen(this._display);
    }

    override void closeWndMngSession()
    {
        XCloseDisplay(this._display);
        this._display = null;
        this._displayID = 0;
    }

    override void acceptArguments(string[] arguments)
    {
        this.arguments = arguments;
    }

    @property override string[] mainArguments()
    {
        return this.arguments;
    }

    @property Window rootWindow()
    {
        return RootWindow(_display, _displayID);
    }
@safe:
    /// An instance for contacting the manager's server.
    @property Display* display()
    {
        return this._display;
    }

    /// Default screen number
    @property int displayID()
    {
        return this._displayID;
    }

    ~this()
    {
        closeWndMngSession();
    }
}

version(Windows)
class TidaRuntime : ITidaRuntime
{
    import core.sys.windows.windows;
    import std.exception : enforce;
    import tida.sound : initSoundlibrary, Device;
    import tida.text : initFontLibrary;

private:
    HINSTANCE hInstance;
    string[] arguments;
    Device _device;

public @trusted:
    override void loadExternalLibraries(LibraryUnite[] libs)
    {
        foreach (e; libs)
        {
            if (e == OpenAL)
            {
                _device = new Device();
                _device.open();
            }
            else
            if (e == FreeType)
                initFontLibrary();
        }
    }

    override void connectToWndMng()
    {
        this.hInstance = GetModuleHandle(null);
        ShowWindow(GetConsoleWindow(), SW_HIDE);

        enforce!Exception(this.hInstance, 
        "Failed to connect to window manager.");
    }

    override void closeWndMngSession()
    {
        this.hInstance = null;
    }

    override void acceptArguments(string[] arguments)
    {
        this.arguments = arguments;
    }

    @property override string[] mainArguments()
    {
        return this.arguments;
    }

@safe:
    @property HINSTANCE instance()
    {
        return this.hInstance;
    }
}
