/++
    Module for importing x11 libraries.

    This module is needed, for example, if the way of loading such a 
    library is changed, then the code in another project can be left unchanged.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.x11;

version(Posix):
public
{
    import x11.Xlib;
    import x11.X;
    import x11.extensions.Xrandr;
    import x11.Xutil;

    version(Dynamic_GLX) 
        import dglx.glx;
    else
        import glx.glx;
}

/++
    Returns an atom for handling events.

    Params:
        name = Atom name.
+/
Atom getAtom(string name) @trusted
{
    import tida.runtime;
    import std.string : toStringz;

    return XInternAtom(runtime.display, name.toStringz, 0);
}

/// Window Manager event structure
struct WMEvent
{
    import tida.runtime;

    public
    {
        Atom first; /// First atom
        Atom second; /// Second atom.
        int format; /// Format event.
        int mode; /// Mode event
        ubyte* data; /// Event data.
        size_t length; /// Event length data.
        Window window; /// Window event.
    }

    /// Send event in window manager.
    void send() @trusted
    {
        XChangeProperty(runtime.display, window, first, second, format,
                        mode, data, cast(int) length);
    }
}
