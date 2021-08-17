/++
    This module describes shapes for drawing, 
    checking and other things related to the work of shapes.

    Forms are of the following types:
    * `Unknown` - Forms are of the following types:
    * `Point` - Dot. The simplest of the simplest forms. Only origin parameters are valid.
    * `line` - More complex form. Has the origin and the end of the coordinates of its two points. 
               By default, this is a line. 
    * 'rectangle' - Rectangle shape. By default, such a rectangle is considered to be solid.
    * `circle` - Circle shape. By default, it is considered to be solid.
    * `triangle` - Triangle shape. It is believed to be solid.
    * `multi` - A shape that combines several shapes, which will eventually give a single shape.
        Here you can, for example, create a non-solid polygon:
        ---
        /*
            Such a rectangle can also be created using the function
            `Shape.RectangleLine(begin,end)`.
        */
        auto rectangle_nonSolid = Shape.Multi([
            Shape.Line(Vecf(0,0),Vecf(32,0)),
            Shape.Line(Vecf(32,0),Vecf(32,32)),
            Shape.Line(Vecf(0,0),Vecf(0,32)),
            Shape.Line(Vecf(0,32),Vecf(32,32))
        ], Vecf(0,0));
        ---

    All such types are specified in enum `ShapeType`.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
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
    roundrect, /// Roundrect
    polygon, /// Polygon
    multi /// Several shapes in one.
}

/++
    Figure description structure.
+/
struct Shape
{
    import tida.vector;

    public
    {
        ShapeType type; /// Shape type
        Shape[] shapes; /++ A set of figures. Needed for the type when you need 
                            to make one shape from several. +/
        Vecf[] data; /// Polygon data
        bool isSolid = false; /// Is the polygon solid?
    }   

    private
    {
        float _radius;
        Vecf _trType;
        Vecf _begin;
        Vecf _end;
    }

    /++
        Converting a form to another form of its presentation.

        Params:
            T = What to convention?

        Example:
        ---
        Vecf[][] points = myPolygon.to!Vecf[][];
        ---
    +/
    T to(T)() @safe @property 
    {
        static if(is(T : Vecf)) {
            return begin;
        }else
        static if(is(T : Vecf[])) {
            if(type == ShapeType.point || type == ShapeType.circle) {
                return [begin];
            }else
            if(type == ShapeType.line || type == ShapeType.rectangle) {
                return [begin,end];
            }else
            if(type == ShapeType.triangle) {
                return [this.vertex!0,this.vertex!1,this.vertex!2];
            }else
            if(type == ShapeType.multi) {
                Vecf[] temp;
                foreach(shape; shapes) {
                    temp ~= this.to!T;
                }
            }

            return [];
        }else
        static if(is(T : Vecf[][])) {
            if(type != ShapeType.unknown) {
                if(type != ShapeType.multi) {
                    return [to!Vecf[]];
                }else {
                    Vecf[][] temp;
                    foreach(shape; shapes) {
                        temp ~= this.to!Vecf[];
                    }
                }
            }
        }
    }

    /// The beginning of the figure.
    Vecf begin() @safe @property nothrow pure inout
    {
        return _begin;
    }

    /// The end of the figure.
    Vecf end() @safe @property nothrow pure inout
    in(type != ShapeType.point && type != ShapeType.circle && type != ShapeType.polygon,
    "This shape does not support end coordinates!")
    do
    {
        return _end;
    }

    /++
        Move shape
    +/
    void move(Vecf pos) @safe nothrow pure
    {
        _begin = _begin + pos;

        if(type == ShapeType.line || type == ShapeType.rectangle) {
            _end = _end + pos;
        }
    }

    /// The beginning of the figure.
    void begin(Vecf vec) @safe @property nothrow pure
    {
        _begin = vec;
    }

    /// The end of the figure.
    void end(Vecf vec) @safe @property nothrow pure
    in(type != ShapeType.point && type != ShapeType.circle && type != ShapeType.polygon,
        "This shape does not support end coordinates!")
    do
    {
        _end = vec;
    }

    /// The beginning of the figure along the x-axis.
    float x() @safe @property nothrow pure inout
    {
        return begin.x;
    }

    /// The beginning of the figure along the y-axis.
    float y() @safe @property nothrow pure inout
    {
        return begin.y;
    }

    /// The beginning of the figure along the x-axis.
    void x(float value) @safe @property nothrow pure
    {
        begin.x = value;
    }

    /// The beginning of the figure along the y-axis.
    void y(float value) @safe @property nothrow pure
    {
        begin.x = value;
    }
    
    /// The end of the figure along the x-axis.
    float endX() @safe @property nothrow pure inout
    {
        return end.x;
    }

