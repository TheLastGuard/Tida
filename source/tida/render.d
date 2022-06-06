module tida.render;

import tida.graphics.gapi;

/++
Camera control object in render,
+/
class Camera
{
    import  tida.vector,
            tida.shape;
            //tida.instance;

    struct CameraObject
    {
        Vector!float* position;
        Vector!float size;
    }

private:
    Shape!float _port;
    Shape!float _shape;
    CameraObject object;
    Vector!float _trackDistance = vec!float(4.0f, 4.0f);
    Vector!float _sizeRoom = vecNaN!float;


public @safe nothrow pure:
    /// The allowed room size for camera scrolling.
    @property Vector!float sizeRoom()
    {
        return _sizeRoom;
    }

    /// The allowed room size for camera scrolling.
    @property Vector!float sizeRoom(Vector!float value)
    {
        return _sizeRoom = value;
    }

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

    ///++
    //A method for binding a specific object to a camera to track it.
    //
    //Params:
    //    instance =  An object in the scene that will be monitored by the camera.
    //                The size is calculated from the object's touch mask.
    //+/
    //void bindObject(Instance instance)
    //{
    //    object.position = &instance.position;
    //    object.size = instance.mask.calculateSize();
    //}

    /++
    A method that reproduces the process of tracking an object.
    +/
    void followObject()
    {
        Vector!float velocity = vecZero!float;

        if (object.position.x < port.begin.x + _trackDistance.x)
        {
            velocity.x = (port.begin.x + _trackDistance.x) - object.position.x;
        } else
        if (object.position.x + object.size.x> port.begin.x + port.end.x - _trackDistance.x)
        {
            velocity.x = (port.begin.x + port.end.x - _trackDistance.x) - (object.position.x + object.size.x);
        }

        if (object.position.y < port.begin.y + _trackDistance.y)
        {
            velocity.y = (port.begin.y + _trackDistance.y) - object.position.y;
        } else
        if (object.position.y + object.size.y > port.begin.y + port.end.y - _trackDistance.y)
        {
            velocity.y = (port.begin.y + port.end.y - _trackDistance.y) - (object.position.y + object.size.y);
        }

        immutable preBegin = port.begin - velocity;

        if (!_sizeRoom.isVectorNaN)
        {
            if (preBegin.x > 0 &&
                preBegin.x + port.end.x < _sizeRoom.x)
            {
                port = Shapef.Rectangle(vec!float(preBegin.x, port.begin.y), port.end);
            }

            if (preBegin.y > 0 &&
                preBegin.y + port.end.y < _sizeRoom.y)
            {
                port = Shapef.Rectangle(vec!float(port.begin.x, preBegin.y), port.end);
            }
        } else
            port = Shapef.Rectangle(preBegin, port.end);
    }

    /// Distance between camera boundaries and subject for the scene to move the camera's view.
    @property Vector!float trackDistance()
    {
        return _trackDistance;
    }

    /// Distance between camera boundaries and subject for the scene to move the camera's view.
    @property Vector!float trackDistance(Vector!float value)
    {
        return _trackDistance = value;
    }

    /++
    The port is the immediate visible part in the "room". The entire area in
    the world that must be covered in the field of view.
    +/
    @property Shape!float port()
    {
        return _port;
    }

    /// ditto
    @property Shape!float port(Shape!float value)
    {
        return _port = value;
    }

    /++
    The size of the visible part in the plane of the window.
    +/
    @property Shape!float shape()
    {
        return _shape;
    }

    /// ditto
    @property Shape!float shape(Shape!float value)
    {
        return _shape = value;
    }

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

/++
An interface for rendering objects to a display or other storehouse of pixels.
+/
interface IRenderer
{
    import  tida.color,
            tida.vector,
            tida.drawable,
            tida.matrix;

@safe:
    /// Updates the rendering surface if, for example, the window is resized.
    void reshape();

    ///Camera for rendering.
    @property void camera(Camera camera);

    /// Camera for rendering.
    @property Camera camera();

    @property IGraphManip api();

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

    /// Cleans the surface by filling it with color.
    void clear() @safe;

    /// Outputs the buffer to the window.
    void drawning() @safe;

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
    void setShader(string name, IShaderProgram program) @safe;

    /++
    Pulls a shader from memory, getting it by name. Returns a null pointer
    if no shader is found.
    Params:
        name = Shader name.
    +/
    IShaderProgram getShader(string name) @safe;

    /// The current shader for the next object rendering.
    void currentShader(IShaderProgram program) @safe @property;

    /// The current shader for the next object rendering.
    IShaderProgram currentShader() @safe @property;

    IShaderProgram mainShader() @safe @property;

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

class Render : IRenderer
{
    import tida.window;
    import  tida.color,
            tida.vector,
            tida.drawable,
            tida.matrix,
            tida.shape,
            tida.meshgen;

    enum vertexShaderSource = "#version 450

    layout(location = 0) in vec2 positions;

    uniform mat4 projection;
    uniform mat4 model;

    void main() {
        gl_Position = projection * model * vec4(positions, 0.0, 1.0);
    }";

