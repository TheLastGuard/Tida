/++
    Module for working with corners. While you can work with different types of angles.
    
    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.angle;

import std.math;

static immutable ubyte Radians = 0; /// Radians
static immutable ubyte Degrees = 1; /// Degrees
static immutable ubyte Turns = 2; /// Turns
static immutable ubyte Gons = 3; /// Gons

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
    static if(Type == Radians) {
        enum max = 2 * PI;
    }else
    static if(Type == Degrees) {
        enum max = 360.0f;
    }else
    static if(Type == Turns) {
        enum max = 1.0f;
    }else
    static if(Type == Gons) {
        enum max = 400.0f;
    }
}

alias perigon = max;

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
    static if(Type == Radians) {
        enum rightAngle = 0.5 * PI;
    }else
    static if(Type == Degrees) {
        enum rightAngle = 90.0f;
    }else
    static if(Type == Turns) {
        enum rightAngle = 1 / 4;
    }else
    static if(Type == Gons) {
        enum rightAngle = 100;
    }else
        static assert(null,"Unknown angle type!");
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
    static if(Type == Radians) {
        enum straight = PI;
    }else
    static if(Type == Degrees) {
        enum straight =  180;
    }else
    static if(Type == Turns) {
        enum straight =  0.5;
    }else
    static if(Type == Gons) {
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
float from(ubyte What,ubyte In)(float value) @safe
{
    import std.math;
    
    static if(What == In) return value;
    else
    static if(In == Turns) return value / max!What;
    else
    static if(What == Turns) return max!In * value;
    else
    static if(What == Radians) {
        static if(In == Degrees) {
            return value * 180 / PI;
        }else
        static if(In == Gons) {
            return value * 200 / PI;
        }
    }else
    static if(What == Degrees) {
        static if(In == Radians) {
            return value * PI / 180;
        }else
        static if(In == Gons) {
            return value * 200 / 180;
        }
    }else
    static if(What == Gons) {
        static if(In == Radians) {
            return value * PI / 200;
        }else
        static if(In == Degrees) {
            return value * 180 / 200;
        }
    }
}

/++
    Finds the angle between two angel's. Accepted in any angle change systems.
    
    Params:
        a = First angle.
        b = Second angle.
        
    Returns: Angle between two angel's.
+/
float betweenAngle(float a,float b) @safe nothrow
{
    return (a + b) / 2;
}

unittest
{
    assert(max!Radians.from!(Radians,Degrees) == max!Degrees);
    assert(max!Degrees.from!(Degrees,Gons) == max!Gons);
    assert(max!Gons.from!(Gons,Turns) == max!Turns);
    
    assert(rightAngle!Radians.from!(Radians,Degrees) == rightAngle!Degrees);
    assert(rightAngle!Degrees.from!(Degrees,Gons) == rightAngle!Gons);
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
float pointDirection(Vecf a,Vecf b) @safe nothrow
{
    import std.math;

    float result = atan2(b.y - a.y, b.x - a.x);
    return result;
}

/++
    Rotates the point by the specified number of degrees.

    Params:
        vec = Point.
        angle = Angle of rotation.
        center = Center of rotation.
+/
Vecf rotate(Vecf vec,float angle,Vecf center) @safe
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