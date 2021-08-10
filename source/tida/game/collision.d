/++
    A module for checking the intersection of some simple shapes.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.game.collision;

import tida.shape, tida.vector;

/++
    Checks if there is a collision between the lines.

    Params:
        first = First line vertexs.
        second = Second line vertexs.
+/
bool lineLineImpl(const Vecf[] first, const Vecf[] second) @safe nothrow pure
{
    const a = first[0];
    const b = first[1];
    const c = second[0];
    const d = second[1];

    const denominator = ((b.X - a.X) * (d.Y - c.Y)) - ((b.Y - a.Y) * (d.X - c.X));

    const numerator1  = ((a.Y - c.Y) * (d.X - c.X)) - ((a.X - c.X) * (d.Y - c.Y));
    const numerator2  = ((a.Y - c.Y) * (b.X - a.X)) - ((a.X - c.X) * (b.Y - a.Y));

    if(denominator == 0) return numerator1 == 0 && numerator2 == 0;

    const r = numerator1 / denominator;
    const s = numerator2 / denominator;

    return (r >= 0 && r <= 1) && (s >= 0 && s <= 1);
}

/++
    Checks if there is a collision between a point and a line.

    Params:
        point = Point position.
        line = Line vertexs.
+/
bool pointLineImpl(const Vecf point, const Vecf[] line) @safe nothrow pure
{
    import tida.graph.each;

    if(point == line[0] ||
       point == line[1])
      return true;

    bool result = false;

    foreach(x,y; LineNoThrowImpl(line[0], line[1])) {
        if(cast(int) point.x == x &&
           cast(int) point.y == y) {
            result = true;
            break;
        }
    }

    return result;
}

/++
    Checks if there is a collision between a point and a rectange.

    Params:
        a = Point position.
        b = Rectangle vertexs.
+/
bool pointRectImpl(const Vecf a, const Vecf[] b) @safe nothrow pure
{
    return a.x > b[0].x &&
           a.y > b[0].y &&
           a.x < b[1].x &&
           a.y < b[1].y;
}

/++
    Checks if there is a collision between a line and a rectangle.

    Params:
        a = Line vertexs.
        b = Rectangle vertexs.
+/
bool lineRectImpl(const Vecf[] a, const Vecf[] b) @safe nothrow pure
{
    import tida.graph.each;

    if(b[0] == a[0] ||
      b[0] == a[1] ||
      b[1] == a[0] ||
      b[1] == a[1])
      return true;

    bool result = false;

    foreach(x,y; LineNoThrowImpl(a[0], a[1])) {
        if(x > b[0].x &&
           x < b[1].x   &&
           y > b[0].y &&
           y < b[1].y) 
        {
           result = true;
           break;
        }
    }

    return result;
}

/++
    Checks if there is a collision between a point and a Circle.

    Params:
        a = Point position.
        circlePos = Circle position.
        circleRadius = Circle radius.
+/
bool pointCircleImpl(const Vecf a, const Vecf circlePos, const float circleRadius) @safe nothrow pure
{
    return a.distance(circlePos) <= circleRadius;
}

/++
    Checks if there is a collision between a line and a Circle.

    Params:
        a = Line vertexs.
        circlePos = Circle position.
        circleRadius = Circle radius.
+/
bool lineCircleImpl(const Vecf[] a, const Vecf circlePos, const float circleRadius) @safe nothrow pure
{
    bool inside1 = pointCircleImpl(a[0], circlePos, circleRadius);
    bool inside2 = pointCircleImpl(a[1], circlePos, circleRadius);
    if(inside1 || inside2) return true;

    float len = a.length;

    float dot = (   (circlePos.x - a[0].x) * (a[1].x - a[0].x)) +
                (   (circlePos.y - a[0].y) * (a[1].y - a[0].y)) / (len * len);

    const closest = a[0] + ((a[1] - a[0]) * dot);

    bool onSegment = pointLineImpl(closest, a);
    if(onSegment) return true;

    const dist = closest - circlePos;
    len = dist.length;

    return (len <= circleRadius);
}

/++
    Checks if there is a collision between a rectangle and a circle.

    Params:
        a = Rectange vertexs.
        circlePos = Circle position.
        circleRadius = Circle radius.