    enum fragmentShaderSource = "#version 450

    uniform vec4 color = vec4(1.0f, 1.0f, 1.0f, 1.0f);

    layout(location = 0) out vec4 outColor;

    void main() {
        outColor = color;
    }";

    IGraphManip gapi;
    IShaderProgram defaultShader;
    mat4 projection;

    Camera _camera;
    Color!ubyte _background;

    IShaderProgram[string] shaders;

    IShaderProgram _currentShader;
    mat4 _currentModel = identity();

    this(Window window) @safe
    {
        gapi = createGraphManip();
        gapi.initialize();
        gapi.createAndBindSurface(
            window,
            GraphicsAttributes(8, 8, 8, 8, 32, BufferMode.doubleBuffer)
        );

        gapi.viewport(0, 0, window.width, window.height);

        auto vertex = gapi.createShader(StageType.vertex);
        vertex.loadFromSource(vertexShaderSource);

        auto fragment = gapi.createShader(StageType.fragment);
        fragment.loadFromSource(fragmentShaderSource);

        defaultShader = gapi.createShaderProgram();
        defaultShader.attach(vertex);
        defaultShader.attach(fragment);
        defaultShader.link();

        _currentShader = defaultShader;

        shaders["Default"] = defaultShader;

        _camera = new Camera();
        _camera.port = Shapef.Rectangle(vecf(0, 0), vecf(window.width, window.height));
        _camera.shape = _camera.port;

        gapi.blendFactor(BlendFactor.SrcAlpha, BlendFactor.OneMinusSrcAlpha, true);
        reshape();
    }

    void setDefaultUniform(Color!ubyte color) @safe
    {
        _currentShader.setUniform(
            _currentShader.getUniformID("projection"),
            projection
        );

        _currentShader.setUniform(
            _currentShader.getUniformID("model"),
            translate(_currentModel, _camera.port.x, _camera.port.y, 0)
        );

        _currentShader.setUniform(
            _currentShader.getUniformID("color"),
            [color.rf, color.gf, color.bf, color.af]
        );
    }

override:
    IGraphManip api()
    {
        return gapi;
    }

    void reshape() @safe
    {
        gapi.viewport(
            -_camera.shape.x,
            -_camera.shape.y,
            _camera.shape.width,
            _camera.shape.height
        );

        projection = ortho(0.0, _camera.port.end.x, _camera.port.end.y, 0.0, -1.0, 1.0);
    }

    void camera(Camera value) @safe
    {
        this._camera = value;
    }

    Camera camera() @safe
    {
        return _camera;
    }

    void point(Vecf vec, Color!ubyte color) @trusted
    {
        gapi.begin();

        immutable buffer = gapi.createImmutableBuffer(BufferType.array);
        buffer.bindData([
            vec
        ]);

        auto vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(vertInfo);
        }

        gapi.bindProgram(_currentShader);
        gapi.bindVertexInfo(vertInfo);

        _currentModel = translate(_currentModel, -camera.port.begin.x, -camera.port.begin.y, 0);

        gapi.begin();
        setDefaultUniform(color);
        gapi.draw(ModeDraw.points, 0, 1);

        resetShader();
        resetModelMatrix();
    }

    void line(Vecf[2] points, Color!ubyte color) @trusted
    {
        immutable buffer = gapi.createImmutableBuffer();
        buffer.bindData([
            points[0], points[1]
        ]);

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(vertInfo);
        }

        gapi.bindVertexInfo(vertInfo);
        gapi.bindProgram(_currentShader);

        _currentModel = translate(_currentModel, -camera.port.begin.x, -camera.port.begin.y, 0);

        gapi.begin();
        setDefaultUniform(color);
        gapi.draw(ModeDraw.lineStrip, 0, 2);

        resetShader();
        resetModelMatrix();
    }

    void rectangle( Vecf position,
                    uint width,
                    uint height,
                    Color!ubyte color,
                    bool isFill) @trusted
    {
        immutable buffer = gapi.createImmutableBuffer();
        buffer.bindData([
            position,
            position + vecf(width, 0),
            position + vecf(width, height),
            position + vecf(0, height)
        ]);

        immutable indexBuffer = gapi.createImmutableBuffer(BufferType.element);

        uint[] index = isFill ?
            [0, 1, 2, 0, 3, 2] :
            [0, 1, 1, 2, 2, 3, 3, 0];

        indexBuffer.bindData(index);

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.bindBuffer(indexBuffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(indexBuffer);
            destroy(vertInfo);
        }

        gapi.bindProgram(_currentShader);
        gapi.bindVertexInfo(vertInfo);

        _currentModel = translate(_currentModel, -camera.port.begin.x, -camera.port.begin.y, 0);

        gapi.begin();
        setDefaultUniform(color);
        gapi.drawIndexed(
            isFill ? ModeDraw.triangle : ModeDraw.line,
            cast(uint) index.length
        );

        resetShader();
        resetModelMatrix();
    }

