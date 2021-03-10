/++
    Module for information about positioning elements.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.vector;

import std.traits;

alias Vecf = Vector!float;

Vecf VecfNan() @safe nothrow pure
{
    return Vecf(float.nan, float.nan);
}

bool isVecfNan(Vecf vec) @safe nothrow pure
{
    import std.math : isNaN;

    return vec.x.isNaN && vec.y.isNaN;
}

///
T sqr(T)(T value) @safe nothrow pure @nogc
{
    return value * value;
}

/++
    Vector structure. Two-dimensional, because the framework does not 
    imply 3D capabilities.
+/
struct Vector(T)
{
    import std.math : sqrt;

    public
    {
        T x = 0; /// X-Axis
        T y = 0; /// Y-Axis
    }

    /++
        Vector init.
    +/
    this(T _x,T _y) @safe nothrow
    {
        this.x = _x;
        this.y = _y;
    }

    ///
    this(T[2] vec) @safe nothrow
    {
        this.x = vec[0];
        this.y = vec[1];
    }

    alias X = x;
    alias Y = y;

    /++
        Gives x coordinate in int format
        Returns:
            int
    ++/
    int intX() @safe nothrow
    {
        return cast(int) this.x;
    }
    
    /++
        Gives y coordinate in int format
        Returns:
            int
    ++/
    int intY() @safe nothrow
    {
        return cast(int) this.y;
    }

    T[] array() @safe nothrow pure
    {
        return [x, y];
    }

    bool opEquals(Vector a, Vector b) @safe nothrow 
    {
        if (a is b)
            return true;

        return a.x == b.x && a.y == b.y;
    }

    bool opEquals(Vector!T rhs) @safe nothrow const
    {
        if (this is rhs)
            return true;

        return this.x == rhs.x && this.y == rhs.y;
    }

    int opCmp(Vector!T rhs) @safe nothrow
    {
        return (x > rhs.x && y > rhs.y) ? 1 : -1;
    }

    int opCmp(Vector!T rhs) @safe nothrow const
    {
        return (x > rhs.x && y > rhs.y) ? 1 : -1;
    }

    @("opEquals")
    @safe unittest
    {
        Vector!float a = Vecf(32, 32);
        Vector!float b = Vecf(32, 32);
        assert(a == b);
        b = Vecf(32, 64);
        assert(a != b);
    }

    Vector!T opBinary(string op)(Vector rhs) @safe nothrow 
    {
        static if(op == "+")
        {
            return Vector!T(this.x + rhs.x, this.y + rhs.y);
        }
        else 
        static if(op == "-")
        {
            return Vector!T(this.x - rhs.x, this.y - rhs.y);
        }
        else 
        static if(op == "*")
        {
            return Vector!T(this.x * rhs.x, this.y * rhs.y);
        }else
        static if(op == "/")
        {
            return Vector!T(this.x / rhs.x, this.y / rhs.y);
        }
    }

    Vector!T opBinary(string op)(T num) @safe nothrow 
    {
        static if(op == "+")
        {
            return Vector!T(this.x + num, this.y + num);
        }else
        static if(op == "-")
        {
            return Vector!T(this.x - num, this.y - num);
        }else
        static if(op == "*")
        {
            return Vector!T(this.x * num, this.y * num);
        }
        else 
        static if(op == "/")
        {
            return Vector!T(this.x / num, this.y / num);
        }else
            static assert(null, "Unknown operator");
    }

    @("opBinary")
    @safe unittest
    {
        Vector!float a = Vecf(32, 32);
        a = a + Vecf(16, 16);
        assert(a == Vecf(48, 48));
        a = a * 2;
        assert(a == Vecf(96, 96));
        a = a / 3;
        assert(a == Vecf(32, 32));
    }

    void opOpAssign(string op)(Vector rhs) @safe nothrow 
    {
        static if (op == "+")
        {
            this.x += rhs.x;
            this.y += rhs.y;
        }
        else static if (op == "-")
        {
            this.x = x - rhs.x;
            this.y = y - rhs.y;
        }
    }