+/
bool rectCircleImpl(const Vecf[] a, const Vecf circlePos, const float circleRadius) @safe nothrow pure
{
    Vecf temp = circlePos;

    if(circlePos.x < a[0].x) temp.x = a[0].x; else
    if(circlePos.x > a[1].x) temp.y = a[1].y;

    if(circlePos.y < a[0].y) temp.y = a[0].y; else
    if(circlePos.y > a[1].y) temp.y = a[1].y;

    immutable dist = circlePos - temp;
    immutable len = dist.length;

    return len <= circleRadius;
}

/++
    A function to check the intersection of two shapes. It does not give an intersection point, 
    it gives a state that informs if there is an intersection.

    Params:
        first = First shape.
        second = Second shape.
        firstPos = Position first shape.
        secondPos = Position second shape.

    Returns:
        Gives a state indicating if there is an intersection.

    Example:
    ---
    isCollide(Shape.Rectangle(Vecf(32,32),Vecf(48,48)),
                     Shape.Line(Vecf(48,32),Vecf(32,48)));
    ---
+/
bool isCollide(Shape first,Shape second,Vecf firstPos = Vecf(0,0),Vecf secondPos = Vecf(0,0)) @safe nothrow pure
in(first.type != ShapeType.unknown  && second.type != ShapeType.unknown)
in(first.type != ShapeType.triangle && second.type != ShapeType.triangle)
do
{
    import std.conv : to;
    import std.math : abs, sqrt;

    first.begin = first.begin + firstPos;
    second.begin = second.begin + secondPos;

    if(first.type == ShapeType.line || first.type == ShapeType.rectangle)
        first.end = first.end + firstPos;

    if(second.type == ShapeType.line || second.type == ShapeType.rectangle)
        second.end = second.end + secondPos;

    switch(first.type)
    {
        case ShapeType.point:

            switch(second.type)
            {
                case ShapeType.point:
                    return first.begin == second.begin;

                case ShapeType.line: 
                    return pointLineImpl(first.begin, second.to!(Vecf[]));

                case ShapeType.rectangle:
                    return pointRectImpl(first.begin, second.to!(Vecf[]));

                case ShapeType.circle:
                    return pointCircleImpl(first.begin, second.begin, second.radius);

                case ShapeType.polygon:
                    return isPolygonAndPoint(second.data, first.begin);

                case ShapeType.multi:
                    foreach(shape; second.shapes) {
                        if(isCollide(first, shape,Vecf(0,0), second.begin))
                            return true;
                    }

                    return false;

                default:
                    return false;
            }

        case ShapeType.line:

            switch(second.type)
            {
                case ShapeType.point:
                    return pointLineImpl(second.begin, first.to!(Vecf[]));

                case ShapeType.line:
                    return lineLineImpl(first.to!(Vecf[]), second.to!(Vecf[]));

                case ShapeType.rectangle:
                    return lineRectImpl(first.to!(Vecf[]), second.to!(Vecf[]));

                case ShapeType.circle:
                    return lineCircleImpl(first.to!(Vecf[]), second.begin, second.radius);

                case ShapeType.polygon:
                    return isPolygonAndLine(second.data, first.to!(Vecf[]));

                case ShapeType.multi:
                    foreach(shape; second.shapes) {
                        if(isCollide(first,shape,Vecf(0,0),second.begin))
                            return true;
                    }

                    return false;

                default:
                    return false;
            }

        case ShapeType.rectangle:
            
            switch(second.type)
            {
                case ShapeType.point:
                    return pointRectImpl(second.begin, first.to!(Vecf[]));

                case ShapeType.line:
                    return lineRectImpl(second.to!(Vecf[]), first.to!(Vecf[]));

                case ShapeType.rectangle:
                    const a = first.begin;
                    const b = first.end;
                    const c = second.begin;
                    const d = second.end;

                    return
                    (
                        a.x + (b.x-a.x) >= c.x && 
                        a.x <= c.x + (d.x-c.x) && 
                        a.y + (b.y - a.y) >= c.y && 
                        a.y <= c.y + (d.y - c.y)
                    );

                case ShapeType.circle:
                    return rectCircleImpl(first.to!(Vecf[]), second.begin, second.radius);

                case ShapeType.polygon:
                    return isPolygonAndRect(second.data, first.to!(Vecf[]));

                case ShapeType.multi:
                    foreach(shape; second.shapes) {
                        if(isCollide(first, shape,Vecf(0,0),second.begin))
                            return true;
                    }

                    return false;

                default:
                    return false;
            }

        case ShapeType.circle:
            switch(second.type)
            {
                case ShapeType.point:
                    return pointCircleImpl(second.begin, first.begin, first.radius);

                case ShapeType.line:
                    return lineCircleImpl(second.to!(Vecf[]), first.begin, first.radius);

                case ShapeType.rectangle:
                    return rectCircleImpl(second.to!(Vecf[]), first.begin, first.radius);

                case ShapeType.circle:
                    immutable dist = first.begin - second.begin;

                    return dist.length <= first.radius + second.radius;

                case ShapeType.polygon:
                    return isPolygonAndCircle(second.data, first.begin, first.radius);

                case ShapeType.multi:
                    foreach(shape; second.shapes) {
                        if(isCollide(first,shape,Vecf(0,0),second.begin))
                            return true;
                    }

                    return false;

                default:
                    return false;
            }

        case ShapeType.polygon:
            switch(second.type)
            {
                case ShapeType.point:
                    return isPolygonAndPoint(first.data, second.begin);

                case ShapeType.line:
                    return isPolygonAndLine(first.data, second.to!(Vecf[]));

                case ShapeType.rectangle:
                    return isPolygonAndRect(first.data, second.to!(Vecf[]));

                case ShapeType.circle:
                    return isPolygonAndCircle(first.data, second.begin, second.radius);

                case ShapeType.polygon:
                    return isPolygonsCollision(first.data, second.data);

                case ShapeType.multi:
                    foreach(shape; second.shapes) {
                        if(isCollide(shape, first, second.begin, Vecf(0,0)))
                            return true;
                    }

                    return false;

                default:
                    return false;
            }

        case ShapeType.multi:
            foreach(shape; first.shapes) {
                if(isCollide(shape, second,first.begin,Vecf(0,0)))
                    return true;
            }

            return false;

        default:
            return false;
    }
}