    void circle(Vecf position,
                float radius,
                Color!ubyte color,
                bool isFill) @trusted
    {
        immutable meshData = generateBuffer(
            isFill ?
                Shapef.Circle(position, radius) :
                Shapef.CircleLine(position, radius)
        );

        immutable buffer = gapi.createImmutableBuffer();
        buffer.bindData(meshData);

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(vertInfo);
        }

        gapi.bindVertexInfo(vertInfo);
        gapi.bindProgram(_currentShader);

        _currentModel = translate(_currentModel, -camera.port.begin.x, -camera.port.begin.y, 0);

        gapi.begin();
        setDefaultUniform(color);
        gapi.draw(
            isFill ? ModeDraw.triangleStrip : ModeDraw.lineStrip,
            0,
            cast(uint) meshData.length * 2 / 4
        );

        resetShader();
        resetModelMatrix();
    }

    void triangle(Vecf[3] points, Color!ubyte color, bool isFill) @trusted
    {
        immutable buffer = gapi.createImmutableBuffer();
        buffer.bindData([
            points[0], points[1], points[2]
        ]);

        immutable indexBuffer = gapi.createImmutableBuffer(BufferType.element);

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);

        if (!isFill)
        {
            indexBuffer.bindData([0, 1, 1, 2, 2, 0]);
            vertInfo.bindBuffer(indexBuffer);
        }

        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(indexBuffer);
            destroy(vertInfo);
        }

        gapi.bindVertexInfo(vertInfo);
        gapi.bindProgram(_currentShader);

        _currentModel = translate(_currentModel, -camera.port.begin.x, -camera.port.begin.y, 0);

        gapi.begin();
        setDefaultUniform(color);

        if (isFill)
            gapi.draw(ModeDraw.triangle, 0, 3);
        else
            gapi.drawIndexed(ModeDraw.line, 6);

        resetShader();
        resetModelMatrix();
    }

    void roundrect( Vecf position,
                    uint width,
                    uint height,
                    float radius,
                    Color!ubyte color,
                    bool isFill) @trusted
    {
        immutable meshData = generateBuffer(
            isFill ?
                Shapef.RoundRectangle(position, position + vecf(width, height), radius) :
                Shapef.RoundRectangleLine(position, position + vecf(width, height), radius)
        );

        immutable buffer = gapi.createImmutableBuffer();
        buffer.bindData(meshData);

        IVertexInfo vertInfo = gapi.createVertexInfo();
        vertInfo.bindBuffer(buffer);
        vertInfo.vertexAttribPointer([
            AttribPointerInfo(0, 2, TypeBind.Float, 2 * float.sizeof, 0)
        ]);

        scope(exit)
        {
            destroy(buffer);
            destroy(vertInfo);
        }

        gapi.bindVertexInfo(vertInfo);
        gapi.bindProgram(_currentShader);

        _currentModel = translate(_currentModel, -camera.port.begin.x, -camera.port.begin.y, 0);

        gapi.begin();
        setDefaultUniform(color);
        gapi.draw(
            isFill ? ModeDraw.triangleStrip : ModeDraw.lineStrip,
            0,
            cast(uint) meshData.length * 2 / 2
        );

        resetShader();
        resetModelMatrix();
    }

    void clear() @safe
    {
        gapi.clear();
    }

    void drawning() @safe
    {
        gapi.drawning();
    }

    void blendOperation(BlendFactor sfactor, BlendFactor dfactor) @safe
    {
        gapi.blendFactor(sfactor, dfactor, true);
    }

    void background(Color!ubyte value) @safe @property
    {
        _background = value;

        gapi.clearColor(value);
    }

    /// ditto
    Color!ubyte background() @safe @property
    {
        return _background;
    }

    void setShader(string name, IShaderProgram program) @safe
    {
        shaders[name] = program;
    }

    IShaderProgram getShader(string name) @safe
    {
        if (name in shaders)
            return shaders[name];
        else
            return null;
    }

    IShaderProgram mainShader() @safe @property
    {
        return defaultShader;
    }

    void currentShader(IShaderProgram program) @safe @property
    {
        _currentShader = program;
        if (_currentShader is null)
            _currentShader = defaultShader;
    }

    IShaderProgram currentShader() @safe @property
    {
        return _currentShader;
    }

    void resetShader() @safe
    {
        _currentShader = defaultShader;
    }

    float[4][4] currentModelMatrix() @safe @property
    {
        return _currentModel;
    }

    void currentModelMatrix(float[4][4] matrix) @safe @property
    {
        _currentModel = matrix;
    }

    void draw(IDrawable drawable, Vecf position) @safe
    {
        _currentModel = _currentModel.translate(_camera.port.begin.x, _camera.port.begin.y, 0f);
        drawable.draw(this, position);
    }

    void drawEx(    IDrawableEx drawable,
                    Vecf position,
                    float angle,
                    Vecf center,
                    Vecf size,
                    ubyte alpha,
                    Color!ubyte color = rgb(255, 255, 255)) @safe
    {
       _currentModel = _currentModel.translate(_camera.port.begin.x, _camera.port.begin.y, 0f);
        drawable.drawEx(this, position, angle, center, size, alpha, color);
    }
}
