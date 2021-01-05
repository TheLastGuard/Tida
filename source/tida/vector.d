/++
    Module for information about positioning elements.

    Authors: $(HTTP https://github.com/TodNaz, TodNaz)
    License: $(HTTP https://opensource.org/licenses/MIT, MIT)
+/
module tida.vector;

alias Vecf = Vector!float;

///
T sqr(T)(T value) @safe
{
    return value * value;
}

/++
    Vector structure. Two-dimensional, because the framework does not 
    imply 3D capabilities.
+/
public struct Vector(T)
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
        static if (op == "+")
        {
            return Vector!T(this.x + rhs.x, this.y + rhs.y);
        }
        else static if (op == "-")
        {
            return Vector!T(this.x - rhs.x, this.y - rhs.y);
        }
    }

    Vector!T opBinary(string op)(T num) @safe nothrow 
    {
        static if (op == "*")
        {
            return Vector!T(this.x * num, this.y * num);
        }
        else static if (op == "/")
        {
            return Vector!T(this.x / num, this.y / num);
        }
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

    /++
        Return length Vector.
    ++/
    T length() @safe
    {
        static if(is(T : int))
        {
            import std.conv : to;
            
            return sqrt(to!float(sqr(this.x) + sqr(this.y))).to!T;
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
