/++
    Module for drawing in a window using opengl or processor.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.render;

/++
    What type of rendering.
+/
enum BlendMode {
    noBlend, // Without alpha channel
    Blend /// With an alpha channel.
};

/// Rendering type
enum RenderType
{
    OpenGL, ///
    Soft ///
}

/++
    Object for rendering objects.
+/
interface IRenderer
{
    import tida.vector, tida.color, tida.graph.drawable, tida.graph.camera, tida.graph.text;

    /++
        Updates the rendering surface if, for example, the window is resized.
    +/
    void reshape() @safe;

    ///Camera for rendering.
    void camera(Camera camera) @safe @property;

    /// Camera for rendering.
    Camera camera() @safe @property;

    /++
        Drawing a point.

        Params:
            vec = Point position.
            color = Point color.
    +/
    void point(Vecf vec,Color!ubyte color) @safe;

    /++
        Line drawing.

        Params:
            points = Tops of lines.
            color = Line color.
    +/
    void line(Vecf[2] points,Color!ubyte color) @safe;

    /++
        Drawing a rectangle.

        Params:
            position = Rectangle position.
            width = Rectangle width.
            height = Rectangle height.
            color = Rectangle color.
            isFill = Whether to fill the rectangle with color.
    +/
    void rectangle(Vecf position,int width,int height,Color!ubyte color,bool isFill) @safe;

    /++
        Drawning a circle.

        Params:
            position = Circle position.
            radious = Circle radious.
            color = Circle color.
            isFill = Whether to fill the circle with color.
    +/
    void circle(Vecf position,float radious,Color!ubyte color,bool isFill) @safe;

    /// Cleans the surface by filling it with color.
    void clear() @safe;

    /// Outputs the buffer to the window.
    void drawning() @safe;

    /// Gives the type of render.
    RenderType type() @safe;

    /// Set the coloring method. Those. with or without alpha blending.
    void blendMode(BlendMode mode) @safe;

    /// The color to fill when clearing.
    void background(Color!ubyte background) @safe @property;

    /// ditto
    Color!ubyte background() @safe @property;

    /++
        Renders an object.

        See_Also: `tida.graph.drawable`.
    +/
    final void draw(IDrawable drawable,Vecf position) @safe
    {
        position -= camera.port.begin;
        drawable.draw(this, position);
    }

    /// ditto
    final void drawEx(IDrawableEx drawable,Vecf position,float angle,Vecf center,Vecf size,ubyte alpha) @safe
    {
        position -= camera.port.begin;
        drawable.drawEx(this, position, angle, center, size, alpha);
    }

    /// ditto
    final void drawColor(IDrawableColor drawable,Vecf position,Color!ubyte color) @safe
    {
        position -= camera.port.begin;
        drawable.drawColor(this, position, color);
    }

    /++
        Renders symbols.

        Params:
            symbols = Symbol's.
            position = Symbols renders position.
    +/
    final void draw(Symbol[] symbols,Vecf position) @safe
    {
        position.y += (symbols[0].size + (symbols[0].size / 2)); 

        foreach(s; symbols) 
        {
            if(s.image !is null)
            {
                if(!s.image.isTexture)
                    s.image.fromTexture();

                drawColor(s.image,position - Vecf(0,s.position.y),s.color);
            }
            
            position.x += (s.advance.intX) + s.position.x;
        }
    }
}

class GLRender : IRenderer
{
    import tida.window, tida.color, tida.vector, tida.graph.camera, tida.shape, tida.graph.gl;
    import std.conv : to;

    private
    {
        IWindow window;
        Color!ubyte _background;
        Camera _camera;
        RenderType _type = RenderType.OpenGL;
    }

    this(IWindow window) @safe
    {
        this.window = window;

        _camera = new Camera();

        _camera.shape = Shape.Rectangle(Vecf(0,0),Vecf(window.width,window.height));
        _camera.port  = Shape.Rectangle(Vecf(0,0),Vecf(window.width,window.height));

        reshape();

        blendMode(BlendMode.Blend);
    }

