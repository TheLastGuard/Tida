/++
A module for rendering objects.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.render;

/++
Camera control object in render,
+/
class Camera
{
    import  tida.vector,
            tida.shape,
            tida.instance;

    struct CameraObject
    {
        Vector!float* position;
        Vector!float size;
    }

private:
    Shape!float _port;
    Shape!float _shape;
    CameraObject object;
    float _trackDistance = 4.0f;
    Vector!float _sizeRoom = vecNaN!float;
    

public @safe nothrow pure:
    /// The allowed room size for camera scrolling.
    @property Vector!float sizeRoom() => _sizeRoom;
    
    /// The allowed room size for camera scrolling.
    @property Vector!float sizeRoom(Vector!float value) => _sizeRoom = value;
    
    /// A method to change the allowed size of a scrolling room for a camera.
    void resizeRoom(Vector!float value)
    {
        _sizeRoom = value;
    }

    /++
    A method for binding a specific object to a camera to track it.
    
    Params:
        position =  The reference to the variable for which the tracking
                    will be performed. We need a variable that will be 
                    alive during the camera's tracking cycle.
        size     =  The size of the object. (Each object is represented as a rectangle.)
    +/
    void bindObject(    ref Vector!float position, 
                        Vector!float size = vecNaN!float)  @trusted
    {
        object.position = &position;
        object.size = size.isVectorNaN ? vec!float(1, 1) : size;
    }
    
    /++
    A method for binding a specific object to a camera to track it.
    
    Params:
        position =  The reference to the variable for which the tracking
                    will be performed. We need a variable that will be 
                    alive during the camera's tracking cycle.
        size     =  The size of the object. (Each object is represented as a rectangle.)
    +/
    void bindObject(    Vector!float* position,
                        Vector!float size = vecNaN!float)
    {
        object.position = position;
        object.size = size.isVectorNaN ? vec!float(1, 1) : size;
    }
    
    /++
    A method for binding a specific object to a camera to track it.
    
    Params:
        instance =  An object in the scene that will be monitored by the camera. 
                    The size is calculated from the object's touch mask.
    +/
    void bindObject(Instance instance)
    {
        object.position = &instance.position;
        object.size = instance.mask.calculateSize();
    }
    
    /++
    A method that reproduces the process of tracking an object.
    +/
    void followObject()
    {
        Vector!float velocity = vecZero!float;
    
        if (object.position.x < port.begin.x + _trackDistance)
        {
            velocity.x = (port.begin.x + _trackDistance) - object.position.x;
        } else
        if (object.position.x + object.size.x> port.begin.x + port.end.x - _trackDistance)
        {
            velocity.x = (port.begin.x + port.end.x - _trackDistance) - (object.position.x + object.size.x);
        }
        
        if (object.position.y < port.begin.y + _trackDistance)
        {
            velocity.y = (port.begin.y + _trackDistance) - object.position.y;
        } else
        if (object.position.y + object.size.y > port.begin.y + port.end.y - _trackDistance)
        {
            velocity.y = (port.begin.y + port.end.y - _trackDistance) - (object.position.y + object.size.y);
        }
        
        immutable preBegin = port.begin - velocity;
        
        if (!_sizeRoom.isVectorNaN)
        {
            if (preBegin.x > 0 &&
                preBegin.x + port.end.x < _sizeRoom.x &&
                preBegin.y > 0 &&
                preBegin.y + port.end.y < _sizeRoom.y)
            {
                port = Shapef.Rectangle(preBegin, port.end);
            }
        } else
            port = Shapef.Rectangle(preBegin, port.end);
    }
    
    /// Distance between camera boundaries and subject for the scene to move the camera's view.
    @property float trackDistance() => _trackDistance;
    
    /// Distance between camera boundaries and subject for the scene to move the camera's view.
    @property float trackDistance(float value) => _trackDistance = value;

    /++
    The port is the immediate visible part in the "room". The entire area in 
    the world that must be covered in the field of view.
    +/
    @property Shape!float port() => _port;

    /// ditto
    @property Shape!float port(Shape!float value) => _port = value;

    /++
    The size of the visible part in the plane of the window.
    +/
    @property Shape!float shape() => _shape;

    /// ditto
    @property Shape!float shape(Shape!float value) => _shape = value;

    /++
    Moves the visible field.

    Params:
        value = Factor movement.
    +/
    void moveView(Vecf value)
    {
        _port = Shape!float.Rectangle(_port.begin + value, _port.end);
    }
}

/// Renderer type
enum RenderType
{
    unknown,
    software,
    opengl,
    directx, // Not implement
    vulkan // Not implement
}

/// A property that explains whether blending should be applied or not.
enum BlendMode
{
    withoutBlend, /// Without blending
    withBlend /// With blending
}

interface ITarget
{
    void bind(IRenderer render) @safe;
    
    void unbind(IRenderer render) @safe;
    
    void drawning(IRenderer render) @safe;
}

/++
An interface for rendering objects to a display or other storehouse of pixels.
+/
interface IRenderer
{
    import  tida.color,
            tida.vector,
            tida.shader,
            tida.drawable,
            tida.matrix;

@safe:
    // null - default
    void bindTarget(ITarget target) @safe;
    
    @property ITarget currentTarget() @safe;

    /// Updates the rendering surface if, for example, the window is resized.
    void reshape();

    ///Camera for rendering.
    @property void camera(Camera camera);

    /// Camera for rendering.
    @property Camera camera();

    /++
    Drawing a point.

    Params:
        vec = Point position.
        color = Point color.
    +/
    void point(Vecf vec, Color!ubyte color) @safe;

    /++
    Line drawing.

    Params:
        points = Tops of lines.
        color = Line color.
    +/
    void line(Vecf[2] points, Color!ubyte color) @safe;

    /++
    Drawing a rectangle.

    Params:
        position = Rectangle position.
        width = Rectangle width.
        height = Rectangle height.
        color = Rectangle color.
        isFill = Whether to fill the rectangle with color.
    +/
    void rectangle( Vecf position, 
                    uint width, 
                    uint height, 
                    Color!ubyte color, 
                    bool isFill) @safe;

    /++
    Drawning a circle.

    Params:
        position = Circle position.
        radius = Circle radius.
        color = Circle color.
        isFill = Whether to fill the circle with color.
    +/
    void circle(Vecf position, 
                float radius, 
                Color!ubyte color, 
                bool isFill) @safe;

    /++
    Drawing a triangle by its three vertices.

    Params:
        points = Triangle vertices
        color = Triangle color.
        isFill = Whether it is necessary to fill the triangle with color.
    +/
    void triangle(Vecf[3] points, Color!ubyte color, bool isFill) @safe;

    /++
    Draws a rectangle with rounded edges.
    (Rendering is available only through hardware acceleration).

    Params:
        position = Position roundrectangle.
        width = Width roundrectangle.
        height = Height roundrectangle.
        radius = Radius rounded edges.
        color = Color roundrect.
        isFill = Roundrect is filled color?
    +/
    void roundrect( Vecf position, 
                    uint width, 
                    uint height, 
                    float radius, 
                    Color!ubyte color, 
                    bool isFill) @safe;

    /++
    Drawing a polygon from an array of vertices.

