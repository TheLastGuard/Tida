/++
    Module for working with corners. While you can work with different types of angles.

    In this module you can find:
    * Convert angular measures (e.g. degrees to radians, etc.): `from`
    * Calculation of the angle between two points: `pointDirection`
    * Rotate a point around the center: `rotate`.

    # 1. Using functions.
    ## 1.1 Finding the angle between two points.
    There is a moment when you need to find the angle between two points, for example, so that some object 
    can move freely towards another object. For this, the `pointDirection` function is used, which takes two vectors, 
    in response, it gives the angle in radians, so that it is easier to pass the value to the function for 
    calculating the motion. But, if it is required exactly in degrees, you can use the from function:
    ---
    float deg = Vecf(32,32).pointDirection(Vecf(64,64)).from!(Radians,Degrees);
    ---

    And let's say you need an object to move to another object directly:
    ---
    float rad = position.pointDirection(otherPositionObject);
    Vecf vecd = vectorDirection(rad);

    position += vecd * 3; 
    ---
    Look in: `pointDirection`, `from`, `vectorDirection`.

    ## 1.2 Turn.
    Indeed, when you need to rotate an object, use the rotate function, which rotates the object, moreover, 
    around the center that you specified. Usage example:
    ---
    Vecf position = ...;
    Vecf positionRotate;

    positionRotate = position.rotate(45.from!(Degrees,Radians), Vecf(...));
    ---
    
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
    Brings the angle back to normal.

    Params:
        Type = Angle type.
        angle = Angle.

    Example:
    ---
    assert(375.minimize!Degrees == 15);
    ---
+/
float minimize(ubyte Type)(float angle) @safe
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
Vecf vectorDirection(float angle) @safe
{
    import std.math : cos, sin;

    return Vecf(cos(angle), sin(angle));
}