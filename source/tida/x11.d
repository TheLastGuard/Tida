/++
	Module for importing x11 libraries.

    This module is needed, for example, if the way of loading such a 
    library is changed, then the code in another project can be left unchanged.

	Authors: TodNaz
	License: MIT
+/
module tida.x11;

version(Posix):

public
{
    import x11.Xlib;
    import x11.X;
    import x11.extensions.Xrandr;
    import x11.Xutil;
}