    Params:
        position = Polygon position.
        points = Polygon vertices/
        color = Polygon color.
        isFill = Whether it is necessary to fill the polygon with color.
    +/
    void polygon(   Vecf position, 
                    Vecf[] points, 
                    Color!ubyte color, 
                    bool isFill) @safe;

    /// Cleans the surface by filling it with color.
    void clear() @safe;

    /// Outputs the buffer to the window.
    void drawning() @safe;

    /// Gives the type of render.
    RenderType type() @safe;

    /// Set the coloring method. Those. with or without alpha blending.
    void blendMode(BlendMode mode) @safe;

    /// Set factor blend
    void blendOperation(BlendFactor sfactor, BlendFactor dfactor) @safe;

    /// The color to fill when clearing.
    void background(Color!ubyte background) @safe @property;

    /// ditto
    Color!ubyte background() @safe @property;

    /++
    Memorize the shader for future reference.

    Params:
        name =  The name of the shader by which it will be possible to pick up 
                the shader in the future.
        program = Shader program.
    +/
    void setShader(string name, Shader!Program program) @safe;

    /++
    Pulls a shader from memory, getting it by name. Returns a null pointer 
    if no shader is found.

    Params:
        name = Shader name.
    +/
    Shader!Program getShader(string name) @safe;

    /// The current shader for the next object rendering.
    void currentShader(Shader!Program program) @safe @property; 

    /// The current shader for the next object rendering.
    Shader!Program currentShader() @safe @property;

    /// Reset the shader to main.
    void resetShader() @safe;

    /// Current model matrix.
    float[4][4] currentModelMatrix() @safe @property;

    /// ditto
    void currentModelMatrix(float[4][4] matrix) @safe @property;

    /// Reset current model matrix.
    final void resetModelMatrix() @safe
    {
        this.currentModelMatrix = identity();
    }

    /++
    Renders an object.

    See_Also: `tida.graph.drawable`.
    +/
    void draw(IDrawable drawable, Vecf position) @safe;

    /// ditto
    void drawEx(    IDrawableEx drawable, 
                    Vecf position, 
                    float angle,
                    Vecf center,
                    Vecf size,
                    ubyte alpha,
                    Color!ubyte color = rgb(255, 255, 255)) @safe;
}

/++
Render objects using hardware acceleration through an open graphics library.
+/
class GLRender : IRenderer
{
    import tida.window;
    import tida.gl;
    import tida.shader;
    import tida.vertgen;
    import tida.color;
    import tida.vector;
    import tida.matrix;
    import tida.shape;
    import tida.drawable;

    enum deprecatedVertex =
    "
    #version 130
    in vec3 position;

    uniform mat4 projection;
    uniform mat4 model;

    void main()
    {
        gl_Position = projection * model * vec4(position, 1.0f);
    }
    ";

    enum deprecatedFragment =
    "
    #version 130
    uniform vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);

    void main()
    {
        gl_FragColor = color;
    }
    ";

    enum modernVertex =
    "
    #version 330 core
    layout (location = 0) in vec3 position;

    uniform mat4 projection;
    uniform mat4 model;

    void main()
    {
        gl_Position = projection * model * vec4(position, 1.0f);
    }
    ";

    enum modernFragment =
    "
    #version 330 core
    uniform vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);

    out vec4 fragColor;

    void main()
    {
        fragColor = color;
    }
    ";

private:
    IWindow window;
    Color!ubyte _background;
    Camera _camera;
    mat4 _projection;

    Shader!Program[string] shaders;
    Shader!Program current;

    mat4 _model;

    bool _isModern = false;
    ITarget _target;

public @trusted:
    this(IWindow window)
    {
        this.window = window;

        _camera = new Camera();
        _camera.shape = Shapef.Rectangle(vecf(0, 0), vecf(window.width, window.height));
        _camera.port = _camera.shape;

        Shader!Program defaultShader = new Shader!Program();

        string vsource, fsource;

        if (glslVersion == "1.10" || glslVersion == "1.20" || glslVersion == "1.30")
        {
            vsource = deprecatedVertex;
            fsource = deprecatedFragment;
            _isModern = false;
        } else
        {
            vsource = modernVertex;
            fsource = modernFragment;
            _isModern = true;
        }

        Shader!Vertex defaultVertex = new Shader!Vertex();
        defaultVertex.bindSource(vsource);

        Shader!Fragment defaultFragment = new Shader!Fragment();
        defaultFragment.bindSource(fsource);

        defaultShader.attach(defaultVertex);
        defaultShader.attach(defaultFragment);
        defaultShader.link();

        setShader("Default", defaultShader);

        _model = identity();
        blendMode(BlendMode.withBlend);
        blendOperation(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha);

        this.reshape();
    }

    @property Shader!Program[string] getShaders()
    {
        return shaders;
    }

    @property mat4 projection()
    {
        return _projection;
    }

    int glBlendFactor(BlendFactor factor)
    {
        if (factor == BlendFactor.Zero)
            return GL_ZERO;
        else
        if (factor == BlendFactor.One)
            return GL_ONE;
        else
        if (factor == BlendFactor.SrcColor)
            return GL_SRC_COLOR;
        else
        if (factor == BlendFactor.DstColor)
            return GL_DST_COLOR;
        else
        if (factor == BlendFactor.OneMinusSrcColor)
            return GL_ONE_MINUS_SRC_COLOR;
        else
        if (factor == BlendFactor.OneMinusDstColor)
            return GL_ONE_MINUS_DST_COLOR;
        else
        if (factor == BlendFactor.SrcAlpha)
            return GL_SRC_ALPHA;
        else
        if (factor == BlendFactor.DstAlpha)
            return GL_DST_ALPHA;
        else
        if (factor == BlendFactor.OneMinusSrcAlpha)
            return GL_ONE_MINUS_SRC_ALPHA;
        else
        if (factor == BlendFactor.OneMinusDstAlpha)
            return GL_ONE_MINUS_DST_ALPHA;

        return 0;
    }

    void setDefaultUniform(Color!ubyte color)
    {
        if (currentShader.getUniformLocation("projection") != -1)
            currentShader.setUniform("projection", _projection);

        if (currentShader.getUniformLocation("color") != -1)
            currentShader.setUniform("color", color);

        if (currentShader.getUniformLocation("model") != -1)
            currentShader.setUniform("model", _model);
    }

    @property bool isModern()
    {
        return _isModern;
    }

