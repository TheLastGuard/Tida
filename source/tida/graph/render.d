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
    noBlend, /// Without alpha channel
    Blend /// With an alpha channel.
};

/// Rendering type
enum RenderType
{
    AUTO, ///
    OpenGL, ///
    Soft ///
}

/++
    Object for rendering objects.
+/
interface IRenderer
{
    import tida.vector, tida.color, tida.graph.drawable, tida.graph.camera, tida.graph.text;
    import tida.graph.shader;

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

    void triangle(Vecf[3] points,Color!ubyte color,bool isFill) @safe;

    void polygon(Vecf position,Vecf[] points,Color!ubyte color,bool isFill) @safe;

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

    ///
    void setShader(string name, Shader!Program program) @safe;

    ///
    Shader!Program getShader(string name) @safe;

    ///
    void currentShader(Shader!Program program) @safe @property; 

    ///
    Shader!Program currentShader() @safe @property;

    ///
    void resetShader() @safe;

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
    final void drawEx(IDrawableEx drawable,Vecf position,float angle,Vecf center,Vecf size,ubyte alpha,Color!ubyte color = rgb(255, 255, 255)) @safe
    {
        position -= camera.port.begin;
        drawable.drawEx(this, position, angle, center, size, alpha, color);
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
}

float[4][4] ortho(float left, float right, float bottom, float top, float zNear = -1.0f, float zFar = 0.0f) 
@safe nothrow pure
{
    immutable defl = 0.0f;

    immutable mRL = right - left;
    immutable mTB = top - bottom;
    immutable mFN = zFar - zNear;

    immutable tRL = -(right + left) / mRL;
    immutable tTB = -(top + bottom) / mTB;
    immutable tFN = -(zFar + zNear) / mFN;

    return      [
                    [2 / mRL, defl,  defl,    defl],
                    [defl,  2 / mTB, defl,    defl],
                    [defl,    defl, -2 / mFN, defl],
                    [ tRL,    tTB,   tFN,     1.0f]
                ];
}

/// A renderer for rendering to a window with hardware acceleration.
class GLRender : IRenderer
{
    import tida.window, tida.color, tida.vector, tida.graph.camera, tida.shape, tida.graph.gl;
    import tida.graph.vertgen, tida.graph.shader;
    import std.conv : to;

    private
    {
        IWindow window;
        Color!ubyte _background;
        Camera _camera;
        RenderType _type = RenderType.OpenGL;
        float[4][4] _projection;

        Shader!Program[string] shaders;
        Shader!Program current;
    }

    this(IWindow window) @safe
    {  
        this.window = window;

        _camera = new Camera();

        _camera.shape = Shape.Rectangle(Vecf(0,0), Vecf(window.width,window.height));
        _camera.port = Shape.Rectangle(Vecf(0,0), Vecf(window.width,window.height));

        Shader!Program defaultShader = new Shader!Program();
        Shader!Vertex vertex = new Shader!Vertex().bindSource(
        `
        #version 130
        in vec3 position;
        uniform mat4 projection;

        void main() {
            gl_Position = projection * vec4(position, 1.0f);
        }
        `);

        Shader!Fragment fragment = new Shader!Fragment().bindSource(
        `
        #version 130
        uniform vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);

        void main() {
            gl_FragColor = color;
        }
        `
        );

        defaultShader
            .attach(vertex)
            .attach(fragment)
            .link();

        shaders["Default"] = defaultShader;

        blendMode(BlendMode.Blend);

        this.reshape();
    }

    ///
    float[4][4] projection() @safe
    {
        return _projection;
    }

    override void reshape() @safe
    {
        GL.viewport(0, 0, _camera.shape.width.to!int,_camera.shape.height.to!int);

        clear();

        this._projection = ortho(0.0, _camera.port.end.x, _camera.port.end.y, 0.0, -1.0, 1.0);
    }

    override void camera(Camera otherCamera) @safe @property
    in(camera,"Camera is not allocated!")
    body
    {
        this._camera = otherCamera;
    }