    void opOpAssign(string op)(T num) @safe nothrow 
    {
        static if (op == "*")
        {
            this.x = this.x * num;
            this.y = this.y * num;
        }
        else static if (op == "/")
        {
            this.x = this.x / num;
            this.y = this.y / num;
        }
    }

    @("opOpAssign")
    @safe unittest
    {
        Vector!float a = Vecf(32, 32);
        a += Vecf(32, 32);
        assert(a == Vecf(64, 64));
        a *= 2;
        assert(a == Vecf(128, 128));
        a /= 4;
        assert(a == Vecf(32, 32));
    }

    Vector!T negative() @safe nothrow pure
    {
        return Vector!T(-x, -y);
    }

    Vector!T normalize() @safe nothrow pure
    {
        return Vector!T(x / length, y / length);
    }

    void norm() @safe nothrow pure
    {
        x /= length;
        y /= length;
    }

    auto invertX() @safe nothrow pure
    {
        x = -x;

        return this;
    }

    auto invertY() @safe nothrow pure
    {
        y = -y;

        return this;
    }

    auto invert() @safe nothrow pure
    {
        x = -x;
        y = -y;

        return this;
    }

    /++
        Return length Vector.
    +/
    T length() @safe nothrow
    {
        static if(is(T : int))
        {   
            return sqrt(cast(float) (sqr(this.x) + sqr(this.y)));
        }
        else
            return sqrt(sqr(this.x) + sqr(this.y));
    }

    /// ditto
    T length() @safe immutable nothrow
    {
        static if(is(T : int))
        {   
            return sqrt(cast(float) (sqr(this.x) + sqr(this.y)));
        }
        else
            return sqrt(sqr(this.x) + sqr(this.y));
    }
    
    string toString() @trusted
    {
        import std.conv : to;

        return "[" ~ x.to!string ~ "," ~ y.to!string ~ "]";
    }
}

Vecf abs(Vecf vec) @safe nothrow
{
    import std.math : abs;

    return Vecf(abs(vec.x), abs(vec.y));
}

template Abs(Vecf vec)
{
    import std.math : abs;

    enum Abs = Vecf(abs(vec.x), abs(vec.y));
}

/++
    Distance between two points.

    Params:
        a = First point.
        b = Second point.
+/
float distance(Vecf a,Vecf b) @safe nothrow
{
    import std.math : sqrt;

    return sqrt(sqr(b.x - a.x) + sqr(b.y - a.y));
}

/++
    Distance between two points.

    Params:
        vecs = Two points.
+/
float distance(Vecf[2] vecs) @safe nothrow
{
    return vecs[0].distance(vecs[1]);
}

template Sqr(float a)
{
    enum Sqr = a * a;
}

template Distance(Vecf a,Vecf b)
{
    import std.math : sqrt;

    enum Distance = sqrt(Sqr!(b.x - a.x)  + Sqr!(b.y - a.y));
}

template Distance(Vecf[2] vecs)
{
    import std.math : sqrt;

    enum Distance = Distance!(vecs[0],vecs[1]);
}

/++
    Average distance between vectors.
+/
Vecf averateVectors(Vecf a,Vecf b) @safe nothrow
{
    return ((b - a) / 2) + ((a > b) ? b : a);
}

/// ditto
template AverateVectors(Vecf a,Vecf b)
{
    enum AverateVectors = ((b - a) / 2) + ((a > b) ? b : a);
}

/++
    Creates a random vector.

    Params:
        begin = Begin.
        end = End.

    Example:
    ---
    Vecf rnd = uniform(Vecf(32, 16), Vecf(64, 48));
    // vec.x = random: 32 .. 64
    // vec.y = random: 16 .. 48
    ---
+/
Vecf uniform(Vecf begin, Vecf end) @safe
{
    import std.random : uniform;

    return Vecf(uniform(begin.x, end.x), uniform(begin.y, end.y));
}

Vecf round(Vecf vec) @safe
{
    import std.math : round;

    return Vecf(round(vec.x), round(vec.y));
}