override:
    void draw(IDrawable drawable, Vecf position) @safe
    {
        position -= camera.port.begin;
        drawable.draw(this, position);
    }

    /// ditto
    void drawEx(    IDrawableEx drawable, 
                    Vecf position, 
                float angle,
                Vecf center,
                Vecf size,
                ubyte alpha,
                Color!ubyte color = rgb(255, 255, 255)) @safe
    {
        position -= camera.port.begin;
        drawable.drawEx(this, position, angle, center, size, alpha, color);
    }

    void reshape()
    {
        import std.conv : to;

        int yborder = 0;

        version (Windows)
        {
            yborder = (cast(Window) window).windowBorderSize;
        }

        glViewport(
            -_camera.shape.begin.x.to!int,
            -_camera.shape.begin.y.to!int - yborder, 
            _camera.shape.end.x.to!int, 
            _camera.shape.end.y.to!int
        );
        
        this._projection = ortho(0.0, _camera.port.end.x, _camera.port.end.y, 0.0, -1.0, 1.0);
    }

    @property void camera(Camera camera)
    {
        _camera = camera;
    }

    @property Camera camera()
    {
        return _camera;
    }
    
    void bindTarget(ITarget target) @safe
    {
        if (target is null)
        {
            if (_target !is null)
                _target.unbind(this);
                
            _target = null;
            return;
        }
        
        if (_target !is null)
            _target.unbind(this);
            
        target.bind(this);
        _target = target;
    }
    
    @property ITarget currentTarget() @safe
    {
        return _target;
    }

    void point(Vecf vec, Color!ubyte color)
    {
        if (currentShader is null)
            currentShader = getShader("Default");
            
        vec -= camera.port.begin;

        Shapef shape = Shapef.Point(vec);
        
        scope vinfo = new VertexInfo!float();
        vinfo.bindFromBuffer(generateBuffer(shape).generateArray);

        vinfo.bindBuffer();
        vinfo.bindVertexArray();
        vinfo.vertexAttribPointer(currentShader.getAttribLocation("position"));

        currentShader.using();
        currentShader.enableVertex("position");

        setDefaultUniform(color);

        vinfo.draw(ShapeType.point);

        currentShader.disableVertex("position");
        vinfo.unbindBuffer();
        vinfo.unbindVertexArray();

        resetShader();
        resetModelMatrix();
    }

    void line(Vecf[2] points, Color!ubyte color)
    {
        if (currentShader is null)
            currentShader = getShader("Default");

        auto shape = Shapef.Line(   points[0] - camera.port.begin, 
                                    points[1] - camera.port.begin);
                                    
        scope vinfo = new VertexInfo!float();
        vinfo.bindFromBuffer(generateBuffer(shape).generateArray);

        vinfo.bindBuffer();
        vinfo.bindVertexArray();

        currentShader.enableVertex("position");
        vinfo.vertexAttribPointer(currentShader.getAttribLocation("position"));

        vinfo.unbindBuffer();

        currentShader.using();
        setDefaultUniform(color);
        vinfo.draw(ShapeType.line);

        currentShader.disableVertex("position");
        vinfo.unbindVertexArray();

        resetShader();
        resetModelMatrix();
    }

    void rectangle(Vecf position, uint width, uint height, Color!ubyte color, bool isFill)
    {
        if (currentShader is null)
            currentShader = getShader("Default");

        position -= camera.port.begin;

        Shapef shape;

        if (isFill)
        {
            shape = Shapef.Rectangle(position, position + vecf(width, height));
        } else
        {
            shape = Shapef.RectangleLine(position, position + vecf(width, height));
        }

        uint[] elems = [0 ,1, 2, 2, 3 ,0];

        scope vinfo = new VertexInfo!float();
        if (isFill)
            vinfo.bindFromBufferAndElem(generateBuffer(shape).generateArray, elems);
        else
            vinfo.bindFromBuffer(generateBuffer(shape).generateArray);

        vinfo.bindVertexArray();
        vinfo.bindBuffer();
        if (isFill) vinfo.bindElementBuffer();

        currentShader.enableVertex("position");
        vinfo.vertexAttribPointer(currentShader.getAttribLocation("position"), 2);

        vinfo.unbindBuffer();

        currentShader.using();
        setDefaultUniform(color);

        if (isFill)
            vinfo.draw(ShapeType.rectangle, 1);
        else
            vinfo.draw(ShapeType.line, 4);

        currentShader.disableVertex("position");
        vinfo.unbindVertexArray();
        if (isFill) vinfo.unbindElementBuffer();
        
        resetShader();
        resetModelMatrix();
    }

    void circle(Vecf position, float radius, Color!ubyte color, bool isFill)
    {
        if (currentShader is null)
            currentShader = getShader("Default");

        position -= camera.port.begin;

        Shapef shape;

        if (isFill)
        {
            shape = Shapef.Circle(position, radius);
        } else
        {
            shape = Shapef.CircleLine(position, radius);
        }

        scope vinfo = new VertexInfo!float();
        vinfo.bindFromBuffer(generateBuffer(shape).generateArray);

        vinfo.bindVertexArray();
        vinfo.bindBuffer();

        currentShader.enableVertex("position");
        vinfo.vertexAttribPointer(currentShader.getAttribLocation("position"));

        vinfo.unbindBuffer();

        currentShader.using();
        setDefaultUniform(color);

        if (isFill)
            vinfo.draw(ShapeType.circle, 1);
        else
            vinfo.draw(ShapeType.line, cast(int) shape.shapes.length);

        currentShader.disableVertex("position");
        vinfo.unbindVertexArray();

        resetShader();
        resetModelMatrix();
    }

    void roundrect(Vecf position, uint width, uint height, float radius, Color!ubyte color, bool isFill)
    {
        if (currentShader is null)
            currentShader = getShader("Default");

        position -= camera.port.begin;

        Shapef shape;

        if (isFill)
        {
            shape = Shapef.RoundRectangle(position, position + vecf(width, height), radius);
        } else
        {
            shape = Shapef.RoundRectangleLine(position,  position + vecf(width, height), radius);
        }

        scope vinfo = new VertexInfo!float();
        vinfo.bindFromBuffer(generateBuffer(shape).generateArray);

        vinfo.bindVertexArray();
        vinfo.bindBuffer();

        currentShader.enableVertex("position");
        vinfo.vertexAttribPointer(currentShader.getAttribLocation("position"));

        vinfo.unbindBuffer();

        currentShader.using();
        setDefaultUniform(color);

        if (isFill)
            vinfo.draw(ShapeType.roundrect, 1);
        else
            vinfo.draw(ShapeType.line, cast(int) shape.shapes.length);

        currentShader.disableVertex("position");
        vinfo.unbindVertexArray();
        
        resetShader();
        resetModelMatrix();
    }

    void triangle(Vecf[3] points, Color!ubyte color, bool isFill)
    {
        if (currentShader is null)
            currentShader = getShader("Default");

        points[0] = points[0] - camera.port.begin;
        points[1] = points[1] - camera.port.begin;
        points[2] = points[2] - camera.port.begin;

        Shapef shape;

        if (isFill)
        {
            shape = Shapef.Triangle(points);
        } else
        {
            shape = Shapef.TriangleLine(points);
        }

        scope vinfo = new VertexInfo!float();
        vinfo.bindFromBuffer(generateBuffer(shape).generateArray);

        vinfo.bindVertexArray();
        vinfo.bindBuffer();

        currentShader.enableVertex("position");
        vinfo.vertexAttribPointer(currentShader.getAttribLocation("position"));

        vinfo.unbindBuffer();

        currentShader.using();
        setDefaultUniform(color);

        if (isFill)
            vinfo.draw(ShapeType.triangle, 1);
        else
            vinfo.draw(ShapeType.line, cast(int) shape.shapes.length);

        currentShader.disableVertex("position");
        vinfo.unbindVertexArray();

        resetShader();
        resetModelMatrix();
    }

    void polygon(Vecf position, Vecf[] points, Color!ubyte color, bool isFill)
    {
        import std.algorithm : each;

        if (currentShader is null)
            currentShader = getShader("Default");
            
        position -= camera.port.begin;

        Shapef shape;
        points.each!((ref e) => e = position + e);

        if (isFill)
        {
            shape = Shapef.Polygon(points);
        } else
        {
            shape = Shapef.Polygon(points ~ points[0]);
        }

        scope vinfo = new VertexInfo!float();
        vinfo.bindFromBuffer(generateBuffer(shape).generateArray);

        vinfo.bindVertexArray();
        vinfo.bindBuffer();

        currentShader.enableVertex("position");
        vinfo.vertexAttribPointer(currentShader.getAttribLocation("position"));

        vinfo.unbindBuffer();

        currentShader.using();
        setDefaultUniform(color);

        if (isFill)
            vinfo.draw(ShapeType.polygon, 1);
        else
            glDrawArrays(GL_LINE_LOOP, 0, 2 * cast(int) shape.data.length);

        currentShader.disableVertex("position");
        vinfo.unbindVertexArray();

        resetShader();
        resetModelMatrix();
    }

    @property RenderType type()
    {
        return RenderType.opengl;
    }

    @property void background(Color!ubyte color)
    {
        _background = color;
        glClearColor(color.rf, color.gf, color.bf, color.af);
    }

    @property Color!ubyte background()
    {
        return _background;
    }

    void clear()
    {
        glClear(GL_COLOR_BUFFER_BIT);
    }

    void drawning()
    {
        if (_target is null)
            window.swapBuffers();
        else
            _target.drawning(this);
    }

    void blendMode(BlendMode mode)
    {
        if (mode == BlendMode.withBlend)
        {
            glEnable(GL_BLEND);
        } else
        if (mode == BlendMode.withoutBlend)
        {
            glDisable(GL_BLEND);
        }
    }

    void blendOperation(BlendFactor sfactor, BlendFactor dfactor)
    {
        glBlendFunc(glBlendFactor(sfactor), glBlendFactor(dfactor));
    }

    void currentShader(Shader!Program program)
    {
        current = program;
    }

    Shader!Program currentShader()
    {
        return current;
    }

    void currentModelMatrix(float[4][4] matrix)
    {
        _model = matrix;
    }

    float[4][4] currentModelMatrix()
    {
        return _model;
    }

    void setShader(string name, Shader!Program program)
    {
        shaders[name] = program;
    }

    Shader!Program getShader(string name)
    {
        if (name in shaders)
            return shaders[name];
        else
            return null;
    }

    void resetShader()
    {
        current = null;
    }
}

