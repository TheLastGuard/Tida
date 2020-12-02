/++
	Module for importing x11 libraries.

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