    /// The end of the figure along the y-axis.
    float endY() @safe @property nothrow pure inout
    {
        return end.y;
    }

    alias left = x; /// Rectangle left
    alias right = endX; /// Rectangle right
    alias top = y; /// Rectangle top
    alias bottom = endY; /// Rectange bottom

    /// The radius the figure.
    float radius() @safe @property nothrow pure inout
    in(type == ShapeType.circle || type == ShapeType.roundrect,"This is not a circle!")
    do
    {
        return _radius;
    }

    /// ditto
    void radius(float value) @safe @property nothrow pure
    in(type == ShapeType.circle || type == ShapeType.roundrect,"This is not a circle!")
    do
    {
        _radius = value;
    }

    /// The top of the triangle.
    Vecf vertex(uint num)() @safe @property nothrow pure inout
    in
    {
        static assert(num < 3,"The triangle has only three vertices! (0 .. 2)");
        assert(type == ShapeType.triangle,"This is not a triangle!");
    }do
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

    /// Shape width
    float width() @safe @property nothrow pure inout
    in(type == ShapeType.rectangle || type == ShapeType.roundrect,"This is not a rectangle!")
    do
    {
        return end.x - begin.x;
    }

    /// Shape height
    float height() @safe @property nothrow pure inout
    in(type == ShapeType.rectangle || type == ShapeType.roundrect,"This is not a rectangle!")
    do
    {
        return end.y - begin.y;
    }

    /// Shape width
    void width(float value) @safe @property nothrow pure
    in(type == ShapeType.rectangle || type == ShapeType.roundrect,"This is not a rectangle!")
    do
    {
        _end = begin + Vecf(value,height);
    }

    /// Shape height
    void height(float value) @safe @property nothrow pure
    in(type == ShapeType.rectangle || type == ShapeType.roundrect,"This is not a rectangle!")
    do
    {
        _end = begin + Vecf(width,value);
    }

    /// The top of the triangle.
    Vecf[] vertexs() @safe @property nothrow pure inout
    {
        return [begin,end,_trType];
    }

    /// ditto
    void vertex(uint num)(Vecf value) @safe @property nothrow pure
    in
    {
        static assert(num < 3,"The triangle has only three vertices! (0 .. 2)");
        assert(type == ShapeType.triangle,"This is not a triangle!");
    }do
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

    /// Line length.
    float length() @safe @property nothrow pure inout
    in(type == ShapeType.line,"This is not a line!")
    do
    {
        import std.math : sqrt;

        auto distX = begin.x - end.x;
        auto distY = begin.y - end.y;

        return sqrt((distX * distX) + (distY * distY));
    }

    /// Line length.
    void length(float value) @safe @property nothrow pure
    in(type == ShapeType.line,"This is not a line!")
    do
    {
        import tida.angle;

        const dir = begin.pointDirection(end);

        end = (vectorDirection(dir) * value);
    }

    unittest
    {
        Shape line = Shape.Line(Vecf(0,0), Vecf(32, 32));
        
        line.length = line.length * 2;

        assert(round(line.end) == Vecf(64, 64));

        line.length = line.length / 4;

        assert(round(line.end) == Vecf(16, 16));

        line.length = line.length * 8;

        assert(round(line.end) == Vecf(128, 128));
    }

    /++
        Resizes as a percentage.

        Params:
            k = Percentage.
    +/
    void scale(float k) @safe nothrow pure
    in(type != ShapeType.point)
    do
    {
        import std.algorithm : each;

        if(type != ShapeType.polygon)
            end = end * k;
        else
            data.each!((ref e) => e = e * k);
    }

    unittest
    {
        Shape rec = Shape.Rectangle(Vecf(32, 32), Vecf(64, 64));
        rec.scale(2);

        assert(round(rec.end) == Vecf(128, 128));
    }

    string toString() @safe inout
    {
        import std.conv : to;
        import std.algorithm;

        if(type == ShapeType.point) {
            return "Shape.Point("~begin.to!string~")";
        }else
        if(type == ShapeType.line) {
            return "Shape.Line(begin: "~begin.to!string~", end: "~end.to!string~")";
        }else
        if(type == ShapeType.rectangle) {
            return "Shape.Rectangle(begin: "~begin.to!string~", end: "~end.to!string~")";
        }else
        if(type == ShapeType.circle) {
            return "Shape.Circle(position: "~begin.to!string~", radius: "~radius.to!string~")";
        }else 
        if(type == ShapeType.triangle) {
            return "Shape.Triangle(0: "~vertexs[0].to!string~", 1:"~vertexs[1].to!string~
                ", 2:"~vertexs[2].to!string~")";
        }else
        if(type == ShapeType.multi) {
            string strData;

            foreach(e; shapes)
                strData ~= e.toString ~ (e == shapes[$-1] ? "" : ",") ~"\n";

            return "Shape.Multi(position: "~begin.to!string~", shapes: [\n" ~ strData ~ "])";

        }else
        if(type == ShapeType.polygon) {
            string strData;

            foreach(e; data)
                strData ~= e.to!string ~ (e == data[$-1] ? "" : ",") ~ "\n";

            return "Shape.Polygon(position: "~begin.to!string~", points: [\n" ~ strData ~ "])";
        }

        return "Shape.Unknown()";
    }