unittest
{
    assert(
        isCollide(
            Shape.Rectangle(Vecf(32,32),Vecf(64,64)),
            Shape.Line(Vecf(48,48),Vecf(96,96))
        )   
    );

    assert(
        isCollide(
            Shape.Rectangle(Vecf(32,32),Vecf(64,64)),
            Shape.Rectangle(Vecf(48,48),Vecf(72,72))
        )
    );

    assert(
        isCollide(
            Shape.Line(Vecf(32,32),Vecf(64,64)),
            Shape.Line(Vecf(64,32),Vecf(32,64))
        )
    );
}

/++
    Checks collision between polygon and point.

    Params:
        first = Polygon vertices.
        second = Point position.
+/
bool isPolygonAndPoint(Vecf[] first, Vecf second) @safe nothrow pure
{
    bool collision = false;

    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        if(((vc.y >= second.y && vn.y <= second.y) || (vc.y <= second.y && vn.y >= second.y)) &&
            (second.x < (vn.x - vc.x) * (second.y - vc.y) / (vn.y - vc.y) + vc.x)) {
            collision = !collision;
        }
    }

    return collision;
}

/++
    Checks collision between polygon and line.

    Params:
        first = Polygon vertices.
        second = Line vertices.
+/
bool isPolygonAndLine(Vecf[] first, Vecf[] second) @safe nothrow pure
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        bool hit = lineLineImpl(second, [vc, vn]);

        if(hit) return true;
    }

    return false;
}

/++
    Check collision between polygon and rectangle.

    Params:
        first = Polygon vertices.
        second = Rectangle vertices.
+/
bool isPolygonAndRect(Vecf[] first, Vecf[] second) @safe nothrow pure
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        bool hit = lineRectImpl([vc, vn], second);

        if(hit) return true;
    }

    return false;
}

/++
    Check collision between polygon and circle.

    Params:
        first = Polygon vertices.
        second = The position of the center of the circle.
        r = Circle radius.
+/
bool isPolygonAndCircle(Vecf[] first, Vecf second, float r) @safe nothrow pure
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        bool hit = lineCircleImpl([vc, vn], second, r);

        if(hit) return true;
    }

    return false;
}

/++
    Checking the collision of two polygons.

    Params:
        first = First polygon vertices.
        second = Second polygon vertices.
+/
bool isPolygonsCollision(Vecf[] first, Vecf[] second) @safe nothrow pure
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        bool hit = isPolygonAndLine(second, [vc, vn]);
        if(hit) return true;

        hit = isPolygonAndPoint(first, second[0]);
        if(hit) return true;
    }

    return false;
}

