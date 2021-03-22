/++
    Module for system information.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.info;

/++
    Information about the monitor.

    Example:
    ---
    auto size = new Monitor().size();
    ---
+/
interface IMonitor
{
    /// Monitor width
    uint width(uint screenID = 0) @safe @property;

    /// Monitor height
    uint height(uint screenID = 0) @safe @property;

    /// Monitor size
    final uint[2] size(uint screenID = 0) @safe @property
    {
        return [width, height];
    }
}

version(Posix)
class Monitor : IMonitor
{
    import tida.x11, tida.runtime;
    import std.exception : enforce;

    override uint width(uint screenID = 0) @trusted @property
    {
        XRRScreenResources* screens = XRRGetScreenResources(runtime.display,
            DefaultRootWindow(runtime.display));
        XRRCrtcInfo* info = null;

        enforce(screenID < screens.ncrtc);

        info = XRRGetCrtcInfo(runtime.display,screens,screens.crtcs[screenID]);

        int of = info.width;

        XRRFreeScreenResources(screens);

        return of;
    }

    override uint height(uint screenID = 0) @trusted @property
    {
        XRRScreenResources* screens = XRRGetScreenResources(runtime.display,
            DefaultRootWindow(runtime.display));
        XRRCrtcInfo* info = null;

        enforce(screenID < screens.ncrtc);

        info = XRRGetCrtcInfo(runtime.display,screens,screens.crtcs[screenID]);

        int of = info.height;

        return of;
    }
}

version(Windows)
class Monitor : IMonitor
{
    import tida.winapi, tida.runtime;

    override uint width(uint screenID = 0) @trusted @property
    {
        RECT desktop;
               
        HWND hDesktop = GetDesktopWindow();

        GetWindowRect(hDesktop, &desktop);

        return desktop.right;
    }

    override uint height(uint screenID = 0) @trusted @property
    {
        RECT desktop;
               
        HWND hDesktop = GetDesktopWindow();

        GetWindowRect(hDesktop, &desktop);

        return desktop.bottom;
    }
}