debug(GLDebug) class GLDebugRender : IRenderer
{
    import tida.vector;
    import tida.color;
    import tida.drawable;
    import tida.shader;

    public struct Operation
    {
        string name;
        
        IDrawable object;
        IDrawableEx objectEx;
        
        Vecf size;
        Vecf center;
        float angle;
        ubyte alpha;

        Color!ubyte color;
        bool isFill = true;

        Shader!Program shader;
        string shaderName;
        float[4][4] matrix;

        Vecf[] vertexs;
        float radius;

        BlendFactor sfactor;
        BlendFactor dfactor;
    }

private:
    GLRender render;
    size_t frame;
    Color!ubyte _background;

public:
    Operation[][] operations;

@safe:
    this(GLRender render)
    {
        this.render = render;    
    }

    string findShadername(Shader!Program shader)
    {
        auto shaders = render.getShaders();

        foreach (key, value; shaders)
        {
            if (value is shader)
                return key;
        }

        return "unknown";
    }

    string textReport() @safe
    {
        import std.conv : to;

        string data;
        size_t iframe = 0;

        foreach (frame; operations)
        {
            iframe++;
            data ~= "Frame " ~ iframe.to!string ~ ":\n";
            foreach (operand; frame)
            {
                data ~= operand.name ~ ":\n";
                data ~= "L color: " ~ operand.color.to!string ~ "\n";
                data ~= "L isFill: " ~ operand.isFill.to!string ~ "\n";
                data ~= "L shader: " ~ operand.shaderName ~ "\n";
                data ~= "L matrix: " ~ operand.matrix.to!string ~ "\n";
                data ~= "L vertexs: " ~ operand.vertexs.to!string ~ "\n\n";
            }
        }

        return data;
    }

    void drawFrame(int idframe) @safe
    {
        auto frame = operations[idframe];

        foreach (i; 0 .. cast(int) frame.length)
            drawOperation(idframe, i);
    }

    void drawOperation(int idframe, int idoper) @safe
    {
        auto operation = operations[idframe][idoper];
        
        if (operation.object !is null)
        {
            render.draw(operation.object, operation.vertexs[0]);
        } else
        if (operation.objectEx !is null)
        {
            render.drawEx(operation.objectEx,   operation.vertexs[0], 
                                                operation.angle, 
                                                operation.center,
                                                operation.size,
                                                operation.alpha,
                                                operation.color);
        } else
        {
            switch (operation.name)
            {
                case "tida.render.GLRender.point":
                    render.point(operation.vertexs[0], operation.color);
                break;

                case "tida.render.GLRender.line":
                    render.line([operation.vertexs[0], operation.vertexs[1]], operation.color);
                break;

                case "tida.render.GLRender.rectangle": {
                    uint width = cast(uint) (operation.vertexs[1].x - operation.vertexs[0].x);
                    uint height = cast(uint) (operation.vertexs[1].y - operation.vertexs[0].y);

                    render.rectangle(operation.vertexs[0], width, height, operation.color, operation.isFill);
                }
                break;

                case "tida.render.GLRender.triangle": 
                    render.triangle([operation.vertexs[0], operation.vertexs[1], operation.vertexs[2]],
                                    operation.color, operation.isFill);
                break;

                case "tida.render.GLRender.circle":
                    render.circle(operation.vertexs[0], operation.radius, operation.color, operation.isFill);
                break;

                case "tida.render.GLRender.roundrect": {
                    uint width = cast(uint) (operation.vertexs[1].x - operation.vertexs[0].x);
                    uint height = cast(uint) (operation.vertexs[1].y - operation.vertexs[0].y);

                    render.roundrect(operation.vertexs[0], width, height, operation.radius, operation.color, operation.isFill);   
                }
                break;

                case "tida.render.GLRender.polygon":
                    render.polygon(operation.vertexs[0], operation.vertexs[1 .. $], operation.color, operation.isFill);
                break;

                default:
                    return;
            }
        }
    }

override:
    void bindTarget(ITarget target) @trusted
    {
        Operation operation;
        operation.name = "bindTarget";

        operations[frame - 1] ~=  operation;

        render.bindTarget(target);
    }
    
    @property ITarget currentTarget() @trusted
    {
        Operation operation;
        operation.name = "currentTarget";

        operations[frame - 1] ~=  operation;

        return render.currentTarget;
    }

    void draw(IDrawable drawable, Vecf position) @trusted
    {
        Operation operation;
        operation.name = (cast(Object) drawable).toString;
        operation.object = drawable;
        operation.vertexs ~= position;
        operation.shader = render.currentShader !is null ? 
            render.currentShader : 
            render.getShader("Default");
        operation.shaderName = render.currentShader !is null ? 
            findShadername(render.currentShader) :
            "Default";

        operations[frame - 1] ~=  operation;

        render.draw(drawable, position);
    }

    /// ditto
    void drawEx(    IDrawableEx drawable, 
                    Vecf position, 
                    float angle,
                    Vecf center,
                    Vecf size,
                    ubyte alpha,
                    Color!ubyte color = rgb(255, 255, 255)) @trusted
    {
        Operation operation;
        operation.name = (cast(Object) drawable).toString;
        operation.objectEx = drawable;
        operation.vertexs ~= [position, position + (size.isVecfNaN ? vecfZero : size)];
        operation.shader = render.currentShader !is null ? 
            render.currentShader : 
            render.getShader("Default");

        operation.angle = angle;
        operation.center = center;
        operation.size = size;
        operation.alpha = alpha;

        operation.shaderName = render.currentShader !is null ? 
            findShadername(render.currentShader) :
            "Default";

        operation.color = color;

        operations[frame - 1] ~=  operation;

        render.drawEx(drawable, position, angle, center, size, alpha, color);
    }

    void clear()
    {
        frame++;
        operations.length += 1;

        Operation operation;
        operation.name = "tida.render.GLRender.clear";
        operation.color = render.background;
        operations[frame - 1] ~= operation;

        render.clear();
    }

    void drawning()
    {
        Operation operation;
        operation.name = "tida.render.GLRender.drawning";
        operations[frame - 1] ~= operation;

        render.drawning();
    }

    void point(Vecf position, Color!ubyte color)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.point";
        operation.color = color;
        operation.shader = render.currentShader !is null ? 
            render.currentShader : 
            render.getShader("Default");

        operation.shaderName = render.currentShader !is null ? 
            findShadername(render.currentShader) :
            "Default";

        operation.vertexs ~= position;
        operations[frame - 1] ~= operation;

        render.point(position, color);                            
    }
    
    void line(Vecf[2] points, Color!ubyte color)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.line";
        operation.color = color;
        operation.shader = render.currentShader !is null ? 
            render.currentShader : 
            render.getShader("Default");

        operation.shaderName = render.currentShader !is null ? 
            findShadername(render.currentShader) :
            "Default";

        operation.vertexs ~= [points[0], points[1]];
        operations[frame - 1] ~= operation;

        render.line(points, color);
    }

    void rectangle(Vecf position, uint width, uint height, Color!ubyte color, bool isFill)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.rectangle";
        operation.color = color;
        operation.shader = render.currentShader !is null ? 
            render.currentShader : 
            render.getShader("Default");

        operation.shaderName = render.currentShader !is null ? 
            findShadername(render.currentShader) :
            "Default";

        operation.vertexs ~= [position, position + vecf(width, height)];
        operation.isFill = isFill;

        operations[frame - 1] ~= operation;

        render.rectangle(position, width, height, color, isFill);
    }

    void triangle(Vecf[3] points, Color!ubyte color, bool isFill)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.triangle";
        operation.color = color;
        operation.shader = render.currentShader !is null ? 
            render.currentShader : 
            render.getShader("Default");

        operation.shaderName = render.currentShader !is null ? 
            findShadername(render.currentShader) :
            "Default";

        operation.vertexs ~= [points[0], points[1], points[2]];
        operation.isFill = isFill;

        operations[frame - 1] ~= operation;

        render.triangle(points, color, isFill);
    }

    void circle(Vecf position, float radius, Color!ubyte color, bool isFill)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.circle";
        operation.color = color;
        operation.shader = render.currentShader !is null ? 
            render.currentShader : 
            render.getShader("Default");

        operation.shaderName = render.currentShader !is null ? 
            findShadername(render.currentShader) :
            "Default";

        operation.vertexs ~= [position];
        operation.isFill = isFill;
        operation.radius = radius;

        operations[frame - 1] ~= operation;

        render.circle(position, radius, color, isFill);
    }

    void polygon(Vecf position, Vecf[] points, Color!ubyte color, bool isFill)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.polygon";
        operation.color = color;
        operation.shader = render.currentShader !is null ? 
            render.currentShader : 
            render.getShader("Default");

        operation.shaderName = render.currentShader !is null ? 
            findShadername(render.currentShader) :
            "Default";

        operation.vertexs ~= [position] ~ points;
        operation.isFill = isFill;

        operations[frame - 1] ~= operation;

        render.polygon(position, points, color, isFill);
    }

    void roundrect(Vecf position, uint width, uint height, float radius, Color!ubyte color, bool isFill)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.line";
        operation.color = color;
        operation.shader = render.currentShader !is null ? 
            render.currentShader : 
            render.getShader("Default");

        operation.shaderName = render.currentShader !is null ? 
            findShadername(render.currentShader) :
            "Default";

        operation.vertexs ~= [position, position + vecf(width, height)];
        operation.isFill = isFill;
        operation.radius = radius;

        operations[frame - 1] ~= operation;

        render.roundrect(position, width, height, radius, color, isFill);
    }

    Shader!Program getShader(string name)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.getShader";
        operation.shader = render.getShader(name);
        operation.shaderName = name;

        operations[frame - 1] ~= operation;

        return render.getShader(name);
    }

    void setShader(string name, Shader!Program shader)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.setShader";
        operation.shader = shader;
        operation.shaderName = name;

        operations[frame - 1] ~= operation;

        render.setShader(name, shader);
    }

    @property RenderType type()
    {
        return RenderType.opengl;
    }

    @property void currentModelMatrix(float[4][4] matrix)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.currentModelMatrix[set]";
        operation.matrix = matrix;

        operations[frame - 1] ~= operation;

        render.currentModelMatrix = matrix;
    }

    @property float[4][4] currentModelMatrix()
    {
        Operation operation;
        operation.name = "tida.render.GLRender.currentModeMatrix[get]";

        operations[frame - 1] ~= operation;

        return render.currentModelMatrix;
    }

    @property Camera camera()
    {
        Operation operation;
        operation.name = "tida.render.GLRender.camera[get]";

        operations[frame - 1] ~= operation;

        return render.camera;
    }

    @property void camera(Camera value)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.camera[set]";

        operations[frame - 1] ~= operation;

        render.camera = value;
    }

    @property void blendMode(BlendMode mode)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.blendMode[set]";

        operations[frame - 1] ~= operation;

        render.blendMode(mode);
    }

    @property void reshape()
    {
        Operation operation;
        operation.name = "tida.render.GLRender.reshape";
        operation.matrix = render.projection;
        operation.vertexs = [camera.port.begin, camera.port.end];

        operations[frame - 1] ~= operation;

        render.reshape();
    }

    @property Color!ubyte background()
    {
        Operation operation;
        operation.name = "tida.render.GLRender.background[get]";
        operation.color = render.background;

        operations[frame - 1] ~= operation;

        return render.background;
    }                            

    @property void background(Color!ubyte color)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.background[set]";
        operation.color = color;

        operations[frame - 1] ~= operation;

        render.background = color;
    }

    @property void currentShader(Shader!Program shader)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.currentShader[set]";
        operation.shader = shader;
        operation.shaderName = findShadername(shader);

        operations[frame - 1] ~= operation;

        render.currentShader = shader;
    }

    @property Shader!Program currentShader()
    {
        Operation operation;
        operation.name = "tida.render.GLRender.currentShader[get]";
        operation.shader = render.currentShader;
        operation.shaderName = findShadername(render.currentShader);

        operations[frame - 1] ~= operation;

        return render.currentShader;
    }

    void resetShader()
    {
        Operation operation;
        operation.name = "tida.render.GLRender.resetShader";
        operation.shader = render.currentShader;
        operation.shaderName = findShadername(render.currentShader);

        operations[frame - 1] ~= operation;

        render.resetShader();
    }

    void blendOperation(BlendFactor sfactor, BlendFactor dfactor)
    {
        Operation operation;
        operation.name = "tida.render.GLRender.blendOperation";
        operation.sfactor = sfactor;
        operation.dfactor = dfactor;

        operations[frame - 1] ~= operation;

        render.blendOperation(sfactor, dfactor);
    }
}

