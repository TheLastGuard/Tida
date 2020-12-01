/++

+/
module tida.graph.camera;

struct Camera
{
    import tida.shape, tida.vector;

    private
    {
        Shape _shape = Shape.Rectangle(Vecf(0,0),Vecf(0,0));
        Shape _port = Shape.Rectangle(Vecf(0,0),Vecf(0,0));
    }

    this(Shape dvShape)
    in
    {
        assert(dvShape.type == ShapeType.rectangle);
    }body
    {
        this._shape = dvShape;
    }

    public void shape(Shape dvShape) @safe @property
    in
    {
        assert(dvShape.type == ShapeType.rectangle);
    }body
    {
        this._shape = dvShape;
    }

    public Shape shape() @safe @property
    {
        return _shape;
    }

    public void port(Shape dvPort) @safe @property
    in
    {
        assert(dvPort.type == ShapeType.rectangle);
    }body
    {
        _port = dvPort;
    }

    public Shape port() @safe @property
    {
        return _port;
    }
}