    override Camera camera() @safe @property
    {
        return this._camera;
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

    override void setShader(string name, Shader!Program program) @safe
    {
        shaders[name] = program;
    }

    override Shader!Program getShader(string name) @safe
    {
        if(name in shaders)
            return shaders[name];
        else
            return null;
    }

    override void currentShader(Shader!Program program) @safe @property
    {
        current = program;
    }

    override Shader!Program currentShader() @safe @property
    {
        return current;
    }
 
    override void resetShader() @safe
    {
        current = null;
    }

    override void point(Vecf position, Color!ubyte color) @trusted
    {
        position -= camera.port.begin;

        if(currentShader is null) {
            currentShader = getShader("Default");
        }

        auto vid = generateVertex(Shape.Point(position));

        vid.bindVertexArray();
        GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);
        GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
        GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 2, GL_FLOAT, false, 0, null);

        GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
        GL3.bindVertexArray(0);

        currentShader.using();
        vid.bindVertexArray();

        currentShader.setUniform("projection", _projection);
        currentShader.setUniform("color", color);

        GL3.drawArrays(GL_POINTS, 0, 2);

        GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
        GL3.bindVertexArray(0);

        destroy(vid);

        resetShader();
    }

    override void line(Vecf[2] points, Color!ubyte color) @trusted
    {
        if(currentShader is null) {
            currentShader = getShader("Default");
        }

        const shape = Shape.Line(   points[0] - camera.port.begin, 
                                    points[1] - camera.port.begin);

        auto vid = generateVertex(shape);

        vid.bindVertexArray();
        GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);
        GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
        GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 2, GL_FLOAT, false, 2 * float.sizeof, null);

        GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
        GL3.bindVertexArray(0);

        currentShader.using();
        vid.bindVertexArray();

        currentShader.setUniform("projection", _projection);
        currentShader.setUniform("color", color);

        GL3.drawArrays(GL_LINES, 0, 2);

        GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
        GL3.bindVertexArray(0);

        destroy(vid);

        resetShader();
    }

    override void rectangle(Vecf position, int width, int height, Color!ubyte color, bool isFill) @trusted
    {
        position -= camera.port.begin;

        if(currentShader is null) {
            currentShader = getShader("Default");
        }

        if(isFill)
        {
            Shape shape = Shape.Rectangle(position, position + Vecf(width, height));

            auto vid = generateVertex(shape);

            vid.bindVertexArray();
            GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);
            GL3.bindBuffer(GL_ELEMENT_ARRAY_BUFFER, vid.idElementArray);

            GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
            GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 3, GL_FLOAT, false, 3 * float.sizeof, null);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            currentShader.using();
            vid.bindVertexArray();

            currentShader.setUniform("projection", _projection);
            currentShader.setUniform("color", color);

            GL3.drawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, null);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            destroy(vid);
        } else {
            Shape shape = Shape.Multi(  [
                                            Shape.Line(position, position + Vecf(width, 0)),
                                            Shape.Line(position + Vecf(width, 0), position + Vecf(width, height)),
                                            Shape.Line(position, position + Vecf(0, height)),
                                            Shape.Line(position + Vecf(0, height), position + Vecf(width, height))
                                        ]);

            auto vid = generateVertex(shape);

            vid.bindVertexArray();
            GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);

            GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
            GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 2, GL_FLOAT, false, 0, null);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            currentShader.using();
            vid.bindVertexArray();

            currentShader.setUniform("projection", _projection);
            currentShader.setUniform("color", color);

            GL3.drawArrays(GL_LINES, 0, 2 * 4);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            destroy(vid);
        }

        resetShader();
    }

    override void circle(Vecf position, float radius, Color!ubyte color, bool isFill) @trusted
    {
        position -= camera.port.begin;

        if(currentShader is null) {
            currentShader = getShader("Default");
        }

        if(isFill) {
            auto vid = generateVertex(Shape.Circle(position, radius));

            vid.bindVertexArray();
            GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);

            GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
            GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 2, GL_FLOAT, false, 0, null);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            currentShader.using();
            vid.bindVertexArray();

            currentShader.setUniform("projection", _projection);
            currentShader.setUniform("color", color);

            GL3.drawArrays(GL_TRIANGLES, 0, cast(uint) vid.length / 3);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            destroy(vid);
        } else {
            import std.math;

            Shape shape;
            shape.type = ShapeType.multi;

            float x = 0.0f;
            float y = 0.0f;

            for(float i = 0; i <= 360;)
            {
                x = radius * cos(i);
                y = radius * sin(i);

                auto vec = Vecf(position.x + x, position.y + y);

                i += 0.5;
                x = radius * cos(i);
                y = radius * sin(i);

                shape.shapes ~= Shape.Line(vec, Vecf(position.x + x,position.y + y));

                i += 0.5;
            }

            auto vid = generateVertex(shape);

            vid.bindVertexArray();
            GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);

            GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
            GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 2, GL_FLOAT, false, 0, null);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            currentShader.using();
            vid.bindVertexArray();

            currentShader.setUniform("projection", _projection);
            currentShader.setUniform("color", color);

            GL3.drawArrays(GL_LINES, 0, vid.length / 2);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            destroy(vid);
        }

        resetShader();
    }

    override void polygon(Vecf position,Vecf[] points,Color!ubyte color,bool isFill) @trusted
    {
        import std.algorithm : each;

        points = points.dup;
        points.each!((ref e) => e = e + position);

        if(currentShader is null) {
            currentShader = getShader("Default");
        }

        if(isFill)
        {
            auto vid = generateVertex(Shape.Polygon(points));

            vid.bindVertexArray();
            GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);
            GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
            GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 3, GL_FLOAT, false, 0, null);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            currentShader.using();
            vid.bindVertexArray();

            currentShader.setUniform("projection", projection);
            currentShader.setUniform("color", color);

            GL3.drawArrays(GL_TRIANGLE_FAN, 0, cast(uint) points.length);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            destroy(vid);
        } else
        {
            Shape shape = Shape.Multi([]);

            int next = 0;
            for(int i = 0; i < points.length; i++)
            {
                next = (i + 1 == points.length) ? 0 : i + 1;
                shape.shapes ~= Shape.Line(points[i], points[next]);
            }

            auto vid = generateVertex(shape);

            vid.bindVertexArray();
            GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);
            GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
            GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 2, GL_FLOAT, false, 0, null);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            currentShader.using();
            vid.bindVertexArray();

            currentShader.setUniform("projection", projection);
            currentShader.setUniform("color", color);

            GL3.drawArrays(GL_LINES, 0, cast(uint) points.length * 2);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            destroy(vid);
        }

        resetShader();
    }

    override void triangle(Vecf[3] position,Color!ubyte color,bool isFill) @trusted
    {
        if(currentShader is null) {
            currentShader = getShader("Default");
        }

        if(isFill)
        {
            auto vid = generateVertex(Shape.Triangle(position));

            vid.bindVertexArray();
            GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);
            GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
            GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 3, GL_FLOAT, false, 0, null);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            currentShader.using();
            vid.bindVertexArray();

            currentShader.setUniform("projection", projection);
            currentShader.setUniform("color", color);

            GL3.drawArrays(GL_TRIANGLES, 0, cast(uint) position.length);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            destroy(vid);
        } else {
            auto vid = generateVertex(Shape.Multi(  [
                                                        Shape.Line(position[0], position[1]),
                                                        Shape.Line(position[1], position[2]),
                                                        Shape.Line(position[2], position[0])
                                                    ]));

            vid.bindVertexArray();
            GL3.bindBuffer(GL_ARRAY_BUFFER, vid.idBufferArray);
            GL3.enableVertexAttribArray(currentShader.getAttribLocation("position"));
            GL3.vertexAttribPointer(currentShader.getAttribLocation("position"), 3, GL_FLOAT, false, 0, null);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            currentShader.using();
            vid.bindVertexArray();

            currentShader.setUniform("projection", projection);
            currentShader.setUniform("color", color);

            GL3.drawArrays(GL_LINES, 0, cast(uint) position.length);

            GL3.bindBuffer(GL_ARRAY_BUFFER, 0);
            GL3.bindVertexArray(0);

            destroy(vid);
        }

        resetShader();
    }

    override void clear() @safe
    {
        GL.clear();
    }

    override void drawning() @safe
    {
        window.swapBuffers();
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

    override RenderType type() @safe
    {
        return _type;
    }
}