unittest
{
    Vecf[]  first = [
                        Vecf(32, 32),
                        Vecf(64, 48),
                        Vecf(64, 128),
                        Vecf(32, 112)
                    ];

    assert(isPolygonAndPoint(first, Vecf(33, 33)));
    assert(isPolygonAndLine(first, [Vecf(16, 16), Vecf(48, 48)]));
    assert(isPolygonAndRect(first, [Vecf(16, 16), Vecf(128, 128)]));
    assert(isPolygonAndCircle(first, Vecf(128, 128), 64));
    assert(isPolygonsCollision(first,   [
                                            Vecf(48, 48),
                                            Vecf(64, 64),
                                            Vecf(32, 64),
                                            Vecf(32, 32),
                                            Vecf(32, 48)
                                        ]));
}

const(Vecf) placePointLineImpl(const Vecf point, const Vecf[] line) @safe nothrow pure
{
    import tida.graph.each;

    if(point == line[0] ||
       point == line[1])
      return point;

    Vecf result = VecfNan;

    foreach(x,y; LineNoThrowImpl(line[0], line[1])) {
        if(cast(int) point.x == x &&
           cast(int) point.y == y) {
            result = Vecf(x, y);
            break;
        }
    }

    return result;
}

const(Vecf) placePointRectImpl(const Vecf point, const Vecf[] rectangle) @safe nothrow pure
{
    Vecf place = rectangle[0] - point;

    if( place.x < 0 || place.y < 0 ||
        place.x > (rectangle[1] - rectangle[0]).x ||
        place.y > (rectangle[1] - rectangle[0]).y) {
        return VecfNan;
    } else {
        return rectangle[0] + place;
    }
}

const(Vecf) placePointCircleImpl(const Vecf point, const Vecf circlePos, const float circleRadius) @safe nothrow pure
{
    return point.distance(circlePos) > circleRadius ? VecfNan : point;
}

const(Vecf) placeLineLineImpl(const Vecf[] first, const Vecf[] second) @safe nothrow pure
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

const(Vecf) placeLineRectImpl(const Vecf[] a, const Vecf[] b) @safe nothrow pure
{
    import tida.graph.each;

    if(b[0] == a[0] ||
      b[0] == a[1] ||
      b[1] == a[0] ||
      b[1] == a[1])
      return a[0];

    Vecf result = VecfNan;

    foreach(x,y; LineNoThrowImpl(a[0], a[1])) {
        if(x > b[0].x &&
           x < b[1].x   &&
           y > b[0].y &&
           y < b[1].y)
        {
           return Vecf(x, y);
        }
    }

    return result;
}

const(Vecf) placeLineCircleImpl(const Vecf[] line, const Vecf circlePos, const float circleRadius) @safe nothrow pure
{
    import tida.graph.each;

    Vecf place = VecfNan;

    foreach(x, y; LineNoThrowImpl(line[0], line[1])) {
        if(!(place = placePointCircleImpl(Vecf(x, y), circlePos, circleRadius)).isVecfNan)
            return place;
    }

    return VecfNan;
}

const(Vecf) placeRectRectImpl(const Vecf[] a, const Vecf[] b,bool isRecurse = false) @safe nothrow pure
{
    if(lineRectImpl([a[0], a[0] + Vecf(a[1].x, 0)], b))
        return placeLineRectImpl([a[0], a[0] + Vecf(a[1].x, 0)], b);
    if(lineRectImpl([a[0] + Vecf(a[1].x, 0), a[1]], b))
        return placeLineRectImpl([a[0] + Vecf(a[1].x, 0), a[1]], b);
    if(lineRectImpl([a[0], a[0] + Vecf(0, a[1].y)], b))
        return placeLineRectImpl([a[0], a[0] + Vecf(0, a[1].y)], b);
    if(lineRectImpl([a[0] + Vecf(0, a[1].y), a[1]], b))
        return placeLineRectImpl([a[0] + Vecf(0, a[1].y), a[1]], b);

    if(!isRecurse)
        return placeRectRectImpl(b, a, true);
    else
        return VecfNan;
}

