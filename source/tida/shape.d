/++
    This module describes shapes for drawing, 
    checking and other things related to the work of shapes.

    Authors: TodNaz
    License: MIT
+/
module tida.shape;

/++
    Shape type.
+/
enum ShapeType
{
    unknown, /// Unknown
    point, /// Point
    line, /// Line
    rectangle, /// Rectangle
    circle, /// Circle
    triangle, /// Triangle
    multi /// Several shapes in one.
}

/++
    Figure description structure.
+/
public struct Shape
{
    import tida.vector;

    public
    {
        ShapeType type; /// Shape type
        Shape[] shapes; /++ A set of figures. Needed for the type when you need 
                            to make one shape from several. +/
    }   

    private
    {
        float _radious;
        Vecf _trType;
        Vecf _begin;
        Vecf _end;
    }

    /// The beginning of the figure.
    public Vecf begin() @safe @property nothrow
    {
        return _begin;
    }

    /// The end of the figure.
    public Vecf end() @safe @property nothrow
    in
    {
        assert(type != ShapeType.point &&
               type != ShapeType.circle,"This shape does not support end coordinates!");
    }body
    {
        return _end;
    }

    /// The beginning of the figure.
    public Vecf begin() @safe @property nothrow immutable
    {
        return _begin;
    }

    /// The end of the figure.
    public Vecf end() @safe @property nothrow immutable
    in
    {
        assert(type != ShapeType.point &&
               type != ShapeType.circle,"This shape does not support end coordinates!");
    }body
    {
        return _end;
    }

    /// The beginning of the figure.
    public void begin(Vecf vec) @safe @property nothrow
    {
        _begin = vec;
    }

    /// The end of the figure.
    public void end(Vecf vec) @safe @property nothrow
    in
    {
        assert(type != ShapeType.point &&
               type != ShapeType.circle,"This shape does not support end coordinates!");
    }body
    {
        _end = vec;
    }

    /// The beginning of the figure along the x-axis.
    public float x() @safe @property nothrow
    {
        return begin.x;
    }

    /// The beginning of the figure along the y-axis.
    public float y() @safe @property nothrow
    {
        return begin.y;
    }

    /// The beginning of the figure along the x-axis.
    public void x(float value) @safe @property nothrow
    {
        begin.x = value;
    }

    /// The beginning of the figure along the y-axis.
    public void y(float value) @safe @property nothrow
    {
        begin.x = value;
    }

    /// The beginning of the figure along the x-axis.
    public float x() @safe @property nothrow immutable
    {
        return begin.x;
    }

    /// The beginning of the figure along the y-axis.
    public float y() @safe @property nothrow immutable
    {
        return begin.y;
    }
    
    /// The end of the figure along the x-axis.
    public float endX() @safe @property nothrow
    {
        return end.x;
    }

    /// The end of the figure along the y-axis.
    public float endY() @safe @property nothrow
    {
        return end.y;
    }

    /// The end of the figure along the x-axis.
    public float endX() @safe @property nothrow immutable
    {
        return end.x;
    }

    /// The end of the figure along the y-axis.
    public float endY() @safe @property nothrow immutable
    {
        return end.y;
    }

    /// The radious the figure.
    public float radious() @safe @property nothrow
    in
    {
        assert(type == ShapeType.circle,"This is not a circle!");
    }body
    {
        return _radious;
    }

    /// The radious the figure.
    public float radious() @safe @property nothrow immutable
    in
    {
        assert(type == ShapeType.circle,"This is not a circle!");
    }body
    {
        return _radious;
    }

    /// ditto
    public void radious(float value) @safe @property nothrow
    in
    {
        assert(type == ShapeType.circle,"This is not a circle!");
    }body
    {
        _radious = value;
    }

