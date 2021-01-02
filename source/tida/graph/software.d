module tida.graph.software;

public class Software
{
    version(Posix) import tida.x11;
    import tida.runtime;
    import tida.window;
    import tida.color;
    import tida.vector;
    import tida.exception;
    import tida.graph.blend;

    private
    {
        version(Posix)
        {
            GC gcontext;
            XImage* ximage;
        }

        tida.window.Window window;
        
        ubyte[] buffer;
        uint _width;
        uint _height;
        Color!ubyte _background;
        BlendMode bmode;
    }

    this(tida.window.Window window) @trusted
    {
        this.window = window;

        version(Posix)
        {
            gcontext = XCreateGC(runtime.display, window.xWindow, 0, null);

            if(gcontext is null) throw new SoftwareException(SoftwareError.noGC,"[X11] GC is not create!");

            XMapRaised(runtime.display, window.xWindow);
        }
    }

    version(Posix) public void xClear() @trusted
    {
        //XClearWindow(runtime.display, window.xWindow);
    }

    version(Posix) XImage* xCreateFramebuffer() @trusted
    {
        XImage* ximage = XCreateImage(runtime.display, window.xGetVisual(), window.xGetDepth(),
            ZPixmap, 0, cast(char*) buffer, _width, _height, 32, 0);

        if(ximage is null) throw new SoftwareException(SoftwareError.flushError, "[X11] XImage is not create!");

        return ximage;
    }

    version(Posix) public void xFlush() @trusted
    {
        XPutImage(runtime.display, window.xWindow, gcontext, ximage, 0, 0, 0, 0, _width, _height);

        XSync(runtime.display, False);
    }

    version(Posix) public void xBackground(Color!ubyte color) @trusted
    {
        XSetBackground(runtime.display, gcontext, color.conv!ulong(PixelFormat.RGB));
    }

    public void background(Color!ubyte color) @safe
    {
        _background = color;
        version (Posix) xBackground(color);
    }

    public void blendMode(BlendMode mode) @safe
    {
        bmode = mode;
    }

    public void clear() @safe
    {
        version(Posix) xClear();

        for(size_t i = 0; i < _width * _height * 4; i += 4)
        {
            buffer[i] = _background.b;
            buffer[i+1] = _background.g;
            buffer[i+2] = _background.r; 
        }
    }

    public void copy(ref ubyte[] arr,Vecf begin,Vecf end) @safe
    {
        
    }

    public void viewport(uint newWidth,uint newHeight) @safe
    {
        _width = newWidth;
        _height = newHeight;

        realloc();
    }

    public void realloc() @trusted
    {
        buffer = new ubyte[](_width * _height * 4);

        version(Posix)
        {
            if(ximage !is null) XDestroyImage(ximage);
            ximage = xCreateFramebuffer();
        }
    }

    public void point(Vecf position,Color!ubyte color) @safe
    {
        import std.conv : to;

        if(position.x.to!int >= _width || position.y.to!int >= _height || 
           position.x.to!int < 0 || position.y.to!int < 0)
            return;

        auto pos = ((_width * position.y.to!int) + position.x.to!int) * 4;

        color.colorize!Alpha(rgba(buffer[pos+2],buffer[pos+1],buffer[pos],255));

        buffer[pos] = color.b;
        buffer[pos+1] = color.g;
        buffer[pos+2] = color.r;
    }

    public void line(Vecf[2] points,Color!ubyte color) @safe
    {
        import std.math : abs;
        import std.conv : to;

        int x1 = points[0].x.to!int;
        int y1 = points[0].y.to!int;
        const x2 = points[1].x.to!int;
        const y2 = points[1].y.to!int;

        const deltaX = abs(x2 - x1);
        const deltaY = abs(y2 - y1);
        const signX = x1 < x2 ? 1 : -1;
        const signY = y1 < y2 ? 1 : -1;

        int error = deltaX - deltaY;

        while(x1 != x2 || y1 != y2) {
            point(Vecf(x1,y1),color);

            const int error2 = error * 2;

            if(error2 > -deltaY) {
                error -= deltaY;
                x1 += signX;
            }

            if(error2 < deltaX) {
                error += deltaX;
                y1 += signY;
            }
        }
    }

    public void circle(Vecf position,float radious,Color!ubyte color,bool isFill) @safe
    {
        int x = 0;
        int y = cast(int) radious;

        int X1 = position.intX();
        int Y1 = position.intY();

        int delta = 1 - 2 * cast(int) radious;
        int error = 0;

        while (y >= 0)
        {
            if(isFill)
            {
                line([Vecf(X1 + x, Y1 + y),Vecf(X1 + x, Y1 - y)],color);
                line([Vecf(X1 - x, Y1 + y),Vecf(X1 - x, Y1 - y)],color);
            }else
            {
                point(Vecf(X1 + x, Y1 + y),color);
                point(Vecf(X1 + x, Y1 - y),color);
                point(Vecf(X1 - x, Y1 + y),color);
                point(Vecf(X1 - x, Y1 - y),color);
            }

            error = 2 * (delta + y) - 1;
            if ((delta < 0) && (error <= 0))
            {
                delta += 2 * ++x + 1;
                continue;
            }
            if ((delta > 0) && (error > 0))
            {
                delta -= 2 * --y + 1;
                continue;
            }
            delta += 2 * (++x - --y);
        }
    }

    public void rectangle(Vecf position,float width,float height,Color!ubyte color,bool isFill) @safe
    {
        import std.conv : to;

        if(isFill)
        {
            foreach(ix; 0 .. cast(int) width)
            {
                foreach(iy; 0 .. cast(int) height)
                {
                    point(Vecf(position.x.to!int + ix,position.y.to!int + iy),color);
                }
            }
        }else
        {
            foreach(ix; 0 .. cast(int) width)
            {
                point(Vecf(position.x.to!int + ix,position.y.to!int),color);
                point(Vecf(position.x.to!int + ix,position.y.to!int + height.to!int),color);
            }

            foreach(iy; 0 .. cast(int) height)
            {
                point(Vecf(position.x.to!int,position.y.to!int + iy),color);
                point(Vecf(position.x.to!int + width.to!int,position.y.to!int + iy),color);
            }
        }
    }

    public auto getBuffer() @safe
    {
        return buffer;
    }

    public auto getWidth() @safe
    {
        return _width;
    }

    public auto getHeight() @safe
    {
        return _height;
    }

    public void flush() @safe
    {
        version(Posix) xFlush();
    }

    ~this() @trusted
    {
        version(Posix)
        {
            XFreeGC(runtime.display, gcontext);

            buffer = null;
        }
    }
}