alias ICanvas = IPlane; /// Inteface Canvas
alias Canvas = Plane; /// Canvas

/++
    An interface for implementing canvas rendering via Software-renderer.
+/
interface IPlane
{
    import tida.color, tida.window, tida.vector;

    /++
        Allocate memory for the canvas at the specified size.

        Params:
            width = Canvas width.
            height = Canvas height.
    +/
    void alloc(uint width,uint height) @safe;

    /++
        Clear the canvas with the specified color.

        Params:
            color = Cleared color.
    +/
    void clearPlane(Color!ubyte color) @safe;

    /++
        Draw the buffer to the canvas.

        Params:
            window = Window.
    +/
    void putToWindow(IWindow window) @safe;

    /++
        Set the color mixing mode.
    +/
    void blendMode(BlendMode mode) @safe @property;

    /++
        Draw a point on the canvas.
        Draw only a point, the rest of the shapes are rendered.

        Params:
            position = Point position.
            color = Point color.
    +/
    void pointTo(Vecf position,Color!ubyte color) @safe;

    /++
        Set port of visibility.

        Params:
            w = Port width.
            h = Port height.
    +/
    void viewport(int w,int h) @safe;

    /++
        Move the visibility port to the specified coordinates.

        Params:
            x = Port x-axis position.
            y = Port y-axis position.
    +/
    void move(int x,int y) @safe;