    /// The top of the triangle.
    public Vecf vertex(uint num)() @safe @property nothrow
    in
    {
        static assert(num < 3,"The triangle has only three vertices! (0 .. 2)");
        assert(type == ShapeType.triangle,"This is not a triangle!");
    }body
    {
        static if(num == 0)
            return begin;
        else
        static if(num == 1)
            return end;
        else
        static if(num == 2)
            return _trType;
    }

    /// ditto
    public void vertex(uint num)(Vecf value) @safe @property nothrow
    in
    {
        static assert(num < 3,"The triangle has only three vertices! (0 .. 2)");
        assert(type == ShapeType.triangle,"This is not a triangle!");
    }body
    {
        static if(num == 0)
            begin = value;
        else
        static if(num == 1)
            end = value;
        else
        static if(num == 2)
            _trType = value;
    }

    alias left = x;
    alias top = y;
    alias right = endX;
    alias bottom = endY;

    string toString() @safe immutable
    {
        import std.conv : to;

        if(type == ShapeType.point) {
            return "Shape.Point(x: "~begin.x.to!string~",y: "~begin.y.to!string~")";
        }else
        if(type == ShapeType.rectangle) {
            return "Shape.Rectangle(x: "~begin.x.to!string~",y: "~begin.y.to!string~","~
            "endX: "~end.x.to!string~", endY: "~end.y.to!string~")";
        }

        return "Shape.Unknown()";
    }

    string toString() @safe
    {
        import std.conv : to;

        if(type == ShapeType.point) {
            return "Shape.Point(x: "~begin.x.to!string~",y: "~begin.y.to!string~")";
        }else
        if(type == ShapeType.rectangle) {
            return "Shape.Rectangle(x: "~begin.x.to!string~",y: "~begin.y.to!string~","~
            "endX: "~end.x.to!string~", endY: "~end.y.to!string~")";
        }

        return "Shape.Unknown()";
    }

    /++
        Collects several figures into one.

        Params:
            shapes = A collection of figures.
            pos = The relative position of such a figure.

        Returns:
            A shapes assembled from many shapes.
    +/
    static Shape Multi(Shape[] shapes,Vecf pos = Vecf(0,0)) @safe 
    {
        Shape shape;

        shape.type = ShapeType.multi;
        shape.shapes = shapes;
        shape.begin = pos;

        return shape;
    }

    /++
        Creates a point.

        Params:
            point = Point position.

        Returns:
            Point.
    +/
    static Shape Point(Vecf point) @safe
    {
        Shape shape;

        shape.type = ShapeType.point;
        shape.begin = point;

        return shape;
    }

    /++
        Creates a line from two points.

        Params:
            begin = Line begin.
            end = Line end. 

        Returns:
            Line.
    +/ 
    static Shape Line(Vecf begin,Vecf end) @safe
    {
        Shape shape;

        shape.type = ShapeType.line;
        shape.begin = begin;
        shape.end = end;

        return shape;
    }

    /++
        Creates a rectangle. 

        Params:
            begin = Rectangle begin.
            end = Rectangle end.

        Returns:
            Rectangle. 
    +/
    static Shape Rectangle(Vecf begin,Vecf end) @safe
    {
        Shape shape;

        shape.type = ShapeType.rectangle;
        shape.begin = begin;
        shape.end = end;

        return shape;
    }

    /++
        Creates a circle.

        Params:
            pos = Circle position.
            r = Circle radious.  

        Returns:
            Circle. 
    +/
    static Shape Circle(Vecf pos,float r) @safe
    {
        Shape shape;

        shape.type = ShapeType.circle;
        shape.begin = pos;
        shape.radious = r;

        return shape;
    }

    /++
        Creates a triangle.

        Params:
            vertexs = Triangle vertexs.

        Returns:
            Tringle. 
    +/
    static Shape Triangle(Vecf[3] vertexs) @safe
    {
        Shape shape;

        shape.type = ShapeType.triangle;
        shape.vertex!0 = vertexs[0];
        shape.vertex!1 = vertexs[1];
        shape.vertex!2 = vertexs[2];

        return shape;
    }
}