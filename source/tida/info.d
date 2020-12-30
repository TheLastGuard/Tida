/++
    Module for system information.

    Authors: TodNaz
    License: MIT
+/
module tida.info;

/++
    Class for monitor information
+/
public class Display
{
    import tida.runtime;

    version(Posix)
    {
        import tida.x11;
    }

    version(Windows)
    {
        import core.sys.windows.windows;
    }

    public
    {
        uint width; /// Display width
        uint height; /// Display height
    }

    /++
        Returns the width of the monitor.
    +/
    static uint getWidth(uint screenID = 0) @trusted 
    {
        version(Posix)
        {
            XRRScreenResources* screens = XRRGetScreenResources(runtime.display,
                DefaultRootWindow(runtime.display));
            XRRCrtcInfo* info = null;

            assert(screenID < screens.ncrtc);

            info = XRRGetCrtcInfo(runtime.display,screens,screens.crtcs[screenID]);

            int of = info.width;

            XRRFreeScreenResources(screens);

            return of;
        }

        version(Windows)
        {
            RECT desktop;
               
            HWND hDesktop = GetDesktopWindow();

            GetWindowRect(hDesktop, &desktop);

            return desktop.right;
        }
    }

    /++
        Returns the height of the monitor.
    +/
    static uint getHeight(uint screenID = 0) @trusted
    {
        version(Posix)
        {
            XRRScreenResources* screens = XRRGetScreenResources(runtime.display,
                DefaultRootWindow(runtime.display));
            XRRCrtcInfo* info = null;

            assert(screenID < screens.ncrtc);

            info = XRRGetCrtcInfo(runtime.display,screens,screens.crtcs[screenID]);

            int of = info.height;

            return of;
        }

        version(Windows)
        {
            RECT desktop;
               
            HWND hDesktop = GetDesktopWindow();

            GetWindowRect(hDesktop, &desktop);

            return desktop.bottom;
        }
    }

    /++
        Returns information about the display.
    +/
    public static Display information(int screenID = 0) @safe
    {
        auto display = new Display();

        display.width = Display.getWidth(screenID);
        display.height = Display.getHeight(screenID);

        return display;
    }

    override string toString() @safe const
    {
        import std.conv : to;

        return "Display(width: "~width.to!string~",height: "~height.to!string~")";
    }
}

struct GPU
{
	import bindbc.opengl;
	import std.conv : to;

	static int totalMemory() @trusted @disable
	{
		int tm;
		glGetIntegerv(0x9048, &tm);
		
		return tm;
	}
	
	static int usedMemory() @trusted @disable
	{
		int cm;
		glGetIntegerv(0x9049, &cm);
		
		return cm;
	}
	
	static string vendor() @trusted
	{
		return glGetString(GL_VENDOR).to!string;
	}
	
	static string renderer() @trusted
	{
		return glGetString(GL_RENDERER).to!string;
	}
	
	static string versions() @trusted
	{
		return glGetString(GL_VERSION).to!string;
	}
}