const(Vecf) placeRectCircleImpl(const Vecf[] a, const Vecf circlePos, const float circleRadius) @safe nothrow pure
{
    if(lineCircleImpl([a[0], a[0] + Vecf(a[1].x, 0)], circlePos, circleRadius))
        return placeLineCircleImpl([a[0], a[0] + Vecf(a[1].x, 0)], circlePos, circleRadius);
    if(lineCircleImpl([a[0] + Vecf(a[1].x, 0), a[1]], circlePos, circleRadius))
        return placeLineCircleImpl([a[0] + Vecf(a[1].x, 0), a[1]], circlePos, circleRadius);
    if(lineCircleImpl([a[0], a[0] + Vecf(0, a[1].y)], circlePos, circleRadius))
        return placeLineCircleImpl([a[0], a[0] + Vecf(0, a[1].y)], circlePos, circleRadius);
    if(lineCircleImpl([a[0] + Vecf(0, a[1].y), a[1]], circlePos, circleRadius))
        return placeLineCircleImpl([a[0] + Vecf(0, a[1].y), a[1]], circlePos, circleRadius);

    Vecf place = VecfNan;
    Vecf[] line =   [
                        circlePos - Vecf(0, circleRadius),
                        circlePos + Vecf(0, circleRadius)
                    ];

    if(!(place = placeLineRectImpl(line, a)).isVecfNan) return place;
    line =  [
                circlePos - Vecf(circleRadius, 0),
                circlePos + Vecf(circleRadius, 0)
            ];

    return placeLineRectImpl(line, a);
}

const(Vecf) placeCircleCircleImpl(const Vecf fPos, const float fRadius, const Vecf sPos, const float sRadius)
@safe nothrow pure
{
    //immutable dist = first.begin - second.begin;
    //return dist.length <= first.radius + second.radius;

    if((fPos - sPos).length <= fRadius + sRadius) {
        return Vecf((fPos.x * sRadius + sPos.x * fRadius) / (fRadius + sRadius),
                    (fPos.y * sRadius + sPos.y * fRadius) / (fRadius + sRadius));
    } else {
        return VecfNan;
    }
}