/++
Implementation of the interface for interacting with the rendering canvas.
+/
interface ICanvas
{
    import tida.color;
    import tida.vector;

@safe:
    /++
    Allocate memory for the canvas at the specified size.

    Params:
        width = Canvas width.
        height = Canvas height.
    +/
    void allocatePlace(uint width, uint height);

    /++
    Cleared the canvas with one color.

    Params:
        color = Cleared color.
    +/
    void clearPlane(Color!ubyte color);

    /++
    Draws a buffer to a storage object.
    +/
    void drawTo();

    /// Blending mode (blend or not).
    @property void blendMode(BlendMode mode);

    /// ditto
    @property BlendMode blendMode();

    /++
    Sets the color mixing factor (which formula to mix colors with).
    +/
    void blendOperation(BlendFactor sfactor, BlendFactor dfactor);

    /++
    Mixing factor (sfactor, dfactor).
    +/
    BlendFactor[2] blendOperation();

    /++
    Draw a point on the canvas.
    Draw only a point, the rest of the shapes are rendered.

    Params:
        position = Point position.
        color = Point color.
    +/
    void pointTo(Vecf position, Color!ubyte color);
    /++
    Set port of visibility.

    Params:
        w = Port width.
        h = Port height.
    +/
    void viewport(uint w, uint h);

