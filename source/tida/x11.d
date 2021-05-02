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
Atom GetAtom(string name)() @trusted
{
	import tida.runtime;

	return XInternAtom(runtime.display, name, 0);
}

struct WMEvent
{
	import tida.runtime;

	public
	{
		Atom first;
		Atom second;
		int format;
		int mode;
		ubyte* data;
		size_t length;
		Window window;
	}

	void send() @trusted
	{
		XChangeProperty(runtime.display, window, first, second, format,
                        mode, data, cast(int) length);
	}
}
