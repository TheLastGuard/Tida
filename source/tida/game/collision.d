/++
    A module for checking the intersection of some simple shapes.

    Authors: TodNaz
    License: MIT
+/
module tida.game.collision;

import tida.shape, tida.vector;

/++
    A function to check the intersection of two shapes. It does not give an intersection point, 
    it gives a state that informs if there is an intersection.

    Params:
        first = First shape.
        second = Second shape.

    Returns:
        Gives a state indicating if there is an intersection.

    Example:
    ---
    assert(isCollide(Shape.Rectangle(Vecf(32,32),Vecf(48,48)),
                     Shape.Line(Vecf(48,32),Vecf(32,48)));
    ---

    TODO:
        * Circle
        * Triangle
+/
public bool isCollide(Shape first,Shape second,Vecf firstPos = Vecf(0,0),Vecf secondPos = Vecf(0,0)) @safe
in(first.type != ShapeType.unknown  && second.type != ShapeType.unknown)
in(first.type != ShapeType.triangle && second.type != ShapeType.triangle)
in(first.type != ShapeType.circle   && second.type != ShapeType.circle)
body
{
    import std.conv : to;
    import std.math : abs;

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

                    /+
                        Virtually by drawing a line, but at each step we check if there is the same collision.
                    +/
                    int x1 = second.begin.x.to!int;
                    int y1 = second.begin.y.to!int;
                    const x2 = second.end.x.to!int;
                    const y2 = second.end.y.to!int;

                    const deltaX = abs(x2 - x1);
                    const deltaY = abs(y2 - y1);
                    const signX = x1 < x2 ? 1 : -1;
                    const signY = y1 < y2 ? 1 : -1;

                    int error = deltaX - deltaY;

                    while(x1 != x2 || y1 != y2) {
                        if(first.begin.x.to!int == x1 &&
                           first.begin.y.to!int == y1)
                           return true;

                        const int error2 = error * 2;

                        if(error2 > -deltaY) {
                            error -= deltaY;
                            x1 += signX;
                        }

                        if(error2 < deltaX) {
                            error += deltaX;
                            y1 += signY;
                        }
                    }

                    return false;

                case ShapeType.rectangle:
                    return first.begin.x > second.begin.x &&
                           first.begin.y > second.begin.y &&
                           first.begin.x < second.end.x &&
                           first.begin.y < second.end.y;

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

                    /+
                        Virtually by drawing a line, but at each step we check if there is the same collision.
                    +/
                    int x1 = first.begin.x.to!int;
                    int y1 = first.begin.y.to!int;
                    const x2 = first.end.x.to!int;
                    const y2 = first.end.y.to!int;

                    const deltaX = abs(x2 - x1);
                    const deltaY = abs(y2 - y1);
                    const signX = x1 < x2 ? 1 : -1;
                    const signY = y1 < y2 ? 1 : -1;

                    int error = deltaX - deltaY;

                    while(x1 != x2 || y1 != y2) {
                        if(second.begin.x.to!int == x1 &&
                           second.begin.y.to!int == y1)
                           return true;

                        const int error2 = error * 2;

                        if(error2 > -deltaY) {
                            error -= deltaY;
                            x1 += signX;
                        }

                        if(error2 < deltaX) {
                            error += deltaX;
                            y1 += signY;
                        }
                    }

                    return false;

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

                    /+
                        Virtually by drawing a line, but at each step we check if there is the same collision.
                    +/
                    int x1 = first.begin.x.to!int;
                    int y1 = first.begin.y.to!int;
                    const x2 = first.end.x.to!int;
                    const y2 = first.end.y.to!int;

                    const deltaX = abs(x2 - x1);
                    const deltaY = abs(y2 - y1);
                    const signX = x1 < x2 ? 1 : -1;
                    const signY = y1 < y2 ? 1 : -1;

                    int error = deltaX - deltaY;

                    while(x1 != x2 || y1 != y2) {
                        if(x1 > second.begin.x &&
                           x1 < second.end.x   &&
                           y1 > second.begin.y &&
                           y1 < second.end.y) 
                        {
                           return true;
                        }

                        const error2 = error * 2;

                        if(error2 > -deltaY) {
                            error -= deltaY;
                            x1 += signX;
                        }

                        if(error2 < deltaX) {
                            error += deltaX;
                            y1 += signY;
                        }
                    }

                    return false;

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

                    /+
                        Virtually by drawing a line, but at each step we check if there is the same collision.
                    +/
                    int x1 = second.begin.x.to!int;
                    int y1 = second.begin.y.to!int;
                    const x2 = second.end.x.to!int;
                    const y2 = second.end.y.to!int;

                    const deltaX = abs(x2 - x1);
                    const deltaY = abs(y2 - y1);
                    const signX = x1 < x2 ? 1 : -1;
                    const signY = y1 < y2 ? 1 : -1;

                    int error = deltaX - deltaY;

                    while(x1 != x2 || y1 != y2) {
                        if(x1 > first.begin.x &&
                           x1 < first.end.x   &&
                           y1 > first.begin.y &&
                           y1 < first.end.y) 
                        {
                           return true;
                        }

                        const error2 = error * 2;

                        if(error2 > -deltaY) {
                            error -= deltaY;
                            x1 += signX;
                        }

                        if(error2 < deltaX) {
                            error += deltaX;
                            y1 += signY;
                        }
                    }

                    return false;

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

                case ShapeType.multi:
                    foreach(shape; second.shapes) {
                        if(isCollide(first, shape,Vecf(0,0),second.begin))
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