    /++
    Move the visibility port to the specified coordinates.

    Params:
        x = Port x-axis position.
        y = Port y-axis position.
    +/
    void move(int x,int y);

    /++
    Canvas data.
    +/
    @property ref ubyte[] data();

    /// Canvas size.
    @property uint[2] size();

    /++
    The real size of the world, where from the world it will be drawn to 
    the size of the canvas.
    +/
    @property uint[2] portSize();

    /++
    Camera position (offset of all drawing points).
    +/
    @property int[2] cameraPosition();
}

template PointToImpl(int pixelformat, int bpc)
{
    import tida.vector;
    import tida.color;

    static assert(isValidFormat!pixelformat);

    static if(bpc == 0)
        enum bytesperpixel = bytesPerColor!pixelformat;
    else
        enum bytesperpixel = bpc;

    override void pointTo(Vecf position, Color!ubyte color)
    {
        import tida.each : Coord;
        import std.conv : to;

        position = position - vecf(cameraPosition);

        immutable scaleWidth = (cast(float) portSize[0]) / (cast(float) size[0]);
        immutable scaleHeight = (cast(float) portSize[1]) / (cast(float) size[1]);
        int w = size[0] / portSize[0] + 1;
        int h = size[0] / portSize[1] + 1;

        position = position / vecf(scaleWidth, scaleHeight);
        
        Color!ubyte bcolor;

        foreach (ix, iy; Coord(  position.x.to!int + w, position.y.to!int + h,
                                position.x.to!int, position.y.to!int))
        {
            if (ix >= size[0] || iy >= size[1] || ix < 0 || iy < 0) continue;
            immutable pos = ((iy * size[0]) + ix) * bytesperpixel;

            if (blendMode == BlendMode.withBlend) {
                Color!ubyte blendcolor;

                static if (pixelformat == PixelFormat.BGRA)
                {
                    blendcolor = rgba(  data[pos+3], 
                                        data[pos+2], 
                                        data[pos+1], 
                                        data[pos]);
                }else
                static if (pixelformat == PixelFormat.BGR)
                {
                    blendcolor = rgba(  data[pos+2],
                                        data[pos+1],
                                        data[pos],
                                        255);
                }else
                static if (pixelformat == PixelFormat.RGBA)
                {
                    blendcolor = rgba(  data[pos],
                                        data[pos+1],
                                        data[pos+2],
                                        data[pos+3]);
                }else
                static if (pixelformat == PixelFormat.RGB)
                {
                    blendcolor = rgba(  data[pos],
                                        data[pos+1],
                                        data[pos+2],
                                        255);
                }

                BlendFactor[2] factors = blendOperation();
                bcolor = BlendFunc!ubyte(factors[0], factors[1])(color, blendcolor);
            }else
                bcolor = color;

            if (pos < data.length)
            {
                static if (pixelformat == PixelFormat.BGRA)
                {
                    data[pos] = bcolor.b;
                    data[pos+1] = bcolor.g;
                    data[pos+2] = bcolor.r;
                    data[pos+3] = bcolor.a;
                }else
                static if (pixelformat == PixelFormat.BGR)
                {
                    data[pos] = bcolor.b;
                    data[pos+1] = bcolor.g;
                    data[pos+2] = bcolor.r;
                }else
                static if (pixelformat == PixelFormat.RGBA)
                {
                    data[pos] = bcolor.r;
                    data[pos+1] = bcolor.g;
                    data[pos+2] = bcolor.b;
                    data[pos+3] = bcolor.a;
                }else
                static if (pixelformat == PixelFormat.RGB)
                {
                    data[pos] = bcolor.r;
                    data[pos+1] = bcolor.g;
                    data[pos+2] = bcolor.b;
                }
            }
        }
    }
}

import tida.color : PixelFormat;

version(Posix)
class Canvas : ICanvas
{
    import x11.X, x11.Xlib, x11.Xutil;
    import tida.window;
    import tida.runtime;
    import tida.color;
    import std.exception : enforce;

private:
    GC context;
    XImage* ximage;
    tida.window.Window window;

    ubyte[] buffer;
    uint width;
    uint height;

    uint pwidth;
    uint pheight;

    int xput = 0;
    int yput = 0;

    bool isAlloc = true;

    BlendFactor[2] bfactor;
    BlendMode bmode;

@trusted:
public:
    this(tida.window.Window window, bool isAlloc = true)
    {
        this.isAlloc = isAlloc;

        this.window = window;
        if (isAlloc)
        {
            context = XCreateGC(runtime.display, this.window.handle, 0, null);
            enforce!Exception(context, "Software context is not a create!");
        }
    }

override:
    void allocatePlace(uint width, uint height)
    {
        this.width = width;
        this.height = height;

        buffer = new ubyte[](width * height * bytesPerColor!(PixelFormat.BGRA));
        if (isAlloc)
        {
            if(ximage !is null) {
                XFree(ximage);
                ximage = null;
            }

            Visual* visual = window.getVisual();
            int depth = window.getDepth();

            ximage = XCreateImage(runtime.display, visual, depth,
                ZPixmap, 0, cast(char*) buffer, width, height, 32, 0);

            enforce!Exception(ximage, "[X11] XImage is not create!");
        }
    }

    void viewport(uint w, uint h)
    {
        pwidth = w;
        pheight = h;
    }

    void move(int x, int y)
    {
        xput = x;
        yput = y;
    }