    override void reshape() @safe
    {
        GL.viewport(0,0, window.width, window.height);

        clear();

        GL.matrixMode(GL_PROJECTION);
        GL.loadIdentity();

        GL.ortho(0.0, _camera.port.end.x, _camera.port.end.y, 0.0, -1.0, 1.0);

        GL.matrixMode(GL_MODELVIEW);
        GL.loadIdentity();
    }
    
    override void camera(Camera camera) @safe
    in(camera,"Camera is no allocated!")
    do
    {
        _camera = camera;
    }

    override Camera camera() @safe
    {
        return _camera;
    }

    override void background(Color!ubyte color) @safe @property
    {
        GL.clearColor = color;

        _background = color;
    }

    override Color!ubyte background() @safe @property
    {
        return _background;
    }

    override void point(Vecf position,Color!ubyte color) @safe
    {
        GL.color = color;

        GL.draw!Points({
            GL.vertex(position - _camera.port.begin);
        });
    }

    override void rectangle(Vecf position,int width,int height,Color!ubyte color,bool isFill) @safe
    {
        position -= _camera.port.begin;

        GL.color = color;

        if(isFill) 
        {
            GL.draw!Rectangle({
                GL.vertex(position);
                GL.vertex(position + Vecf(width,0));
                GL.vertex(position + Vecf(width,height));
                GL.vertex(position + Vecf(0,height));
            });
        }else 
        {
            GL.draw!Lines({
                GL.vertex(position);
                GL.vertex(position + Vecf(width,0));

                GL.vertex(position + Vecf(width,0));
                GL.vertex(position + Vecf(width,height));

                GL.vertex(position + Vecf(width,height));
                GL.vertex(position + Vecf(0,height));

                GL.vertex(position + Vecf(0,height));
                GL.vertex(position);
            });
        }
    }

    override void line(Vecf[2] points,Color!ubyte color) @safe
    {
        auto ps = points.dup;

        ps[0] -= _camera.port.begin;
        ps[1] -= _camera.port.begin;

        GL.color = color;

        GL.draw!Lines({
            GL.vertex(ps[0]);
            GL.vertex(ps[1]);
        });
    }