    /++
        Canvas data.
    +/
    ubyte[] data() @safe @property;
}

/++
    Implementing the rendering of a point in the canvas.

    Params:
        pixelformat = Pixel Format.
+/
template PointToImpl(int pixelformat)
{
    override void pointTo(Vecf position, Color!ubyte color) @trusted
    {
        import std.conv : to;

        position = position - Vecf(xput,yput);

        if(position.x.to!int >= _width || position.y.to!int >= _height ||
           position.x.to!int < 0 || position.y.to!int < 0)
            return;

        if(_pwidth == _width && _pheight == _height)
        {
            auto pos = ((_width * position.y.to!int) + position.x.to!int) * 4;

            if(bmode == BlendMode.Blend) {
                static if(pixelformat == PixelFormat.BGRA)
                {
                    color.colorize!Alpha(rgba(buffer[pos+3],buffer[pos+2],buffer[pos+1],buffer[pos]));
                }else
                static if(pixelformat == PixelFormat.BGR)
                {
                    color.colorize!Alpha(rgba(buffer[pos+2],buffer[pos+1],buffer[pos],255));
                }else
                static if(pixelformat == PixelFormat.RGBA)
                {
                    color.colorize!Alpha(rgba(buffer[pos], buffer[pos+1],buffer[pos+2],buffer[pos+3]));
                }else
                static if(pixelformat == PixelFormat.RGB)
                {
                    color.colorize!Alpha(rgba(buffer[pos],buffer[pos+1],buffer[pos+2],255));
                }
            }

            static if(pixelformat == PixelFormat.BGRA)
            {
                buffer[pos] = color.b;
                buffer[pos+1] = color.g;
                buffer[pos+2] = color.r;
                buffer[pos+3] = color.a;
            }else
            static if(pixelformat == PixelFormat.BGR)
            {
                buffer[pos] = color.b;
                buffer[pos+1] = color.g;
                buffer[pos+2] = color.r;
            }else
            static if(pixelformat == PixelFormat.RGBA)
            {
                buffer[pos] = color.r;
                buffer[pos+1] = color.g;
                buffer[pos+2] = color.b;
                buffer[pos+3] = color.a;
            }else
            static if(pixelformat == PixelFormat.RGB)
            {
                buffer[pos] = color.r;
                buffer[pos+1] = color.g;
                buffer[pos+2] = color.b;
            }
        }else
        {
            import tida.graph.each;

            auto scaleWidth = cast(double) _pwidth / cast(double) _width;
            auto scaleHeight = cast(double) _pheight / cast(double) _height;

            int w = cast(int) _width / _pwidth + 1;
            int h = cast(int) _height / _pheight + 1;

            position = Vecf(position.x / scaleWidth, position.y / scaleHeight);

            Color!ubyte original = color;

            foreach(ix, iy; Coord(position.x.to!int + w,position.y.to!int + h,
                                  position.x.to!int,position.y.to!int))
            {
                if(ix > _width || iy > _height || ix < 0 || iy < 0)
                    continue;

                auto pos = (iy * _width) + ix;
                pos *= 4;

                color = original;
                if(bmode == BlendMode.Blend) {
                    static if(pixelformat == PixelFormat.BGRA)
                    {
                        color.colorize!Alpha(rgba(buffer[pos+3],buffer[pos+2],buffer[pos+1],buffer[pos]));
                    }else
                    static if(pixelformat == PixelFormat.BGR)
                    {
                        color.colorize!Alpha(rgba(buffer[pos+2],buffer[pos+1],buffer[pos],255));
                    }else
                    static if(pixelformat == PixelFormat.RGBA)
                    {
                        color.colorize!Alpha(rgba(buffer[pos],buffer[pos+1],buffer[pos+2],buffer[pos+3]));
                    }else
                    static if(pixelformat == PixelFormat.RGB)
                    {
                        color.colorize!Alpha(rgba(buffer[pos],buffer[pos+1],buffer[pos+2],255));
                    }
                }

                if(pos < buffer.length)
                {
                    static if(pixelformat == PixelFormat.BGRA)
                    {
                        buffer[pos] = color.b;
                        buffer[pos+1] = color.g;
                        buffer[pos+2] = color.r;
                        buffer[pos+3] = color.a;
                    }else
                    static if(pixelformat == PixelFormat.BGR)
                    {
                        buffer[pos] = color.b;
                        buffer[pos+1] = color.g;
                        buffer[pos+2] = color.r;
                    }else
                    static if(pixelformat == PixelFormat.RGBA)
                    {
                        buffer[pos] = color.r;
                        buffer[pos+1] = color.g;
                        buffer[pos+2] = color.b;
                        buffer[pos+3] = color.a;
                    }else
                    static if(pixelformat == PixelFormat.RGB)
                    {
                        buffer[pos] = color.r;
                        buffer[pos+1] = color.g;
                        buffer[pos+2] = color.b;
                    }
                }
            }
        }
    }
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
                xput, yput, xput, yput, _width, _height);

            XSync(runtime.display, False);
        }
    }

    override void blendMode(BlendMode mode) @safe @property
    {
        bmode = mode;
    }

    mixin PointToImpl!(PixelFormat.BGR);
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
        import std.exception;

        if(wimage !is null) DeleteObject(wimage);
        if(hdc is null) hdc = GetDC((cast(Window) window).handle);

        wimage = CreateBitmap(_width, _height,1,32,cast(LPBYTE) buffer);

        enforce(wimage,"[WINAPI] Bitmap is not create!");

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

    mixin PointToImpl!(PixelFormat.BGR);
}

