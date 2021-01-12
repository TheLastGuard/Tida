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
        bool isSolid = false; /// Is the polygon solid?
    }   

    private
    {
        float _radious;
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
    Vecf begin() @safe @property nothrow
    {
        return _begin;
    }

    /// The end of the figure.
    Vecf end() @safe @property nothrow
    in(type != ShapeType.point && type != ShapeType.circle,"This shape does not support end coordinates!")
    body
    {
        return _end;
    }

    /++
        Move shape
    +/
    void move(Vecf pos) @safe nothrow
    {
        _begin = _begin + pos;

        if(type == ShapeType.line || type == ShapeType.rectangle) {
            _end = _end + pos;
        }
    }

    /// The beginning of the figure.
    Vecf begin() @safe @property nothrow immutable
    {
        return _begin;
    }

    /// The end of the figure.
    Vecf end() @safe @property nothrow immutable
    in(type != ShapeType.point && type != ShapeType.circle,"This shape does not support end coordinates!")
    body
    {
        return _end;
    }

    /// The beginning of the figure.
    void begin(Vecf vec) @safe @property nothrow
    {
        _begin = vec;
    }

    /// The end of the figure.
    void end(Vecf vec) @safe @property nothrow
    in(type != ShapeType.point && type != ShapeType.circle,"This shape does not support end coordinates!")
    body
    {
        _end = vec;
    }

    /// The beginning of the figure along the x-axis.
    float x() @safe @property nothrow
    {
        return begin.x;
    }

    /// The beginning of the figure along the y-axis.
    float y() @safe @property nothrow
    {
        return begin.y;
    }

    /// The beginning of the figure along the x-axis.
    void x(float value) @safe @property nothrow
    {
        begin.x = value;
    }

    /// The beginning of the figure along the y-axis.
    void y(float value) @safe @property nothrow
    {
        begin.x = value;
    }

    /// The beginning of the figure along the x-axis.
    float x() @safe @property nothrow immutable
    {
        return begin.x;
    }

    /// The beginning of the figure along the y-axis.
    float y() @safe @property nothrow immutable
    {
        return begin.y;
    }
    
    /// The end of the figure along the x-axis.
    float endX() @safe @property nothrow
    {
        return end.x;
    }

    /// The end of the figure along the y-axis.
    float endY() @safe @property nothrow
    {
        return end.y;
    }

    /// The end of the figure along the x-axis.
    float endX() @safe @property nothrow immutable
    {
        return end.x;
    }

    /// The end of the figure along the y-axis.
    float endY() @safe @property nothrow immutable
    {
        return end.y;
    }

    /// The radious the figure.
    float radious() @safe @property nothrow
    in(type == ShapeType.circle,"This is not a circle!")
    body
    {
        return _radious;
    }

    /// The radious the figure.
    float radious() @safe @property nothrow immutable
    in(type == ShapeType.circle,"This is not a circle!")
    body
    {
        return _radious;
    }

    /// ditto
    void radious(float value) @safe @property nothrow
    in(type == ShapeType.circle,"This is not a circle!")
    body
    {
        _radious = value;
    }

    /// The top of the triangle.
    Vecf vertex(uint num)() @safe @property nothrow
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

    /// Shape width
    float width() @safe @property
    in(type == ShapeType.rectangle,"This is not a rectangle!")
    do
    {
        return end.x - begin.x;
    }

    /// Shape height
    float height() @safe @property
    in(type == ShapeType.rectangle,"This is not a rectangle!")
    do
    {
        return end.y - begin.y;
    }

    /// The top of the triangle.
    Vecf[] vertexs() @safe @property nothrow
    {
        return [begin,end,_trType];
    }

    ///
    Vecf[] vertexs() @safe @property nothrow immutable
    {
        return [begin,end,_trType];
    }

    /// ditto
    void vertex(uint num)(Vecf value) @safe @property nothrow
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
            return "Shape.Point("~begin.to!string~")";
        }else
        if(type == ShapeType.line) {
            return "Shape.Line(begin: "~begin.to!string~", end: "~end.to!string~")";
        }else
        if(type == ShapeType.rectangle) {
            return "Shape.Line(begin: "~begin.to!string~", end: "~end.to!string~")";
        }else
        if(type == ShapeType.circle) {
            return "Shape.Circle(position: "~begin.to!string~", radious: "~radious.to!string~")";
        }else 
        if(type == ShapeType.triangle) {
            return "Shape.Triangle(0: "~vertexs[0].to!string~", 1:"~vertexs[1].to!string~
                ", 2:"~vertexs[2].to!string~")";
        }else
        if(type == ShapeType.multi) {
            return "Shape.Multi(position: "~begin.to!string~", shapesCount: "~shapes.length.to!string~")";
        }

        return "Shape.Unknown()";
    }

    ///
    string toString() @safe 
    {
        import std.conv : to;

        if(type == ShapeType.point) {
            return "Shape.Point("~begin.to!string~")";
        }else
        if(type == ShapeType.line) {
            return "Shape.Line(begin: "~begin.to!string~", end: "~end.to!string~")";
        }else
        if(type == ShapeType.rectangle) {
            return "Shape.Line(begin: "~begin.to!string~", end: "~end.to!string~")";
        }else
        if(type == ShapeType.circle) {
            return "Shape.Circle(position: "~begin.to!string~", radious: "~radious.to!string~")";
        }else 
        if(type == ShapeType.triangle) {
            return "Shape.Triangle(0: "~vertex!0.to!string~", 1:"~vertex!1.to!string~", 2:"~vertex!2.to!string~")";
        }else
        if(type == ShapeType.multi) {
            return "Shape.Multi(position: "~begin.to!string~", shapesCount: "~shapes.length.to!string~")";
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
        Create a non-solid rectangle. 

        Params:
            begin = Rectangle begin.
            end = Rectangle end. 

        Returns:
            Non-solid rectangle
    +/
    static Shape RectangleLine(Vecf begin,Vecf end) @safe
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