    void clearPlane(Color!ubyte color)
    {
        for (size_t i = 0; 
            i < width * height * bytesPerColor!(PixelFormat.BGRA); 
            i += bytesPerColor!(PixelFormat.BGRA))
        {
            buffer[i]   = color.b;
            buffer[i+1] = color.g;
            buffer[i+2] = color.r;
            buffer[i+3] = color.a;
        }
    }

    void drawTo()
    {
        if (isAlloc)
        {
            XPutImage(  runtime.display, window.handle, context, ximage,
                        xput, yput, xput, yput, width, height);

            XSync(runtime.display, false);
        }
    }

    BlendFactor[2] blendOperation()
    {
        return bfactor;
    }

    void blendOperation(BlendFactor sfactor, BlendFactor dfactor)
    {
        bfactor = [sfactor, dfactor];
    }

    BlendMode blendMode()
    {
        return bmode;
    }

    void blendMode(BlendMode mode)
    {
        bmode = mode;
    }

    @property ref ubyte[] data()
    {
        return buffer;
    }

    @property uint[2] size()
    {
        return [width, height];
    }

    @property uint[2] portSize()
    {
        return [pwidth, pheight];
    }

    @property int[2] cameraPosition()
    {
        return [xput, yput];
    }

    mixin PointToImpl!(PixelFormat.BGRA, 4);
}

version(Windows)
class Canvas : ICanvas
{
    import core.sys.windows.windows;
    import tida.color;
    import std.exception : enforce;

private:
    PAINTSTRUCT paintstr;
    HDC hdc;
    HDC pdc;
    HBITMAP bitmap;

    tida.window.Window window;

    ubyte[] buffer;
    uint _width;
    uint _height;
    uint _pwidth;
    uint _pheight;
    int xput;
    int yput;

    Color!ubyte _background;
    BlendMode bmode;
    BlendFactor sfactor;
    BlendFactor dfactor;

    bool _isAlloc = true;

public @trusted:
    this(tida.window.Window window, bool isAlloc = true)
    {
        this.window = window;
        _isAlloc = isAlloc;
    }

    void recreateBitmap()
    {
        if (bitmap !is null)
            DeleteObject(bitmap);

        if (hdc is null)
            hdc = GetDC((cast(Window) window).handle);

        bitmap = CreateBitmap(_width, _height, 1, 32, cast(LPBYTE) buffer);
        enforce(bitmap, "[WINAPI] bitmap is not a create!");

        if (pdc is null)
            pdc = CreateCompatibleDC(hdc);

        SelectObject(pdc, bitmap);
    }

override:
    void allocatePlace(uint width, uint height)
    {
        _width = width;
        _height = height;

        buffer = new ubyte[](_width * _height * 4);
    }

    void viewport(uint width, uint height)
    {
        _pwidth = width;
        _pheight = height;
    }

    void move(int x, int y)
    {
        xput = x;
        yput = y;
    }

    void clearPlane(Color!ubyte color)
    {
        for (size_t i = 0; i < _width * _height * 4; i += 4)
        {
            buffer[i] = color.b;
            buffer[i + 1] = color.g;
            buffer[i + 2] = color.r;
            buffer[i + 3] = color.Max;
        }
    }

    void drawTo()
    {
        if (_isAlloc)
        {
            recreateBitmap();
            BitBlt(hdc, 0, 0, _width, _height, pdc, 0, 0, SRCCOPY);
        }
    }

    BlendMode blendMode()
    {
        return bmode;
    }

    void blendMode(BlendMode mode)
    {
        bmode = mode;
    }

    BlendFactor[2] blendOperation()
    {
        return [sfactor, dfactor];
    }

    void blendOperation(BlendFactor sfactor, BlendFactor dfactor)
    {
        this.sfactor = sfactor;
        this.dfactor = dfactor;
    }

    @property ref ubyte[] data()
    {
        return buffer;
    }

    @property uint[2] size()
    {
        return [_width, _height];
    }

    @property uint[2] portSize()
    {
        return [_pwidth, _pheight];
    }

    @property int[2] cameraPosition()
    {
        return [xput, yput];
    }

    mixin PointToImpl!(PixelFormat.BGRA, 4);
}

class Software : IRenderer
{
    import tida.window;
    import tida.color;
    import tida.vector;
    import tida.shape;
    import tida.drawable;

private:
    ICanvas canvas;
    Camera _camera;
    Color!ubyte _background;

public @safe:
    this(IWindow window, bool isAlloc = true)
    {
        _camera = new Camera();
        canvas = new Canvas(cast(Window) window);

        _camera.port = Shape!float.Rectangle(vecf(0, 0), vecf(window.width, window.height));
        _camera.shape = _camera.port;

        canvas.blendMode(BlendMode.withBlend);
        canvas.blendOperation(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha);

        reshape();
    }

    this(ICanvas canvas, bool isAlloc = true)
    {
        _camera = new Camera();
        this.canvas = canvas;

        canvas.blendMode(BlendMode.withBlend);
        canvas.blendOperation(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha);
    }

override:
    @property RenderType type()
    {
        return RenderType.software; 
    }
    
    void bindTarget(ITarget target) @safe
    {
        assert(null, "Target not a support with software renderer!");
    }
    
    @property ITarget currentTarget() @safe
    {
        return null;
    }

    void reshape()
    {
        import std.conv : to;

        canvas.allocatePlace(_camera.shape.end.x.to!int,_camera.shape.end.y.to!int);
        canvas.viewport(_camera.port.end.x.to!int,_camera.port.end.y.to!int);
        canvas.move(_camera.port.begin.x.to!int,_camera.port.begin.y.to!int);
    }

    @property Camera camera()
    {
        return _camera;
    }

    @property void camera(Camera cam)
    {
        _camera = cam;
    }

    @property Color!ubyte background()
    {
        return _background;
    }

    @property void background(Color!ubyte color)
    {
        _background = color;
    }

    void point(Vecf position, Color!ubyte color)
    {
        canvas.pointTo(position, color);
    }

    void line(Vecf[2] points, Color!ubyte color)
    {
        import tida.each : Line;

        foreach (x, y; Line(points[0], points[1]))
            canvas.pointTo(vecf(x, y), color);
    }

    void rectangle( Vecf position, 
                    uint width, 
                    uint height, 
                    Color!ubyte color, 
                    bool isFill)
    {
        import tida.each : Coord;
        import std.conv : to;

        if (isFill)
        {
            foreach (ix, iy; Coord(width.to!int, height.to!int))
            {
                point(vecf(position.x.to!int + ix, position.y.to!int + iy), color);
            }
        }else
        {
            foreach (ix, iy; Coord(width.to!int, height.to!int))
            {
                point(vecf(position.x.to!int + ix,position.y.to!int), color);
                point(vecf(position.x.to!int + ix,position.y.to!int + height.to!int), color);
 
                point(vecf(position.x.to!int,position.y.to!int + iy), color);
                point(vecf(position.x.to!int + width.to!int,position.y.to!int + iy), color);
            }
        }
    }

