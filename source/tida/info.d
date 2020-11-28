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
        import x11.Xlib;
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
            return XWidthOfScreen(ScreenOfDisplay(runtime.display,screenID));
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
            return XHeightOfScreen(ScreenOfDisplay(runtime.display,screenID));
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
    public static Display information() @safe
    {
        auto display = new Display();

        display.width = Display.getWidth();
        display.height = Display.getHeight();

        return display;
    }
}