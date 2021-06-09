/++
    A module for checking the intersection of some simple shapes.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.game.collision;

import tida.shape, tida.vector;

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
bool isCollide(Shape first,Shape second,Vecf firstPos = Vecf(0,0),Vecf secondPos = Vecf(0,0)) @safe
in(first.type != ShapeType.unknown  && second.type != ShapeType.unknown)
in(first.type != ShapeType.triangle && second.type != ShapeType.triangle)
body
{
    import std.conv : to;
    import std.math : abs, sqrt;
    import tida.graph.each;

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
                    if(first.begin == second.begin ||
                       first.begin == second.end)
                      return true;

                    bool result = false;

                    foreach(x,y; Line(second.begin, second.end)) {
                        if(cast(int) first.begin.x == x &&
                           cast(int) first.begin.y == y) {
                            result = true;
                            break;
                        }
                    }

                    return result;

                case ShapeType.rectangle:
                    return first.begin.x > second.begin.x &&
                           first.begin.y > second.begin.y &&
                           first.begin.x < second.end.x &&
                           first.begin.y < second.end.y;

                case ShapeType.circle:
                    return first.begin.distance(second.begin) <= second.radius;

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
                    if(second.begin == first.begin ||
                      second.begin == first.end)
                      return true;

                    bool result = false;

                    foreach(x, y; Line(first.begin, first.end)) {
                        if(cast(int) second.begin.x == x &&
                           cast(int) second.begin.y == y) {
                            result = true;
                            break;
                        }
                    }

                    return result;

                case ShapeType.line:
                    const a = first.begin;
                    const b = first.end;
                    const c = second.begin;
                    const d = second.end;

                    const denominator = ((b.X - a.X) * (d.Y - c.Y)) - ((b.Y - a.Y) * (d.X - c.X));

                    const numerator1  = ((a.Y - c.Y) * (d.X - c.X)) - ((a.X - c.X) * (d.Y - c.Y));
                    const numerator2  = ((a.Y - c.Y) * (b.X - a.X)) - ((a.X - c.X) * (b.Y - a.Y));

                    if(denominator == 0) return numerator1 == 0 && numerator2 == 0;

                    const r = numerator1 / denominator;
                    const s = numerator2 / denominator;

                    return (r >= 0 && r <= 1) && (s >= 0 && s <= 1);

                case ShapeType.rectangle:
                    if(second.begin == first.begin ||
                      second.begin == first.end ||
                      second.end == first.begin ||
                      second.end == first.end)
                      return true;

                    bool result = false;

                    foreach(x,y; Line(first.begin, first.end)) {
                        if(x > second.begin.x &&
                           x < second.end.x   &&
                           y > second.begin.y &&
                           y < second.end.y) 
                        {
                           result = true;
                           break;
                        }
                    }

                    return result;

                case ShapeType.circle:
                    bool inside1 = isCollide(second, Shape.Point(first.begin));
                    bool inside2 = isCollide(second, Shape.Point(first.end));
                    if(inside1 || inside2) return true;

                    float len = first.length;

                    float dot = (   (second.x - first.x) * (first.end.x - first.begin.x)) +
                                (   (second.y - first.y) * (first.end.y - first.begin.y)) / (len * len);

                    float closestX = first.x + (dot * (first.end.x - first.begin.y));
                    float closestY = first.y + (dot * (first.end.y - first.begin.y));

                    bool onSegment = isCollide(first, Shape.Point(Vecf(closestX,closestY)));
                    if(onSegment) return true;

                    float distX = closestX - second.x;
                    float distY = closestY - second.y;

                    len = Vecf(distX,distY).length;

                    return (len <= second.radius);

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
                    return second.begin.x > first.begin.x &&
                           second.begin.y > first.begin.y &&
                           second.begin.x < first.end.x &&
                           second.begin.y < first.end.y;

                case ShapeType.line:
                    if(second.begin == first.begin ||
                       second.begin == first.end ||
                       second.end == first.begin ||
                       second.end == first.end)
                      return true;

                    bool result = false;

                    foreach(x,y; Line(second.begin, second.end)) {
                        if(x > first.begin.x &&
                           x < first.end.x   &&
                           y > first.begin.y &&
                           y < first.end.y) 
                        {
                           result = true;
                           break;
                        }
                    }

                    return result;

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
                    Vecf temp = second.begin;

                    if(second.x < first.left) temp.x = first.left; else
                    if(second.x > first.right) temp.y = first.right;

                    if(second.y < first.top) temp.y = first.top; else
                    if(second.y > first.bottom) temp.y = first.bottom;

                    immutable dist = second.begin - temp;
                    immutable len = dist.length;

                    return len <= second.radius;

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
                    return second.begin.distance(first.begin) <= first.radius;

                case ShapeType.line:
                    bool inside1 = isCollide(first, Shape.Point(second.begin));
                    bool inside2 = isCollide(first, Shape.Point(second.end));
                    if(inside1 || inside2) return true;

                    float len = second.length;

                    float dot = (   (first.x - second.x) * (second.end.x - second.begin.x)) +
                                (   (first.y - second.y) * (second.end.y - second.begin.y)) / (len * len);

                    float closestX = second.x + (dot * (second.end.x - second.begin.y));
                    float closestY = second.y + (dot * (second.end.y - second.begin.y));

                    bool onSegment = isCollide(second, Shape.Point(Vecf(closestX,closestY)));
                    if(onSegment) return true;

                    float distX = closestX - first.x;
                    float distY = closestY - first.y;

                    len = Vecf(distX,distY).length;

                    return (len <= first.radius);

                case ShapeType.rectangle:
                    Vecf temp = first.begin;

                    if(first.x < second.left) temp.x = second.left; else
                    if(first.x > second.right) temp.y = second.right;

                    if(first.y < second.top) temp.y = second.top; else
                    if(first.y > second.bottom) temp.y = second.bottom;

                    immutable dist = first.begin - temp;
                    immutable len = dist.length;

                    return len <= first.radius;

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
bool isPolygonAndPoint(Vecf[] first, Vecf second) @safe
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
bool isPolygonAndLine(Vecf[] first, Vecf[] second) @safe
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        bool hit = isCollide(Shape.Line(second[0], second[1]), Shape.Line(vc, vn));

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
bool isPolygonAndRect(Vecf[] first, Vecf[] second) @safe
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        bool hit = isCollide(Shape.Rectangle(second[0], second[1]), Shape.Line(vc, vn));

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
bool isPolygonAndCircle(Vecf[] first, Vecf second, float r) @safe
{
    int next = 0;
    for(int current = 0; current < first.length; current++)
    {
        next = current + 1;

        if(next == first.length) next = 0;

        Vecf vc = first[current];
        Vecf vn = first[next];

        bool hit = isCollide(Shape.Circle(second, r), Shape.Line(vc, vn));

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
bool isPolygonsCollision(Vecf[] first, Vecf[] second) @safe
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