    void roundrect(Vecf position, uint width, uint height, float radius, Color!ubyte color, bool isFill) @safe
    {
        import std.math : cos, sin;

        immutable size = vecf(width, height);
        immutable iter = 0.25;

        position += camera.port.begin;

        if (isFill)
        {
            rectangle(position + vecf(radius, 0), cast(int) (width - radius * 2), height, color, true);
            rectangle(position + vecf(0, radius), width, cast(int) (height - radius * 2), color, true);

            void rounded(Vecf pos, float a, float b, float iter) @safe
            {
                import tida.angle;

                for (float i = a; i <= b;)
                {
                    Vecf temp;
                    temp = pos + vecf(cos(i.from!(Degrees, Radians)), sin(i.from!(Degrees, Radians))) * radius;

                    line([pos, temp], color);
                    i += iter;
                }
            }

            rounded(position + vecf(radius, radius), 180, 270, iter);
            rounded(position + vecf(size.x - radius, radius), 270, 360, iter);
            rounded(position + vecf(radius, size.y - radius), 90, 180, iter);
            rounded(position + vecf(size.x - radius, size.y - radius), 0, 90, iter);
        }else
        {
            void rounded(Vecf pos, float a, float b,float iter) @safe
            {
                import tida.angle;

                for (float i = a; i <= b;)
                {
                    Vecf temp;
                    temp = pos + vecf(cos(i.from!(Degrees, Radians)), sin(i.from!(Degrees, Radians))) * radius;
                    point(temp, color);
                    i += iter;
                }
            }

            rounded(position + vecf(radius, radius), 180, 270, iter);
            rounded(position + vecf(size.x - radius, radius), 270, 360, iter);
            rounded(position + vecf(radius, size.y - radius), 90, 180, iter);
            rounded(position + vecf(size.x - radius, size.y - radius), 0, 90, iter);

            line([position + vecf(radius, 0), position + vecf(width - radius, 0)], color);
            line([position + vecf(width, radius), position + vecf(width, height - radius)], color);
            line([position + vecf(radius, height), position + vecf(width - radius, height)], color);
            line([position + vecf(0, radius), position + vecf(0, height - radius)], color);
        }
    }

    void circle(Vecf position, float radius, Color!ubyte color, bool isFill)
    {
        import tida.image, tida.each;

        int rad = cast(int) radius;
        Image buffer = new Image(rad * 2, rad * 2);
        buffer.fill(rgba(255,255,255,0));

        int x = 0;
        int y = rad;

        int X1 = rad;
        int Y1 = rad;

        int delta = 1 - 2 * cast(int) radius;
        int error = 0;

        void bufferLine(Vecf[2] points, Color!ubyte color) @safe 
        {
            foreach (ix, iy; Line(points[0], points[1]))
            {
                buffer.setPixel(ix, iy, color);
            }
        }

        while (y >= 0)
        {
            if (isFill)
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

        foreach (ix, iy; Coord(buffer.width, buffer.height))
        {
            Color!ubyte pixel;

            if ((pixel = buffer.getPixel(ix,iy)).a != 0)
            {
                point(position + vecf(ix, iy), pixel);
            }
        }
    }

    void triangle(Vecf[3] position,Color!ubyte color,bool isFill) @trusted
    {
        import tida.each;

        if (isFill)
        {
            foreach (x, y; Line(position[0], position[1])) {
                auto p = vecf(x,y);

                line([p, position[2]], color);
            }
        } else
        {
            line([position[0], position[1]], color);
            line([position[1], position[2]], color);
            line([position[2], position[0]], color);
        }
    }

    void polygon(Vecf position, Vecf[] points, Color!ubyte color, bool isFill)
    {
        import std.algorithm : each;
        points = points.dup;
        points.each!((ref e) => e = e + position);

        if (!isFill)
        {
            int next = 0;
            for (int i = 0; i < points.length; i++)
            {
                next = (i + 1 == points.length) ? 0 : i + 1;
                line([points[i],points[next]], color);
            }
        }else
        {
            import std.algorithm : minElement, maxElement;
            import tida.collision : placeLineLineImpl;

            float maxX = points.maxElement!"a.x".x;
            float minY = points.minElement!"a.y".y;
            float maxY = points.maxElement!"a.y".y;
            float minX = points.minElement!"a.x".x;

            alias LineIter = Vecf[2];

            LineIter[] drowning;

            for (float i = minY; i <= maxY; i += 1.0f)
            {
                Vecf firstPoint = vecfNaN;
                float lastX = minX > position.x ? position.x : minX;

                for (float j = lastX; j <= maxX; j += 1.0f)
                {
                    size_t next = 0;
                    for (size_t currPointI = 0; currPointI < points.length; currPointI++)
                    {
                        next = (currPointI + 1 == points.length) ? 0 : currPointI + 1;

                        auto iter = placeLineLineImpl(  [vecf(lastX, i), vecf(j, i)],
                                                        [points[currPointI], points[next]]);
                        if (!iter.isVecfNaN) {
                            if (firstPoint.isVecfNaN)
                            {
                                firstPoint = vecf(j, i);
                            } else
                            {
                                drowning ~= [firstPoint, vecf(j, i)];
                                firstPoint = vecfNaN;
                            }

                            lastX = j;
                        }
                    }             
                }
            }

            foreach (e; drowning)
            {
                line(e, color);
            }
        }
    }

    void clear()
    {
        import std.conv : to;

        canvas.move(_camera.port.begin.x.to!int,_camera.port.begin.y.to!int);
        canvas.clearPlane(_background);
    }

    void drawning()
    {
        canvas.drawTo();
    }

    @property void blendMode(BlendMode mode)
    {
        canvas.blendMode(mode);
    }

    void blendOperation(BlendFactor sfactor, BlendFactor dfactor)
    {
        canvas.blendOperation(sfactor, dfactor);
    }

    void draw(IDrawable drawable, Vecf position) @safe
    {
        position -= camera.port.begin;
        drawable.draw(this, position);
    }

    /// ditto
    void drawEx(    IDrawableEx drawable, 
                    Vecf position, 
                float angle,
                Vecf center,
                Vecf size,
                ubyte alpha,
                Color!ubyte color = rgb(255, 255, 255)) @safe
    {
        position -= camera.port.begin;
        drawable.drawEx(this, position, angle, center, size, alpha, color);
    }

    import tida.shader;

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

    override void currentModelMatrix(float[4][4] matrix) @safe @property
    {
        assert(null, "There are no matrix in this version of the render.");
    }

    override float[4][4] currentModelMatrix() @safe @property
    {
        assert(null, "There are not matrix in this version of the render.");
    }
}

import tida.window;

/++
Creates a render based on hardware acceleration capabilities.
It should be used if the program does not use intentional hardware
acceleration objects.

Params:
    window = Window object.
+/
IRenderer createRenderer(IWindow window) @trusted
{
    import bindbc.opengl;

    if (isOpenGLLoaded())
    {
        GLSupport ver = loadedOpenGLVersion();
        if (ver != GLSupport.gl11 && ver != GLSupport.gl12 &&
            ver != GLSupport.gl13 && ver != GLSupport.gl14 &&
            ver != GLSupport.gl15)
        {
            return new GLRender(window);
        }
    }

    return new Software(window, true);
}

import tida.image;
import tida.vector;

Image renderRead(IRenderer render, Vecf position, int width, int height) @trusted
{
    import tida.gl;
    import std.conv : to;

    Image image = new Image(width, height);
    glReadPixels(   position.x.to!int, position.y.to!int,
                    width, height, GL_RGBA, GL_UNSIGNED_BYTE, cast(void*) image.pixels);

    return image;
}