const(Vecf) placeofTangents(Shape first, Shape second, Vecf firstPos = Vecf(0, 0), Vecf secondPos = Vecf(0, 0))
@safe nothrow pure
in(first.type != ShapeType.unknown  && second.type != ShapeType.unknown)
in(first.type != ShapeType.triangle && second.type != ShapeType.triangle)
do
{
    first.begin = first.begin + firstPos;
    second.begin = second.begin + secondPos;

    if(first.type == ShapeType.line || first.type == ShapeType.rectangle)
        first.end = first.end + firstPos;

    if(second.type == ShapeType.line || second.type == ShapeType.rectangle)
        second.end = second.end + secondPos;

    switch(first.type)
    {
        case ShapeType.point:
            switch(second.type) {
                case ShapeType.point:
                    return first.begin == second.begin ? first.begin : VecfNan;

                case ShapeType.line:
                    return placePointLineImpl(first.begin, second.to!(Vecf[]));

                case ShapeType.rectangle:
                    return placePointRectImpl(first.begin, second.to!(Vecf[]));

                case ShapeType.circle:
                    return placePointCircleImpl(first.begin, second.begin, second.radius);

                case ShapeType.polygon:
                    return placePolygonAndPoint(second.data, first.begin);

                case ShapeType.multi:
                    Vecf place = VecfNan;

                    foreach(shape; second.shapes) {
                        if(!((place = placeofTangents(first, shape,Vecf(0,0), second.begin)).isVecfNan))
                            return place;
                    }

                    return VecfNan;

                default:
                    return VecfNan;
            }

        case ShapeType.line:
            switch(second.type)
            {
                case ShapeType.point:
                    return placePointLineImpl(second.begin, first.to!(Vecf[]));

                case ShapeType.line:
                    return placeLineLineImpl(first.to!(Vecf[]), second.to!(Vecf[]));

                case ShapeType.rectangle:
                    return placeLineRectImpl(second.to!(Vecf[]), first.to!(Vecf[]));

                case ShapeType.circle:
                    return placeLineCircleImpl(first.to!(Vecf[]), second.begin, second.radius);

                case ShapeType.polygon:
                    return placePolygonAndLine(second.data, first.to!(Vecf[]));

                case ShapeType.multi:
                    Vecf place = VecfNan;

                    foreach(shape; second.shapes) {
                        if(!((place = placeofTangents(first, shape,Vecf(0,0), second.begin)).isVecfNan))
                            return place;
                    }

                    return VecfNan;

                default:
                    return VecfNan;
            }

        case ShapeType.rectangle:
            switch(second.type)
            {
                case ShapeType.point:
                    return placePointRectImpl(second.begin, first.to!(Vecf[]));

                case ShapeType.line:
                    return placeLineRectImpl(second.to!(Vecf[]), first.to!(Vecf[]));

                case ShapeType.rectangle:
                    return placeRectRectImpl(first.to!(Vecf[]), second.to!(Vecf[]));

                case ShapeType.circle:
                    return placeRectCircleImpl(first.to!(Vecf[]), second.begin, second.radius);

                case ShapeType.polygon:
                    return placePolygonAndRect(second.data, first.to!(Vecf[]));

                case ShapeType.multi:
                    Vecf place = VecfNan;

                    foreach(shape; second.shapes) {
                        if(!((place = placeofTangents(first, shape,Vecf(0,0), second.begin)).isVecfNan))
                            return place;
                    }

                    return VecfNan;

                default:
                    return VecfNan;
            }

        case ShapeType.circle:
            switch(second.type)
            {
                case ShapeType.point:
                    return placePointCircleImpl(second.begin, first.begin, first.radius);

                case ShapeType.line:
                    return placeLineCircleImpl(second.to!(Vecf[]), first.begin, first.radius);

                case ShapeType.rectangle:
                    return placeRectCircleImpl(second.to!(Vecf[]), first.begin, first.radius);

                case ShapeType.circle:
                    return placeCircleCircleImpl(first.begin, first.radius, second.begin, second.radius);

                case ShapeType.polygon:
                    return placePolygonAndCircle(second.data, first.begin, first.radius);

                case ShapeType.multi:
                    Vecf place = VecfNan;

                    foreach(shape; second.shapes) {
                        if(!((place = placeofTangents(first, shape,Vecf(0,0), second.begin)).isVecfNan))
                            return place;
                    }

                    return VecfNan;

                default:
                    return VecfNan;
            }

        case ShapeType.polygon:
            switch(second.type)
            {
                case ShapeType.point:
                    return placePolygonAndPoint(first.data, second.begin);

                case ShapeType.line:
                    return placePolygonAndLine(first.data, second.to!(Vecf[]));

                case ShapeType.rectangle:
                    return placePolygonAndRect(first.data, second.to!(Vecf[]));

                case ShapeType.circle:
                    return placePolygonAndCircle(first.data, second.begin, second.radius);

                case ShapeType.polygon:
                    return placePolygonsCollision(first.data, second.data);

                case ShapeType.multi:
                    Vecf place = VecfNan;

                    foreach(shape; second.shapes) {
                        if(!((place = placeofTangents(first, shape,Vecf(0,0), second.begin)).isVecfNan))
                            return place;
                    }

                    return VecfNan;

                default:
                    return VecfNan;
            }

        case ShapeType.multi:
            Vecf place = VecfNan;

            foreach(shape; first.shapes) {
                if(!((place = placeofTangents(shape, second, first.begin, Vecf(0, 0))).isVecfNan))
                    return place;
            }

            return VecfNan;

        default:
            return VecfNan;
    }
}

Vecf placePolygonAndPoint(Vecf[] first, Vecf second) @safe nothrow pure
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        if(((vc.y >= second.y && vn.y <= second.y) || (vc.y <= second.y && vn.y >= second.y)) &&
            (second.x < (vn.x - vc.x) * (second.y - vc.y) / (vn.y - vc.y) + vc.x)) {
            return second;
        }
    }

    return VecfNan;
}

Vecf placePolygonAndLine(Vecf[] first, Vecf[] second) @safe nothrow pure
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        Vecf place = placeLineLineImpl(second, [vc, vn]);
        if(!place.isVecfNan) return place;
    }

    return VecfNan;
}

Vecf placePolygonAndRect(Vecf[] first, Vecf[] second) @safe nothrow pure
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        Vecf place = placeLineRectImpl([vc, vn], second);
        if(!place.isVecfNan) return place;
    }

    return VecfNan;
}

Vecf placePolygonAndCircle(Vecf[] first, Vecf second, float r) @safe nothrow pure
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        Vecf place = placeLineCircleImpl([vc, vn], second, r);
        if(!place.isVecfNan) return place;
    }

    return VecfNan;
}

Vecf placePolygonsCollision(Vecf[] first, Vecf[] second) @safe nothrow pure
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        Vecf place = placePolygonAndLine(second, [vc, vn]);
        if(!place.isVecfNan) return place;

        place = placePolygonAndPoint(first, second[0]);
        if(!place.isVecfNan) return place;
    }

    return VecfNan;
}