    override void circle(Vecf position,float radious,Color!ubyte color,bool isFill) @safe
    {
        GL.color = color;

        if (isFill)
        {
            int x = 0;
            int y = cast(int) radious;

            int X1 = position.intX();
            int Y1 = position.intY();

            int delta = 1 - 2 * cast(int) radious;
            int error = 0;

            GL.draw!Lines({
                while (y >= 0)
                {
                    GL.vertex(Vecf(X1 + x, Y1 + y));
                    GL.vertex(Vecf(X1 + x, Y1 - y));

                    GL.vertex(Vecf(X1 - x, Y1 + y));
                    GL.vertex(Vecf(X1 - x, Y1 - y));

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
            });
        }
        else
        {
            int x = 0;
            int y = cast(int) radious;

            int X1 = position.intX();
            int Y1 = position.intY();

            int delta = 1 - 2 * cast(int) radious;
            int error = 0;

            GL.draw!Points({
                while (y >= 0)
                {
                    GL.vertex(Vecf(X1 + x, Y1 + y));
                    GL.vertex(Vecf(X1 + x, Y1 - y));
                    GL.vertex(Vecf(X1 - x, Y1 + y));
                    GL.vertex(Vecf(X1 - x, Y1 - y));


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
            });
        }
    }

    override void clear() @safe
    {
        GL.clear();
    }

    override void drawning() @safe
    {
        window.swapBuffers();
    }

    override RenderType type() @safe
    {
        return _type;
    }

    override void blendMode(BlendMode mode) @trusted
    {
        if(mode == BlendMode.Blend) {
            GL.enable(GL_BLEND);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        }else if(mode == BlendMode.noBlend) {
            GL.disable(GL_BLEND);
        }
    }
}

interface IPlane
{
    import tida.color, tida.window, tida.vector;

    void alloc(uint width,uint height) @safe;
    void clearPlane(Color!ubyte color) @safe;
    void putToWindow(IWindow window) @safe;
    void blendMode(BlendMode mode) @safe @property;
    void pointTo(Vecf position,Color!ubyte color) @safe;
    void viewport(int w,int h) @safe;
    void move(int x,int y) @safe;

    ubyte[] data() @safe @property;
}

version(Posix)
class Plane : IPlane
{
    import tida.x11, tida.color, tida.window, tida.runtime, tida.vector;

    private
    {
        GC context;
        XImage* ximage;

        tida.window.Window window;

        ubyte[] buffer;
        uint _width;
        uint _height;

        BlendMode bmode;
        uint _pwidth;
        uint _pheight;

        uint xput;
        uint yput;

        bool _isAlloc = true;
    }

    this(tida.window.Window window,bool isAlloc = true) @trusted
    {
        this.window = window;

        _isAlloc = isAlloc;

        if(_isAlloc) {
            context = XCreateGC(runtime.display, window.handle, 0, null);
        }
    }

    override ubyte[] data() @safe @property
    {
        return buffer;
    }

    override void alloc(uint width,uint height) @trusted
    {
        _width = width;
        _height = height;

        buffer = new ubyte[](_width * _height * 4);

        if(_isAlloc)
        {
            if(ximage !is null) {
                XFree(ximage);
                ximage = null;
            }

            Visual* visual = (cast(tida.window.Window) window).getVisual();
            int depth = (cast(tida.window.Window) window).getDepth();

            ximage = XCreateImage(runtime.display, visual, depth,
                ZPixmap, 0, cast(char*) buffer, _width, _height, 32, 0);

            if(ximage is null) throw new Exception("[X11] XImage is not create!");
        }
    }

    override void viewport(int w,int h) @safe
    {
        _pwidth = w;
        _pheight = h;
        alloc(_width,_height);
    }

    override void move(int x,int y) @safe
    {
        xput = x;
        yput = y;
    }

    override void clearPlane(Color!ubyte color) @safe
    {
        for(size_t i = 0; i < _width * _height * 4; i += 4)
        {
            buffer[i] = color.b;
            buffer[i+1] = color.g;
            buffer[i+2] = color.r; 
        }
    }

    override void putToWindow(IWindow window) @trusted
    {
        if(_isAlloc)
        {
            XPutImage(runtime.display, (cast(tida.window.Window) window).handle, context, ximage,
                0, 0, 0, 0, _width, _height);

            XSync(runtime.display, False);
        }
    }

    override void blendMode(BlendMode mode) @safe @property
    {
        bmode = mode;
    }

    override void pointTo(Vecf position,Color!ubyte color) @safe @property
    {
        import std.conv : to;

        position = position - Vecf(xput,yput);

        if(position.x.to!int >= _width || position.y.to!int >= _height || 
           position.x.to!int < 0 || position.y.to!int < 0)
            return;

        if(_pwidth == _width && _pheight == _height)
        {
            auto pos = ((_width * position.y.to!int) + position.x.to!int) * 4;

            if(bmode == BlendMode.Blend) 
                color.colorize!Alpha(rgba(buffer[pos+2],buffer[pos+1],buffer[pos],255));

            buffer[pos] = color.b;
            buffer[pos+1] = color.g;
            buffer[pos+2] = color.r;
        }else
        {
            import tida.graph.each;

            auto scaleWidth = cast(double) _pwidth / cast(double) _width;
            auto scaleHeight = cast(double) _pheight / cast(double) _height;

            int w = cast(int) _width / _pwidth + 1;
            int h = cast(int) _height / _pheight + 1;

            import std.stdio;

            position =  Vecf(position.x / scaleWidth, position.y / scaleHeight);

            Color!ubyte original = color;

            foreach(ix, iy; Coord(position.x.to!int + w,position.y.to!int + h,
                                  position.x.to!int,position.y.to!int))
            {
                auto pos = (iy * _width) + ix;
                pos *= 4;

                color = original;
                if(bmode == BlendMode.Blend)
                    color.colorize!Alpha(rgba(buffer[pos+2],buffer[pos+1],buffer[pos],255));

                if(pos < buffer.length)
                {
                    buffer[pos] = color.b;
                    buffer[pos+1] = color.g;
                    buffer[pos+2] = color.r;
                }
            }
        }
    }
}

version(Windows)
class Plane : IPlane
{
    import tida.winapi, tida.window, tida.vector, tida.color;

    private
    {
        PAINTSTRUCT paintstr;
        HDC hdc;
        HDC pdc;
        HBITMAP wimage = null;

        tida.window.Window window;
        
        ubyte[] buffer;
        uint _width;
        uint _height;
        Color!ubyte _background;
        BlendMode bmode;

        int _pwidth;
        int _pheight;
        int xput;
        int yput;

        bool _isAlloc = true;
    }

    this(tida.window.Window window,bool isAlloc = true) @trusted
    {
        this.window = window;
        _isAlloc = isAlloc;
    }

    void recreateBitmap() @trusted
    {
        if(wimage !is null) DeleteObject(wimage);
        if(hdc is null) hdc = GetDC((cast(Window) window).handle);

        wimage = CreateBitmap(_width,_height,1,32,cast(LPBYTE) buffer);

        assert(wimage,"[WINAPI] Bitmap is not create!");

        pdc = CreateCompatibleDC(hdc);

        SelectObject(pdc, wimage);
    }

    override ubyte[] data() @safe @property
    {
        return buffer;
    }

    override void alloc(uint width,uint height) @trusted
    {
        import std.algorithm : fill;

        _width = width;
        _height = height;

        buffer = new ubyte[](_width * _height * 4);
    }

    override void viewport(int w,int h) @safe
    {
        _pwidth = w;
        _pheight = h;
    }

    override void move(int x,int y) @safe
    {
        xput = x;
        yput = y;
    }

    override void clearPlane(Color!ubyte color) @safe
    {
        for(size_t i = 0; i < _width * _height * 4; i += 4)
        {
            buffer[i] = color.b;
            buffer[i+1] = color.g;
            buffer[i+2] = color.r; 
            buffer[i+3] = 255;
        }
    }

    override void putToWindow(IWindow window) @trusted
    {
        if(_isAlloc)
        {
            recreateBitmap();
            BitBlt(hdc, 0, 0, _width, _height, pdc, 0, 0, SRCCOPY);
        }
    }

    override void blendMode(BlendMode mode) @safe @property
    {
        bmode = mode;
    }

    override void pointTo(Vecf position,Color!ubyte color) @safe @property
    {
        import std.conv : to;

        position = position - Vecf(xput,yput);

        if(position.x.to!int >= _width || position.y.to!int >= _height || 
           position.x.to!int < 0 || position.y.to!int < 0)
            return;

        if(_pwidth == _width && _pheight == _height)
        {
            auto pos = ((_width * position.y.to!int) + position.x.to!int) * 4;

            if(bmode == BlendMode.Blend) 
                color.colorize!Alpha(rgba(buffer[pos+2],buffer[pos+1],buffer[pos],255));

            buffer[pos] = color.b;
            buffer[pos+1] = color.g;
            buffer[pos+2] = color.r;
        }else
        {
            import tida.graph.each;

            auto scaleWidth = cast(double) _pwidth / cast(double) _width;
            auto scaleHeight = cast(double) _pheight / cast(double) _height;

            int w = cast(int) _width / _pwidth + 1;
            int h = cast(int) _height / _pheight + 1;

            import std.stdio;

            position =  Vecf(position.x / scaleWidth, position.y / scaleHeight);

            foreach(ix, iy; Coord(position.x.to!int + w,position.y.to!int + h,
                                  position.x.to!int,position.y.to!int))
            {
                auto pos = (iy * _width) + ix;
                pos *= 4;

                if(pos < buffer.length)
                {
                    buffer[pos] = color.b;
                    buffer[pos+1] = color.g;
                    buffer[pos+2] = color.r;
                }
            }
        }
    }
}

class Software : IRenderer
{
    import tida.window, tida.color, tida.vector, tida.graph.camera, tida.shape;
    import std.conv : to;

    protected
    {
        IWindow window;
        Color!ubyte _background;
        Camera _camera;
        RenderType _type = RenderType.Soft;
        IPlane plane;
    }

    this(IWindow window,bool _isAlloc = true) @safe
    {
        this.window = window;

        plane = new Plane(cast(Window) window, _isAlloc);

        _camera = new Camera();

        if(window !is null)
        {
            _camera.shape = Shape.Rectangle(Vecf(0,0),Vecf(window.width,window.height));
            _camera.port  = Shape.Rectangle(Vecf(0,0),Vecf(window.width,window.height));
        }

        plane.blendMode(BlendMode.Blend);

        reshape();
    }

    this(IPlane plane) @safe
    {
        this(null, false);

        this.plane = plane;

        plane.blendMode(BlendMode.Blend);
    }

    override RenderType type() @safe
    {
        return _type;
    }

    override void reshape() @safe
    {
        import std.conv : to;

        plane.alloc(_camera.shape.end.x.to!int,_camera.shape.end.y.to!int);
        plane.viewport(_camera.port.end.y.to!int,_camera.port.end.y.to!int);
    }    

    override void camera(Camera camera) @safe
    in(camera,"Camera is no allocated!")
    do
    {
        _camera = camera;
    }

    override Camera camera() @safe
    {
        return _camera;
    }

    override void background(Color!ubyte color) @safe @property
    {
        _background = color;
    }

    override Color!ubyte background() @safe @property
    {
        return _background;
    }

    override void point(Vecf position,Color!ubyte color) @safe
    {
        plane.pointTo(position,color);
    }

    override void rectangle(Vecf position,int width,int height,Color!ubyte color,bool isFill) @safe
    {
        import tida.graph.each;

        if(isFill)
        {
            foreach(ix,iy; Coord(width.to!int,height.to!int))
            {
                point(Vecf(position.x.to!int + ix,position.y.to!int + iy),color);
            }
        }else
        {
            foreach(ix,iy; Coord(width.to!int,height.to!int))
            {
                point(Vecf(position.x.to!int + ix,position.y.to!int),color);
                point(Vecf(position.x.to!int + ix,position.y.to!int + height.to!int),color);
 
                point(Vecf(position.x.to!int,position.y.to!int + iy),color);
                point(Vecf(position.x.to!int + width.to!int,position.y.to!int + iy),color);
            }
        }
    }

    override void line(Vecf[2] points,Color!ubyte color) @safe
    {
        import std.math : abs;

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

    override void circle(Vecf position,float radious,Color!ubyte color,bool isFill) @safe
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

    override void clear() @safe
    {
        import std.conv : to;

        plane.move(_camera.port.begin.x.to!int,_camera.port.begin.y.to!int);
        plane.clearPlane(_background);
    }

    override void drawning() @safe
    {
        plane.putToWindow(window);
    }

    override void blendMode(BlendMode mode) @safe
    {
        plane.blendMode(mode);
    }

    IPlane getPlane() @safe
    {
        return plane;
    }
}

import tida.window;
import tida.graph.gl;

/++
    Creates a render depending on the situation. If graphics output is available through the video card, 
    it will create a render for OpenGL, otherwise it will create a render subprocessor.

    Params:
        window = Window.
+/
IRenderer CreateRenderer(IWindow window) @safe
{
    IRenderer render;

    try
    {
        GL.initialize();

        render = new GLRender(window);
    }catch(Exception e)
    {
        render = new Software(window);
    }

    return render;
}