/++
    Render without hardware acceleration.
    It is aggregated with either a window or canvases (IPlane).

    Example:
    ---
    // Render for the window.
    Software soft = new Software(myWindow);
    ...

    // Render for another object like a picture, or another object.
    Software soft = new Software(new MyCanvas());
    ---
+/
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
        plane.move(_camera.shape.begin.x.to!int,_camera.shape.begin.y.to!int);
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
        import tida.graph.each;

        foreach(x,y; Line(points[0],points[1]))
        {
            point(Vecf(x,y),color);
        }
    }

    override void circle(Vecf position,float radious,Color!ubyte color,bool isFill) @safe
    {
        import tida.graph.image, tida.graph.each;

        int rad = cast(int) radious;
        Image buffer = new Image(rad * 2, rad * 2);
        buffer.fill(rgba(255,255,255,0));

        int x = 0;
        int y = rad;

        int X1 = rad;
        int Y1 = rad;

        int delta = 1 - 2 * cast(int) radious;
        int error = 0;

        void bufferLine(Vecf[2] points, Color!ubyte color) @safe {
            foreach(ix, iy; Line(points[0], points[1])) {
                buffer.setPixel(ix, iy, color);
            }
        }

        while (y >= 0)
        {
            if(isFill)
            {
                bufferLine([Vecf(X1 + x, Y1 + y),Vecf(X1 + x, Y1 - y)],color);
                bufferLine([Vecf(X1 - x, Y1 + y),Vecf(X1 - x, Y1 - y)],color);
            }else
            {
                buffer.setPixel(X1 + x, Y1 + y,color);
                buffer.setPixel(X1 + x, Y1 - y,color);
                buffer.setPixel(X1 - x, Y1 + y,color);
                buffer.setPixel(X1 - x, Y1 - y,color);
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

        foreach(ix, iy; Coord(buffer.width, buffer.height)) {
            Color!ubyte pixel;

            if( (pixel = buffer.getPixel(ix,iy)).a != 0)
            {
                point(position + Vecf(ix, iy), pixel);
            }
        }
    }

    override void triangle(Vecf[3] position,Color!ubyte color,bool isFill) @trusted
    {
        import tida.graph.each;

        if(isFill)
        {
            foreach(x, y; Line(position[0], position[1])) {
                auto p = Vecf(x,y);

                line([p, position[2]], color);
            }
        } else
        {
            line([position[0], position[1]], color);
            line([position[1], position[2]], color);
            line([position[2], position[0]], color);
        }
    }

    Vecf lineLineTouch(Vecf[] first, Vecf[] second) @safe
    {
        const a = first[0];
        const b = first[1];
        const c = second[0];
        const d = second[1];

        const denominator = ((b.X - a.X) * (d.Y - c.Y)) - ((b.Y - a.Y) * (d.X - c.X));

        const numerator1  = ((a.Y - c.Y) * (d.X - c.X)) - ((a.X - c.X) * (d.Y - c.Y));
        const numerator2  = ((a.Y - c.Y) * (b.X - a.X)) - ((a.X - c.X) * (b.Y - a.Y));

        const r = numerator1 / denominator;
        const s = numerator2 / denominator;

        if((r >= 0 && r <= 1) && (s >= 0 && s <= 1))
            return first[0] - ((first[1] - first[0]) * r);
        else
            return VecfNan;
    }

    override void polygon(Vecf position,Vecf[] points,Color!ubyte color,bool isFill) @trusted
    {
        import std.algorithm : each;
        points = points.dup;
        points.each!((ref e) => e = e + position);

        if(!isFill)
        {
            int next = 0;
            for(int i = 0; i < points.length; i++) {
                next = (i + 1 == points.length) ? 0 : i + 1;
                line([points[i],points[next]], color);
            }
        } else {
            import std.algorithm;

            float maxX = points.maxElement!"a.x".x;
            float minY = points.minElement!"a.y".y;
            float maxY = points.maxElement!"a.y".y;
            float minX = points.minElement!"a.x".x;

            alias LineIter = Vecf[2];

            LineIter[] drowning;

            for(float i = minY; i <= maxY; i += 1.0f)
            {
                Vecf firstPoint = VecfNan;
                float lastX = minX > position.x ? position.x : minX;

                for(float j = lastX; j <= maxX; j += 1.0f)
                {
                    size_t next = 0;
                    for(size_t currPointI = 0; currPointI < points.length; currPointI++)
                    {
                        next = (currPointI + 1 == points.length) ? 0 : currPointI + 1;

                        auto iter = lineLineTouch(  [Vecf(lastX, i), Vecf(j, i)],
                                                    [points[currPointI], points[next]]);
                        if(!iter.isVecfNan) {
                            if(firstPoint.isVecfNan) {
                                firstPoint = Vecf(j, i);
                            } else {
                                drowning ~= [firstPoint, Vecf(j, i)];
                                firstPoint = VecfNan;
                            }

                            lastX = j;
                        }
                    }             
                }
            }

            foreach(e; drowning)
            {
                line(e, color);
            }
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

    import tida.graph.shader;

    override Shader!Program getShader(string name) @safe
    {
        assert(null, "There are no shaders in this version of the render.");
    }

    override void setShader(string name,Shader!Program program) @safe
    {
        assert(null, "There are no shaders in this version of the render.");
    }

    override void currentShader(Shader!Program program) @safe @property
    {
        assert(null, "There are no shaders in this version of the render.");
    }

    override Shader!Program currentShader() @safe @property
    {
        assert(null, "There are no shaders in this version of the render.");
    }

    override void resetShader() @safe
    {
        assert(null, "There are no shaders in this version of the render.");
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

        if( glSupport == GLSupport.gl11 ||
            glSupport == GLSupport.gl12 ||
            glSupport == GLSupport.gl13 ||
            glSupport == GLSupport.gl14 ||
            glSupport == GLSupport.gl15) {
            throw new Exception("The version of the open library must be equal to or greater than 2.");
        }

        render = new GLRender(window);
    }catch(Exception e)
    {
        render = new Software(window);
    }

    return render;
}