    /++
        Returns the shape as a polygon.

        Params:
            points = An array of polygon vertices.
            pos = Polygon position.

        Returns:
            Polygon.

        Example:
        ---
        auto triangle = Shape.Polygon([
            Vecf(64, 32),
            Vecf(32, 64),
            Vecf(96, 64)
        ]);
        ---
    +/
    static Shape Polygon(Vecf[] points,Vecf pos = Vecf(0,0)) @safe nothrow pure
    {
        Shape shape;

        shape.type = ShapeType.polygon;
        shape.data = points;
        shape.begin = pos;

        return shape;
    }

    /++
        Collects several figures into one.

        Params:
            shapes = A collection of figures.
            pos = The relative position of such a figure.

        Returns:
            A shapes assembled from many shapes.

        Example:
        ---
        auto multi = Shape.Mutli([
            Shape.Line(Vecf(0,0), Vecf(32,32)),
            Shape.Rectangle(Vecf(32,0), Vecf(64, 32)),
            ...
        ]);
        ---
    +/
    static Shape Multi(Shape[] shapes,Vecf pos = Vecf(0,0)) @safe nothrow pure
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
    static Shape Point(Vecf point) @safe nothrow pure
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
    static Shape Line(Vecf begin,Vecf end) @safe nothrow pure
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
    static Shape Rectangle(Vecf begin, Vecf end) @safe nothrow pure
    {
        Shape shape;

        shape.type = ShapeType.rectangle;
        shape.begin = begin;
        shape.end = end;

        return shape;
    }

    static Shape RoundRectangle(Vecf begin, Vecf end, float radius) @safe nothrow pure
    {
        Shape shape;

        shape.type = ShapeType.roundrect;
        shape.begin = begin;
        shape.end = end;
        shape.radius = radius;

        return shape;
    }

    /++
        Create a non-solid rectangle. 

        Params:
            begin = Rectangle begin.
            end = Rectangle end. 

        Returns:
            Non-solid rectangle
    +/
    static Shape RectangleLine(Vecf begin,Vecf end) @safe nothrow pure
    {
        return Shape.Multi([
            Shape.Line(begin,begin + Vecf(end.x,0)),
            Shape.Line(begin + Vecf(end.x,0),end),
            Shape.Line(begin,begin + Vecf(0,end.y)),
            Shape.Line(begin + Vecf(0,end.y),end)
        ],Vecf(0,0));
    }

    /++
        Creates a circle.

        Params:
            pos = Circle position.
            r = Circle radius.  

        Returns:
            Circle. 
    +/
    static Shape Circle(Vecf pos,float r) @safe nothrow pure
    {
        Shape shape;

        shape.type = ShapeType.circle;
        shape.begin = pos;
        shape.radius = r;

        return shape;
    }

    /++
        Creates a triangle.

        Params:
            vertexs = Triangle vertexs.

        Returns:
            Tringle. 
    +/
    static Shape Triangle(Vecf[3] vertexs) @safe nothrow pure
    {
        Shape shape;

        shape.type = ShapeType.triangle;
        shape.vertex!0 = vertexs[0];
        shape.vertex!1 = vertexs[1];
        shape.vertex!2 = vertexs[2];

        return shape;
    }

    /++
        Create a square.

        Params:
            pos = Square position.
            len = Square length;

        Returns:
            Square (ShapeType: Rectangle).
    +/
    static Shape Square(Vecf pos,float len) @safe nothrow pure
    {
        return Shape.Rectangle(pos,pos + Vecf(len,len));
    }
}

import tida.vector;

///
Shape rectVertexs(Vecf[] vertexArray) @safe nothrow pure
{
    import std.algorithm : maxElement, minElement;

    Shape shape = Shape.Rectangle(VecfNan, VecfNan);

    shape.begin = Vecf(vertexArray.minElement!"a.x".x, shape.begin.y);
    shape.end = Vecf(vertexArray.maxElement!"a.x".x, shape.end.y);
    shape.begin = Vecf(shape.begin.x, vertexArray.minElement!"a.y".y);
    shape.end = Vecf(shape.end.x, vertexArray.maxElement!"a.y".y);

    return shape;
}
