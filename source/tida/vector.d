/++
Module two-dimensional vectors.

Mainly contains vector arithmetic functions as well as some traits.

Macros:
    LREF = <a href="#$1">$1</a>
    HREF = <a href="$1">$2</a>

Authors: $(HREF https://github.com/TodNaz,TodNaz)
Copyright: Copyright (c) 2020 - 2021, TodNaz.
License: $(HREF https://github.com/TodNaz/Tida/blob/master/LICENSE,MIT)
+/
module tida.vector;

import std.traits;

/++
Vector structure. May include any numeric data type available for vector arithmetic.
+/
struct Vector(T)
if (isNumeric!T && isMutable!T && isSigned!T)
{
    import std.math : pow, sqrt;

    alias Type = T;

public:
    T   x, /// X-axis position.
        y; /// Y-axis position. 

@safe nothrow pure:
    /++
    Any numeric type that can be freely converted to a template vector type 
    can be included in the vector's constructor.
    +/
    this(R)(R x, R y)
    {
        this.x = cast(T) x;
        this.y = cast(T) y;
    }

    /++
    Any numeric type that can be freely converted to a template vector type 
    can be included in the vector's constructor.
    +/
    this(R)(R[2] arrvec)
    if (isImplicitlyConvertible!(R, T))
    {
        this.x = cast(T) arrvec[0];
        this.y = cast(T) arrvec[1];
    }

    void opOpAssign(string op)(Vector rhs)
    {
        static if (op == "+")
        {
            this.x += rhs.x;
            this.y += rhs.y;
        }else 
        static if (op == "-")
        {
            this.x = x - rhs.x;
            this.y = y - rhs.y;
        }else
        static if (op == "*")
        {
            this.x = x * rhs.x;
            this.y = y * rhs.y;
        }else
        static if (op == "/")
        {
            this.x = x / rhs.x;
            this.y = y / rhs.y;
        }else
            static assert(null, "The `" ~ op ~ "` operator is not implemented.");
    }

    void opOpAssign(string op)(T num)
    {
        static if (op == "+")
        {
            this.x = this.x + num;
            this.y = this.y + num;
        }else
        static if (op == "-")
        {
            this.x = this.x - num;
            this.y = this.y - num;
        }else
        static if (op == "*")
        {
            this.x = this.x * num;
            this.y = this.y * num;
        }else 
        static if (op == "/")
        {
            this.x = this.x / num;
            this.y = this.y / num;
        }else
            static assert(null, "The `" ~ op ~ "` operator is not implemented.");
    }

    unittest
    {
        Vector!double a = [3.0, 3.0];
        a += Vector!double(3.0, 3.0);
        assert(a == Vector!double(6.0, 6.0));

        a /= 2;
        assert(a == Vector!double(3.0, 3.0));
    }

    /++
    Normalizes the vector.
    +/
    void normalize()
    {
        immutable d = 1 / length;

        this.x = x * d;
        this.y = y * d;
    }
inout:
    /++
    Converts a vector to an array.
    +/
    T[] array()
    {
        return [x, y];
    }

    bool opEquals(Vector a, Vector b)
    {
        if (a is b)
            return true;

        return a.x == b.x && a.y == b.y;
    }

    bool opEquals(Vector other)
    {
        if (this is other)
            return true;

        return this.x == other.x && this.y == other.y;
    }

    unittest
    {
        Vector!real a = [3.0, 3.0];
        assert(a == Vector!real(3.0, 3.0));
    }

    int opCmp(Vector rhs)
    {
        return (x > rhs.x && y > rhs.y) ? 1 : -1;
    }

    unittest
    {
        Vector!real a = [3.0, 3.0];
        assert(a > Vector!real(2.5, 1.1));
        assert(a < Vector!real(4.1, 3.1));
    }

    Vector!T opBinary(string op)(Vector rhs)
    {
        static if (op == "+")
        {
            return Vector!T(this.x + rhs.x, this.y + rhs.y);
        }
        else 
        static if (op == "-")
        {
            return Vector!T(this.x - rhs.x, this.y - rhs.y);
        }
        else
        static if (op == "*")
        {
            return Vector!T(this.x * rhs.x, this.y * rhs.y);
        }else
        static if (op == "/")
        {
            return Vector!T(this.x / rhs.x, this.y / rhs.y);
        }else
        static if (op == "%")
        {
            return Vector!T(this.x % rhs.x, this.y % rhs.y);
        }else
            static assert(null, "The `" ~ op ~ "` operator is not implemented.");
    }

    Vector!T opBinary(string op)(T num)
    {
        static if (op == "+")
        {
            return Vector!T(this.x + num, this.y + num);
        }else
        static if (op == "-")
        {
            return Vector!T(this.x - num, this.y - num);
        }else
        static if (op == "*")
        {
            return Vector!T(this.x * num, this.y * num);
        }
        else 
        static if (op == "/")
        {
            return Vector!T(this.x / num, this.y / num);
        }else
        static if (op == "%")
        {
            return Vector!T(this.x % num, this.y % num);
        }else
        static if (op == "^^")
        {
            return Vector!T(this.x ^^ num, this.y ^^ num);
        }else
            static assert(null, "The `" ~ op ~ "` operator is not implemented.");
    }

    unittest
    {
        Vector!int a = [3, 3];

        assert(a + Vector!int(3, 3) == Vector!int(6, 6));
        assert(a ^^ 2 == Vector!int(9, 9));
    }

    /++
    Vector length.
    +/
    T length()
    {
        static if(isIntegral!T) 
        {
            return cast(T) (sqrt(cast(float) ((this.x * this.x) + (this.y * this.y))));
        }else
        {
            return sqrt((this.x * this.x) + (this.y * this.y));
        }
    }

    /++
    Returns a normalized vector.
    +/
    Vector!T normalized()
    {
        immutable d = 1 / length;

        return Vector!T(this.x * d, this.y * d);
    }
}

/++
Checks if this type is a vector.
+/
template isVector(T)
{
    enum isVector = __traits(hasMember, T, "x") && __traits(hasMember, T, "y");
}

/++
Checks if the vector is integers.
+/
template isVectorIntegral(T)
if (isVector!T)
{
    enum isVectorIntegral = isIntegral!(T.Type); 
}

/++
Checks if the vector is float.
+/
template isVectorFloatingPoint(T)
if (isVector!T)
{
    enum isVectorFloatingPoint = isFloatingPoint!(T.Type);
}

unittest
{
    static assert(isVector!(Vector!int));
    static assert(!isVector!int);

    static assert(isVectorIntegral!(Vector!int));
    static assert(!isVectorIntegral!(Vector!float));

    static assert(isVectorFloatingPoint!(Vector!double));
    static assert(!isVectorFloatingPoint!(Vector!long));
}

alias Vecf = Vector!float; /// Vector float.
alias vec(T) = Vector!T; /// Vector.
alias vecf = vec!float; /// Vector float.

/++
Not a numeric vector.
+/
template vecNaN(T)
if (isVectorFloatingPoint!(Vector!T))
{
    enum vecNaN = Vector!T(T.nan, T.nan);
}

/// ditto
enum vecfNaN = vecNaN!float;

/++
Checks if the vector is non-numeric.
+/
bool isVectorNaN(T)(Vector!T vector)
if (isVectorFloatingPoint!(Vector!T))
{
    import std.math : isNaN;

    return vector.x.isNaN && vector.y.isNaN;
}

/// ditto
alias isVecfNaN = isVectorNaN!float;

/++
Generates a buffer from vectors.

Params:
    vectors = Array vector.
+/
T[] generateArray(T)(Vector!T[] vectors) @safe nothrow pure
{
    T[] result;
    foreach (e; vectors)
        result ~= e.array;

    return result;
}

unittest
{
    assert(vecfNaN.isVecfNaN);
    assert(vecNaN!double.isVectorNaN);
    assert(vecNaN!real.isVectorNaN);
}

inout(T) sqr(T)(inout(T) value) @safe nothrow pure
{
    return value * value;
}

/++
Construct the vector modulo.

Params:
    vec = Vector.
+/
inout(Vector!T) abs(T)(inout(Vector!T) vec) @safe nothrow pure
{
    import std.math : abs;

    return Vector!T(abs(vector.x), abs(vector.y));
}

/++
Distance between two points.

Params:
    a = First point.
    b = Second point.
+/
inout(T) distance(T)(inout(Vector!T) a, inout(Vector!T) b) @safe nothrow pure
{
    import std.math : sqrt;

    return sqrt(sqr(b.x - a.x) + sqr(b.y - a.y));
}

/++
Average distance between vectors.
+/
inout(Vector!T) averateVectors(T)(inout(Vector!T) a, inout(Vector!T) b) @safe nothrow pure
{
    return ((b - a) / 2) + ((a > b) ? b : a);
}

/++
Creates a random vector.

Params:
    begin = Begin.
    end = End.

Example:
---
Vecf rnd = uniform(vecf(32, 16), vecf(64, 48));
// vec.x = random: 32 .. 64
// vec.y = random: 16 .. 48
---
+/
inout(Vector!T) uniform(T)(inout(Vector!T) begin, inout(Vector!T) end) @safe
{
    import std.random : uniform;

    return Vector!T(uniform(begin.x, end.x), uniform(begin.y, end.y));
}

/++
Rounds the vector up.

Params:
    vec = Rounded vector.

Example:
---
assert(Vecf(32.5,32.5) == Vecf(33, 33));
---
+/
inout(Vector!T) round(T)(inout(Vector!T) vec) @safe nothrow
if (isVectorFloatingPoint!(Vector!T))
{
    import std.math : round;

    return Vector!T(round(vec.x), round(vec.y));
}

/++
Floors the vector down.

Params:
    vec = Floored vector.

Example:
---
assert(vecf(32.5, 32.5) == vecf(32, 32));
---
+/
inout(Vector!T) floor(T)(inout(Vector!T) vec) @safe nothrow
if (isVectorFloatingPoint!(Vector!T))
{
    import std.math : floor;

    return Vector!T(floor(vec.x), floor(vec.y));
}
