/++
Module for working with mathematical angles. Contains the translation of
measurement systems, work in the form of determining the angle,
vector rotation and more.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.angle;

import std.math : PI;
version(unittest) import fluent.asserts;

enum Radians = 0; /// Radians
enum Degrees = 1; /// Degrees
enum Turns = 2; /// Turns
enum Gons = 3; /// Gons

/++
Maximum angle value.

Params:
    Type = Type angle.
    
Example:
---
auto maxRad = max!Radians;
---
+/
template max(ubyte Type)
{
    static if (Type == Radians) 
    {
        enum max = 2 * PI;
    }else
    static if (Type == Degrees)
    {
        enum max = 360.0f;
    }else
    static if (Type == Turns)
    {
        enum max = 1.0f;
    }else
    static if (Type == Gons)
    {
        enum max = 400.0f;
    }
}

alias perigon = max; /// perigon

/++
Returns the right angle.

Params:
    Type = Type angle.
    
Example:
---
auto riaRad = rightAngle!Radians;
---
+/
template rightAngle(ubyte Type)
{
    static if (Type == Radians)
    {
        enum rightAngle = 0.5 * PI;
    }else
    static if (Type == Degrees)
    {
        enum rightAngle = 90.0f;
    }else
    static if (Type == Turns)
    {
        enum rightAngle = 1 / 4;
    }else
    static if (Type == Gons)
    {
        enum rightAngle = 100;
    }else
        static assert(null, "Unknown angle type!");
}

/++
Returns straight angle.

Params:
    Type = Type angle.
    
Example:
---
auto strRad = straight!Radians;
---
+/
template straight(ubyte Type)
{   
    static if (Type == Radians)
    {
        enum straight = PI;
    }else
    static if (Type == Degrees) 
    {
        enum straight =  180;
    }else
    static if (Type == Turns)
    {
        enum straight =  0.5;
    }else
    static if (Type == Gons)
    {
        enum straight =  200;
    }else
        static assert(null,"Unknown angle type!");
}

/++
Translate one system of angles into another.

Params:
    What = What to translate.
    In = What to translate.
    value = Value.

Example:
---
from(Degrees,Radians)(45);
---
+/
float conv(ubyte What,ubyte In)(float value) @safe nothrow pure
{
    import std.math;
    
    static if (What == In) return value;
    else
    static if (In == Turns) return value / max!What;
    else
    static if (What == Turns) return max!In * value;
    else
    static if (What == Radians)
    {
        static if (In == Degrees)
        {
            return value * 180 / PI;
        }else
        static if (In == Gons)
        {
            return value * 200 / PI;
        }
    }else
    static if (What == Degrees)
    {
        static if (In == Radians)
        {
            return value * PI / 180;
        }else
        static if (In == Gons)
        {
            return value * 200 / 180;
        }
    }else
    static if (What == Gons)
    {
        static if (In == Radians)
        {
            return value * PI / 200;
        }else
        static if (In == Degrees)
        {
            return value * 180 / 200;
        }
    }
}

alias from = conv; // old name saved.

/++
Brings the angle back to normal.

Params:
    Type = Angle type.
    angle = Angle.

Example:
---
assert(375.minimize!Degrees == 15);
    ---
+/
float minimize(ubyte Type)(float angle) @safe nothrow pure
{
    int k = cast(int) (angle / max!Type);
    float sign = angle >= 0 ? 1 : -1;

    return angle - ((max!Type * cast(float) k) * sign);
}

/++
Finds the angle between two angel's. Accepted in any angle change systems.

Params:
    a = First angle.
    b = Second angle.
    
Returns: Angle between two angel's.
+/
float betweenAngle(float a, float b) @safe nothrow pure
{
    return (a + b) / 2;
}

unittest
{
    max!Radians.from!(Radians,Degrees).should.equal(max!Degrees);
    max!Degrees.from!(Degrees,Gons).should.equal(max!Gons);
    max!Gons.from!(Gons,Turns).should.equal(max!Turns);
    
    rightAngle!Radians.from!(Radians,Degrees).should.equal(rightAngle!Degrees);
    rightAngle!Degrees.from!(Degrees,Gons).should.equal(rightAngle!Gons);
}

import tida.vector;

/++
Returns the angle between two vectors in radians.

Params:
    a = First point.
    b = Second point.
    
Returns: Angle in radians.

To convert, for example, to degrees, use the function like this:
---
pointDirection(...).from!(Radians,Degrees);
    ---
+/
T pointDirection(T)(Vector!T a, Vector!T b) @safe nothrow pure
{
    import std.math : atan2;

    T result = atan2(b.y - a.y, b.x - a.x);
    return result;
}

/++
Rotates the point by the specified number of degrees.

Params:
    vec = Point.
    angle = Angle of rotation.
    center = Center of rotation.
+/
Vecf rotate(Vecf vec, float angle, Vecf center = vecf(0, 0)) @safe nothrow pure
{
    import std.math : sin, cos;

    float ca = cos(angle);
    float sa = sin(angle);

    Vecf result;

    vec -= center;

    result.x = vec.x * ca - vec.y * sa;
    result.y = vec.x * sa + vec.y * ca;

    return result + center;
}

/++
Convert angle to direction vector. Use when moving an object at a given angle.

Params:
    angle = Angle.

Example:
---
Vecf vecd = vectorDirection(45.from!(Degrees,Radians));
position += vecd * 5; // Move the object 45 degrees at a given speed.
    ---
+/
Vector!T vectorDirection(T)(T angle) @safe nothrow pure
{
    import std.math : cos, sin;

    return vec!T(cos(angle), sin(angle));
}
