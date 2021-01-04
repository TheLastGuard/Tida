/++
    A module for working with a camera.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.graph.camera;

/++
    Camera object.
+/
class Camera
{
    import tida.shape, tida.vector;

    private
    {
        Shape _shape = Shape.Rectangle(Vecf(0,0),Vecf(0,0));
        Shape _port = Shape.Rectangle(Vecf(0,0),Vecf(0,0));
    }

    this() @safe {}

    this(Shape dvShape)
    in(dvShape.type == ShapeType.rectangle)
    body
    {
        this._shape = dvShape;
    }

    /// Port on the window.
    void shape(Shape dvShape) @safe @property
    in(dvShape.type == ShapeType.rectangle)
    body
    {
        this._shape = dvShape;
    }

    /// Port on the window.
    Shape shape() @safe @property
    {
        return _shape;
    }

    /// Port in the plane.
    void port(Shape dvPort) @safe @property
    in(dvPort.type == ShapeType.rectangle)
    body
    {
        _port = dvPort;
    }

    /// Port in the plane.
    Shape port() @safe @property
    {
        return _port;
    }
}